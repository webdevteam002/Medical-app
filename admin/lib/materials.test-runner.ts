import assert from "node:assert";
import {
  formatFileSize,
  validateUploadMaterialPayload,
  UploadMaterialPayload,
} from "./materials";

export function runMaterialsDomainTests(): boolean {
  // Test 1: formatFileSize formatting helper
  assert.strictEqual(formatFileSize(500), "500 B");
  assert.strictEqual(formatFileSize(1024 * 500), "500.0 KB");
  assert.strictEqual(formatFileSize(1024 * 1024 * 2.5), "2.5 MB");

  // Test 2: Valid upload material payload passes validation
  const dummyFile = new File(["dummy pdf content"], "brachial-plexus.pdf", {
    type: "application/pdf",
  });

  const validPayload: UploadMaterialPayload = {
    file: dummyFile,
    subjectId: "550e8400-e29b-41d4-a716-446655440000",
    title: "Brachial Plexus Comprehensive Diagram Notes",
  };

  const validRes = validateUploadMaterialPayload(validPayload);
  assert.strictEqual(validRes.isValid, true);
  assert.strictEqual(Object.keys(validRes.errors).length, 0);

  // Test 3: Missing file fails validation
  const missingFileRes = validateUploadMaterialPayload({
    ...validPayload,
    file: null as unknown as File,
  });
  assert.strictEqual(missingFileRes.isValid, false);
  assert.strictEqual(missingFileRes.errors.file, "Please select a file to upload.");

  // Test 4: Missing subjectId fails validation
  const missingSubjectRes = validateUploadMaterialPayload({
    ...validPayload,
    subjectId: "",
  });
  assert.strictEqual(missingSubjectRes.isValid, false);
  assert.strictEqual(
    missingSubjectRes.errors.subjectId,
    "Parent subject is required."
  );

  // Test 5: Missing or short title fails validation
  const missingTitleRes = validateUploadMaterialPayload({
    ...validPayload,
    title: "A",
  });
  assert.strictEqual(missingTitleRes.isValid, false);
  assert.strictEqual(
    missingTitleRes.errors.title,
    "Material title must be at least 2 characters."
  );

  return true;
}
