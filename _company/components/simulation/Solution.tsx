import React from 'react';
import { useSimulationContext } from './SimulationContext';

// Solution 단계 컴포넌트 (ROI 계산 및 최종 의사결정 유도)
const Solution: React.FC = () => {
  const { state, resetSimulation } = useSimulationContext();

  return (
    <section className="simulation-stage solution">
      <h1>✅ [State 3] 투자 결정 및 ROI 확보</h1>
      <p>최종적으로 얻을 수 있는 경제적 가치(ROI)를 계산하고 명확한 액션 플랜을 제시합니다. 사용자가 가장 안도감을 느끼는 지점입니다.</p>
      {/* 실제 UI: KPI 요약 카드, 계좌 잔고 변화 애니메이션 */}
      <div className="visualization-placeholder">
        [KPI SUMMARY] 예상 ROI: +25% / 회피 비용액: $Y M
      </div>
      <button 
        onClick={resetSimulation}
        className="cta-button reset-button"
      >
        처음부터 다시 시뮬레이션하기
      </button>
    </section>
  );
};

export default Solution;