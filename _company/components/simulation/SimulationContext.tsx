import React, { createContext, useContext, useState, useCallback } from 'react';

// 💡 정의된 상태 값 (Designer Spec 기반)
export type Stage = 'Pain' | 'Analysis' | 'Solution';

interface SimulationState {
  currentStage: Stage;
  simulationData: Record<string, any>; // 시뮬레이션 데이터를 담을 객체
}

interface SimulationContextType {
  state: SimulationState;
  advanceStage: (nextStage: Stage) => void;
  resetSimulation: () => void;
}

// Context 생성 및 기본값 설정
const SimulationContext = createContext<SimulationContextType | undefined>(undefined);

export const useSimulationContext = (): SimulationContextType => {
  const context = useContext(SimulationContext);
  if (!context) {
    throw new Error('useSimulationContext must be used within a SimulationProvider');
  }
  return context;
};

// Provider 컴포넌트 (핵심 상태 로직 포함)
export const SimulationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setState] = useState<SimulationState>({
    currentStage: 'Pain', // 초기 시작 단계는 Pain Point 인식
    simulationData: {},
  });

  /**
   * 다음 상태로 전환하는 로직 (상태 머신 역할을 수행)
   * @param nextStage - 이동할 목표 스테이지 ('Analysis' 또는 'Solution')
   */
  const advanceStage = useCallback((nextStage: Stage): void => {
    console.log(`[STATE CHANGE] Transitioning from ${state.currentStage} to ${nextStage}`);
    // 실제 구현 시, 여기서 다음 단계 진입에 필요한 데이터 로딩/전처리 로직 추가 필요
    setState(prevState => ({ 
        ...prevState, 
        currentStage: nextStage,
        simulationData: { ...prevState.simulationData, lastTransition: new Date().toISOString() } // 전환 기록
    }));
  }, [state.currentStage]);

  const resetSimulation = useCallback(() => {
    setState({
      currentStage: 'Pain',
      simulationData: {},
    });
  }, []);

  return (
    <SimulationContext.Provider value={{ state, advanceStage, resetSimulation }}>
      {children}
    </SimulationContext.Provider>
  );
};
export default SimulationProvider;