import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import '../errors/failures.dart';

class OfflineEncryptionService {
  static const String _keyStorageAlias = 'medstudy_offline_master_aes_key';
  static const int _versionByte = 0x01;
  static const int _keySize = 32; // 256-bit AES key
  static const int _nonceSize = 12; // 96-bit GCM nonce
  static const int _tagSizeBits = 128; // 128-bit authentication tag

  final FlutterSecureStorage _secureStorage;
  final Map<String, String> _inMemoryFallback = {};

  OfflineEncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<Uint8List> _getOrCreateMasterKey() async {
    try {
      String? base64Key = await _secureStorage.read(key: _keyStorageAlias);
      if (base64Key == null || base64Key.isEmpty) {
        final randomBytes = Uint8List(_keySize);
        final secureRandom = Random.secure();
        for (int i = 0; i < _keySize; i++) {
          randomBytes[i] = secureRandom.nextInt(256);
        }
        base64Key = base64.encode(randomBytes);
        await _secureStorage.write(key: _keyStorageAlias, value: base64Key);
      }
      return base64.decode(base64Key);
    } on MissingPluginException catch (_) {
      return _getOrCreateInMemoryKey();
    } catch (_) {
      return _getOrCreateInMemoryKey();
    }
  }

  Uint8List _getOrCreateInMemoryKey() {
    String? base64Key = _inMemoryFallback[_keyStorageAlias];
    if (base64Key == null || base64Key.isEmpty) {
      final randomBytes = Uint8List(_keySize);
      final secureRandom = Random.secure();
      for (int i = 0; i < _keySize; i++) {
        randomBytes[i] = secureRandom.nextInt(256);
      }
      base64Key = base64.encode(randomBytes);
      _inMemoryFallback[_keyStorageAlias] = base64Key;
    }
    return base64.decode(base64Key);
  }

  Uint8List _generateNonce() {
    final nonce = Uint8List(_nonceSize);
    final secureRandom = Random.secure();
    for (int i = 0; i < _nonceSize; i++) {
      nonce[i] = secureRandom.nextInt(256);
    }
    return nonce;
  }

  Future<List<int>> encryptBytes(List<int> inputBytes,
      {List<int>? overrideKeyBytes}) async {
    try {
      final keyBytes = overrideKeyBytes != null
          ? Uint8List.fromList(overrideKeyBytes)
          : await _getOrCreateMasterKey();

      final nonce = _generateNonce();
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(keyBytes),
        _tagSizeBits,
        nonce,
        Uint8List(0),
      );

      cipher.init(true, params);
      final cipherTextAndTag = cipher.process(Uint8List.fromList(inputBytes));

      final builder = BytesBuilder();
      builder.addByte(_versionByte);
      builder.add(nonce);
      builder.add(cipherTextAndTag);

      return builder.toBytes();
    } catch (e) {
      if (e is Failure) rethrow;
      throw const NetworkFailure('Failed to encrypt offline material.');
    }
  }

  Future<List<int>> decryptBytes(List<int> encryptedPayload,
      {List<int>? overrideKeyBytes}) async {
    try {
      if (encryptedPayload.length < (1 + _nonceSize + (_tagSizeBits ~/ 8))) {
        throw const NetworkFailure(
            'Invalid or corrupted encrypted file container.');
      }

      final version = encryptedPayload[0];
      if (version != _versionByte) {
        throw const NetworkFailure(
            'Unsupported offline encryption format version.');
      }

      final nonce =
          Uint8List.fromList(encryptedPayload.sublist(1, 1 + _nonceSize));
      final cipherTextAndTag =
          Uint8List.fromList(encryptedPayload.sublist(1 + _nonceSize));

      final keyBytes = overrideKeyBytes != null
          ? Uint8List.fromList(overrideKeyBytes)
          : await _getOrCreateMasterKey();

      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(
        KeyParameter(keyBytes),
        _tagSizeBits,
        nonce,
        Uint8List(0),
      );

      cipher.init(false, params);
      final decrypted = cipher.process(cipherTextAndTag);

      return decrypted;
    } catch (e) {
      if (e is Failure) rethrow;
      throw const NetworkFailure(
          'Failed to decrypt offline material. Authentication tag or ciphertext corrupted.');
    }
  }
}
