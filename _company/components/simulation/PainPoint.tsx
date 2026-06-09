import React from 'react';
import { useSimulationContext } from './SimulationContext';

// Pain Point 단계 컴포넌트 (사용자 입력 유도 및 다음 스테이지 전환 버튼 포함)
const PainPoint: React.FC = () => {
  const { advanceStage, state } = useSimulationContext();

  return (
    <section className="simulation-stage pain-point">
      <h1>🚨 [State 1] 에너지 효율 실패 시나리오</h1>
      <p>현재 시스템의 취약성을 인지하고 손실액을 체감하는 단계입니다. 이 데이터는 사용자의 감정적 몰입(Pain)에 초점을 맞춥니다.</p>
      {/* 실제 UI: 대형 경고 타이포그래피, 깜빡이는 그래프 등 */}
      <div className="visualization-placeholder">
        {/* 여기에 실시간 손실액 시각화 컴포넌트가 들어갑니다. */}
        [VISUALIZATION] 현재의 운영 비용(OPEX) 대비 회피 가능한 최대 손실액: $X M
      </div>
      <button 
        onClick={() => advanceStage('Analysis')}
        disabled={state.currentStage !== 'Pain'} // 상태 검증을 통한 버튼 비활성화 방지
        className="cta-button next-step"
      >
        💡 손실 분석 보기 (→ Analysis)
      </button>
    </section>
  );
};

export default PainPoint;