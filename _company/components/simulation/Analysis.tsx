import React from 'react';
import { useSimulationContext } from './SimulationContext';

// Analysis 단계 컴포넌트 (비교 차트 및 기술적 논리 제시)
const Analysis: React.FC = () => {
  const { advanceStage, state } = useSimulationContext();

  return (
    <section className="simulation-stage analysis">
      <h1>🔬 [State 2] 대안 분석 및 비교</h1>
      <p>문제 해결의 가능성을 탐색하고 기술적 구조를 학습합니다. 분산형 시스템(DER)과 중앙집중식 대비 효율을 시각적으로 보여줘야 합니다.</p>
      {/* 실제 UI: 인터랙티브 슬라이더/토글, Dual Axis 비교 차트 */}
      <div className="visualization-placeholder">
        [COMPARISON CHART] DER vs. Centralized (OPEX 절감률 비교)
      </div>
      <button 
        onClick={() => advanceStage('Solution')}
        className="cta-button next-step"
      >
        💰 경제적 가치 정량화하기 (→ Solution)
      </button>
    </section>
  );
};

export default Analysis;