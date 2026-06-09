/**
 * ReportState 정의: 인터랙티브 Mock-up의 현재 논리적 단계를 관리한다.
 */
export type Stage = 'PAIN_POINT' | 'ANALYSIS' | 'SOLUTION';

/**
 * ComponentProps 정의: 각 섹션에 필요한 props와 데이터 구조를 강제한다.
 */
export interface ReportData {
  // Pain Point Data (Centralized Legacy)
  painPointTitle: string;
  pueValue: number; // Power Usage Effectiveness
  legacyFlowDescription: string;

  // Analysis Logic Data (Decentralization Concept)
  analysisConceptName: string; // e.g., "Energy Circulation"
  decentralizationBenefit: string;
  keyLogicSteps: { step: string; detail: string }[];

  // Solution Data (Final Action Plan)
  solutionGoal: string; // e.g., "Energy Sovereignty"
  ctaMessage: string;
}

export interface ReportProps {
    currentStage: Stage;
    setStage: (stage: Stage) => void;
}