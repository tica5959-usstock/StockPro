import React, { useState, useEffect, useRef } from 'react';

// --- [TYPE DEFINITIONS] ----------------------------------------
interface SimulatorProps {
  painPointData: { name: string; value: number; unit: string }; // Pain Point (손실액)
  analysisDataPoints: Array<{ x: number; y_loss: number; y_avoided: number }>; // 분석 데이터 포인트
}

/**
 * 핵심 상태 기반 시뮬레이터 컴포넌트.
 * 스크롤 위치에 따라 정보가 점진적으로 공개되는 로직을 구현합니다.
 */
const InteractiveSavingsSimulator: React.FC<SimulatorProps> = ({ painPointData, analysisDataPoints }) => {
  // 1. [STATE MANAGEMENT] 시뮬레이터의 현재 상태 정의 (핵심)
  const [state, setState] = useState<'initial' | 'analysis_triggered' | 'solution_revealed'>('initial');
  const containerRef = useRef<HTMLDivElement>(null);

  // 2. [INTERSECTION OBSERVER HOOK] 스크롤 이벤트 감지 로직 (상태 전환 트리거)
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            // 뷰포트에 진입하면 'analysis_triggered' 상태로 변경 시작
            setState('analysis_triggered');
          }
        });
      },
      { threshold: 0.1 } // 요소의 10%가 보이면 감지
    );

    if (containerRef.current) {
      observer.observe(containerRef.current);
    } else {
      return () => observer.disconnect();
    }

    // Cleanup function
    return () => {
      if (containerRef.current) {
        observer.unobserve(containerRef.current);
      }
    };
  }, []); // 마운트 시 한 번만 실행

  // 3. [EFFECTIVE LOGIC] 스크롤 위치에 따라 최종 상태를 'solution_revealed'로 전환하는 로직 (가정)
  useEffect(() => {
    const handleScroll = () => {
      const scrollY = window.scrollY;
      const rect = containerRef.current?.getBoundingClientRect();

      // 가상의 조건: 스크롤이 충분히 내려왔을 때 최종 상태로 전환
      if (rect && (rect.bottom > window.innerHeight * 0.7) && state === 'analysis_triggered') {
        setState('solution_revealed');
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [state]);


  // 4. [RENDERING LOGIC] 상태별로 다른 UI/UX를 제공합니다.
  const renderContent = () => {
    switch (state) {
      case 'initial':
        return <PainPointSection data={painPointData} />;

      case 'analysis_triggered':
        // 스크롤을 통해 사용자가 Pain Point를 인지하고, 분석 단계로 진입했음을 나타냄.
        return <AnalysisTransitionSection points={analysisDataPoints} />;

      case 'solution_revealed':
        // 모든 논리적 단계를 거쳐 최종 해답이 제시되는 순간 (최대 시각적 임팩트)
        return <SolutionRevealSection points={analysisDataPoints} painPointValue={painPointData.value} />;

      default:
        return null;
    }
  };

  return (
    <section ref={containerRef} className="simulator-section py-24 bg-gray-50">
      <h2 className="text-4xl font-bold text-center mb-16">OPEX 절감 시뮬레이터: 손실 회피의 가치를 증명합니다.</h2>
      {renderContent()}
    </section>
  );
};

// --- [COMPONENT DEFAULTS] ----------------------------------------

const PainPointSection: React.FC<{ data: any }> = ({ data }) => (
  <div className="text-center py-20 bg-red-50 border-l-8 border-red-600 max-w-4xl mx-auto">
    <h3 className="text-sm uppercase font-semibold text-red-700 mb-2">❌ 현재의 비효율성 (Pain Point)</h3>
    <p className="text-xl text-gray-600 mb-8">현재 시스템 구조가 지속하는 운영상의 손실을 직면하게 됩니다.</p>
    <div className="inline-block bg-red-100 p-6 rounded-lg shadow-inner">
      <p className="text-5xl font-extrabold text-red-800">{data.value.toLocaleString()} {data.unit}</p>
      <p className="mt-2 text-lg font-semibold text-gray-700">누적된 연간 운영 손실액 ({data.name})</p>
    </div>
  </div>
);

const AnalysisTransitionSection: React.FC<{ points: any[] }> = ({ points }) => (
  <div className="py-24 max-w-6xl mx-auto">
    <h3 className="text-3xl font-bold text-center mb-16 text-blue-700">🔍 분석 단계: 근본 원인 파악</h3>
    <p className="text-lg text-gray-700 mb-12 text-center max-w-3xl mx-auto">
      우리가 직면한 문제는 단순한 비용이 아니라, 시스템의 구조적 비효율성에서 발생하는 **회피 가능한 손실(Avoidable Loss)** 입니다.
    </p>
    {/* 여기에 상세 분석 데이터를 점진적으로 노출하는 차트/테이블 컴포넌트가 들어갑니다. */}
    <div className="bg-white p-8 rounded-xl shadow-lg border border-blue-200">
      <h4 className="text-2xl font-semibold mb-6 text-center">데이터 포인트 분석 (Loss vs Potential)</h4>
      {/* TODO: 실제 차트 라이브러리(Recharts 등)를 사용하여 points 데이터를 기반으로 인터랙티브 그래프 구현 */}
      <div className="text-gray-500 italic p-10 border-dashed border-2 border-gray-300 text-center">
        [Placeholder: Analysis Chart Component] <br /> (사용자 스크롤에 따라 데이터 라벨 및 축이 점진적으로 활성화되어야 함)
      </div>
    </div>
  </div>
);

const SolutionRevealSection: React.FC<{ points: any[], painPointValue: number }> = ({ points, painPointValue }) => {
  // 폭발적 증가 애니메이션의 핵심 로직 구현 (가상의 시뮬레이션)
  const totalAvoidedCost = Math.max(...points.map(p => p.y_avoided));

  return (
    <div className="text-center py-20 bg-green-50 rounded-xl shadow-2xl border-4 border-green-600 max-w-6xl mx-auto">
      <h3 className="text-sm uppercase font-bold text-green-700 mb-2 tracking-widest">✅ 해결책 발견 (Solution)</h3>
      <p className="text-5xl font-extrabold text-gray-800 mb-4">시스템 개선을 통해 확보 가능한 잠재적 가치</p>
      
      {/* 🚀 핵심 시각화: 손실액 대비 회피 비용의 폭발적인 증가 애니메이션 */}
      <div className="relative flex justify-center items-end h-64 mt-10">
        {/* 배경 그래프 (손실 영역) - 스크롤로 인해 점차 가려짐 */}
        <svg width="100%" height="100%" viewBox={`0 0 ${points.length * 80} 100`} preserveAspectRatio="none" className="absolute top-0 left-0 z-10">
          {/* Pain Point 기준선 (빨간색) */}
          <line x1="0" y1="95%" x2={`${points.length * 80}`} y2="95%" stroke="#EF4444" strokeWidth="3"/>
          {/* 손실 영역 그래프 - 이 부분이 사라지거나 극복됨을 암시 */}
           <path d="M0,95 L100,70 L200,80 L300,60 L${points.length * 80},75" fill="#FEE2E2" />
        </svg>

        {/* Solution Area (회피 비용) - 폭발적으로 증가 */}
        <div className="relative z-20 flex items-end justify-between w-[calc(100%-4rem)]">
          {[...points].reverse().map((p, index) => (
            <div key={index} style={{ width: `${80 / points.length}%` }} className="flex flex-col items-center transition-all duration-1000 ease-out transform translate-y-full opacity-0 animate-popIn">
              {/* 막대 그래프 (회피 비용) */}
              <div 
                className="bg-green-500 hover:bg-green-600 transition-transform duration-700 shadow-xl" 
                style={{ height: `${(p.y_avoided / totalAvoidedCost) * 90}%` }} // 비율로 높이 계산
              ></div>
              <span className="text-sm font-bold text-green-800 mt-2">{p.x}</span>
            </div>
          ))}
        </div>

      </div>
      
      {/* 최종 요약 */}
      <div className="mt-16 grid grid-cols-2 gap-8 max-w-xl mx-auto text-center">
        <div>
          <p className="text-lg font-semibold text-gray-700">기존 손실액 (Pain Point)</p>
          <p className="text-4xl font-extrabold text-red-600">{painPointValue.toLocaleString()} {painPointData.unit}</p>
        </div>
        <div>
          <p className="text-lg font-semibold text-gray-700">회피 가능한 총 비용 (Avoided Cost)</p>
          <p className="text-4xl font-extrabold text-green-600">{totalAvoidedCost.toLocaleString()} {painPointData.unit}</p>
        </div>
      </div>
    </div>
  );
};

export default InteractiveSavingsSimulator;