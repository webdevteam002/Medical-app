import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'app.dart';
import 'core/security/security_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
  // Android FLAG_SECURE / Windows SetWindowDisplayAffinity — keep on for the
  // whole session so exams and study content cannot be captured.
  await SecurityService().enableSecureScreen();
  runApp(const MedStudyApp());
}
