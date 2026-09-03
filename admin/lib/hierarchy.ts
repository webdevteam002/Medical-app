import { Year } from "./years";
import { Subject } from "./subjects";
import { Material } from "./materials";

export interface HierarchyFilterState {
  yearId: string;
  subjectId: string;
  topicId: string;
}

export function resetDependentFilters(
  current: HierarchyFilterState,
  changedField: "yearId" | "subjectId" | "topicId",
  newValue: string
): HierarchyFilterState {
  if (changedField === "yearId") {
    return {
      yearId: newValue,
      subjectId: "",
      topicId: "",
    };
  }
  if (changedField === "subjectId") {
    return {
      yearId: current.yearId,
      subjectId: newValue,
      topicId: "",
    };
  }
  return {
    ...current,
    topicId: newValue,
  };
}

export function filterSubjectsByYear(subjects: Subject[], yearId: string): Subject[] {
  if (!yearId) return subjects;
  return subjects.filter((s) => s.yearId === yearId);
}

export function filterMaterialsByHierarchy(
  materials: Material[],
  filters: HierarchyFilterState,
  subjects: Subject[],
  years: Year[]
): Material[] {
  return materials.filter((material) => {
    // 1. Year Filter
    if (filters.yearId) {
      const yearObj = years.find((y) => y.id === filters.yearId);
      const subjectObj = subjects.find((s) => s.id === material.subjectId);
      
      const matchesBySubjectYearId = subjectObj?.yearId === filters.yearId;
      const matchesBySlug = yearObj && material.subject?.year?.slug === yearObj.slug;

      if (!matchesBySubjectYearId && !matchesBySlug) {
        return false;
      }
    }

    // 2. Subject Filter
    if (filters.subjectId) {
      if (material.subjectId !== filters.subjectId) {
        return false;
      }
    }

    // 3. Topic Filter
    if (filters.topicId) {
      if (material.topicId !== filters.topicId) {
        return false;
      }
    }

    return true;
  });
}

export function formatHierarchyBreadcrumb(
  yearName?: string | null,
  subjectName?: string | null,
  topicName?: string | null
): string {
  const parts: string[] = [];
  if (yearName) parts.push(yearName);
  if (subjectName) parts.push(subjectName);
  if (topicName) parts.push(topicName);
  return parts.length > 0 ? parts.join(" > ") : "All Content Hierarchy";
}
