import assert from "node:assert";
import {
  resetDependentFilters,
  filterSubjectsByYear,
  filterMaterialsByHierarchy,
  formatHierarchyBreadcrumb,
  HierarchyFilterState,
} from "./hierarchy";
import { Material } from "./materials";
import { Subject } from "./subjects";
import { Year, PlanType } from "./years";

export function runHierarchyDomainTests(): boolean {
  // Test 1: Dependent filter resets
  const initial: HierarchyFilterState = {
    yearId: "year-123",
    subjectId: "subj-456",
    topicId: "topic-789",
  };

  // Changing Year resets Subject & Topic
  const afterYearChange = resetDependentFilters(initial, "yearId", "year-999");
  assert.strictEqual(afterYearChange.yearId, "year-999");
  assert.strictEqual(afterYearChange.subjectId, "");
  assert.strictEqual(afterYearChange.topicId, "");

  // Changing Subject resets Topic
  const afterSubjectChange = resetDependentFilters(initial, "subjectId", "subj-888");
  assert.strictEqual(afterSubjectChange.yearId, "year-123");
  assert.strictEqual(afterSubjectChange.subjectId, "subj-888");
  assert.strictEqual(afterSubjectChange.topicId, "");

  // Test 2: Filter subjects by Year
  const sampleSubjects: Subject[] = [
    { id: "s1", yearId: "y1", name: "Anatomy", slug: "anatomy", sortOrder: 1 },
    { id: "s2", yearId: "y2", name: "Pathology", slug: "pathology", sortOrder: 2 },
  ];
  const filteredSubs = filterSubjectsByYear(sampleSubjects, "y1");
  assert.strictEqual(filteredSubs.length, 1);
  assert.strictEqual(filteredSubs[0].id, "s1");

  // Test 3: Filter materials by hierarchy
  const sampleYears: Year[] = [
    { id: "y1", name: "1st Year MBBS", slug: "year-1", sortOrder: 1, planType: PlanType.YEAR_1 },
  ];
  const sampleMaterials: Material[] = [
    {
      id: "m1",
      subjectId: "s1",
      topicId: "t1",
      title: "Upper Limb Notes",
      type: "PDF",
      fileKey: "k1",
      fileSizeBytes: "1000",
      isPublished: true,
      isDownloadable: true,
      isPastPaper: false,
      createdAt: "2026-09-03",
      subject: { name: "Anatomy", slug: "anatomy", year: { slug: "year-1" } },
    },
    {
      id: "m2",
      subjectId: "s2",
      topicId: "t2",
      title: "General Pathology",
      type: "PDF",
      fileKey: "k2",
      fileSizeBytes: "2000",
      isPublished: true,
      isDownloadable: true,
      isPastPaper: false,
      createdAt: "2026-09-03",
      subject: { name: "Pathology", slug: "pathology", year: { slug: "year-2" } },
    },
  ];

  // Filter by subject s1
  const matsBySub = filterMaterialsByHierarchy(
    sampleMaterials,
    { yearId: "", subjectId: "s1", topicId: "" },
    sampleSubjects,
    sampleYears
  );
  assert.strictEqual(matsBySub.length, 1);
  assert.strictEqual(matsBySub[0].id, "m1");

  // Filter by topic t1
  const matsByTopic = filterMaterialsByHierarchy(
    sampleMaterials,
    { yearId: "", subjectId: "s1", topicId: "t1" },
    sampleSubjects,
    sampleYears
  );
  assert.strictEqual(matsByTopic.length, 1);

  // Filter with no match
  const noMatch = filterMaterialsByHierarchy(
    sampleMaterials,
    { yearId: "y1", subjectId: "s2", topicId: "" },
    sampleSubjects,
    sampleYears
  );
  assert.strictEqual(noMatch.length, 0);

  // Test 4: Breadcrumb formatting
  const breadcrumb = formatHierarchyBreadcrumb("1st Year MBBS", "Gross Anatomy", "Upper Limb");
  assert.strictEqual(breadcrumb, "1st Year MBBS > Gross Anatomy > Upper Limb");

  return true;
}
