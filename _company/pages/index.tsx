import React from 'react';
import { SimulationProvider, useSimulationContext } from '../components/simulation/SimulationContext';
import PainPoint from '../components/simulation/PainPoint';
import Analysis from '../components/simulation/Analysis';
import Solution from '../components/simulation/Solution';

// 🚀 메인 시뮬레이션 컨테이너 (상태 기반 렌더링 담당)
const SimulationPageContent: React.FC = () => {
  const { state } = useSimulationContext();

  let CurrentComponent;
  switch (state.currentStage) {
    case 'Pain':
      CurrentComponent = <PainPoint />;
      break;
    case 'Analysis':
      CurrentComponent = <Analysis />;
      break;
    case 'Solution':
      CurrentComponent = <Solution />;
      break;
    default:
      CurrentComponent = <div>Error: Unknown Simulation State</div>;
  }

  return (
    <div className="simulation-container">
      {/* 전역 애니메이션 컨테이너가 이곳에 적용되어야 합니다. */}
      <main>
        {CurrentComponent}
      </main>
    </div>
  );
};

// 페이지 레벨에서 Provider로 감싸기
const HomePage: React.FC = () => (
  <SimulationProvider>
    <SimulationPageContent />
  </SimulationProvider>
);

export default HomePage;