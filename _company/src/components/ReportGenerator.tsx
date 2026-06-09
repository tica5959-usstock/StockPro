import React, { useState } from 'react';
import { Stage, ReportProps } from '../types/reportTypes';

// 더미 데이터: 실제 API 호출로 대체될 구조화된 데이터를 사용한다고 가정합니다.
const mockData: ReportData = {
    painPointTitle: "중앙 집중식의 한계: PUE 1.8",
    pueValue: 1.8,
    legacyFlowDescription: "과부하와 열 누수로 인한 막대한 OPEX 증가.",
    analysisConceptName: "분산형 에너지 순환 아키텍처 (Decentralized Energy Circulation)",
    decentralizationBenefit: "열 재활용 및 전력 소비 효율성 극대화",
    keyLogicSteps: [
        { step: "Step 1", detail: "모듈 단위로 열을 포착하고 분산 제어." },
        { step: "Step 2", detail: "포착된 열 에너지를 지역 난방 등 다른 시스템에 재활용(Heat Reuse)." },
        { step: "Step 3", detail: "시스템 전체의 전력 자립성을 확보하여 리스크를 최소화." }
    ],
    solutionGoal: "궁극적인 에너지 자립 및 회복 탄력성 확보 (Resilience)",
    ctaMessage: "지금, 시스템 아키텍처 전환에 투자해야 합니다.",
};

// --- 서브 컴포넌트 정의 (코드 가독성을 위해 내부 정의) ---

/**
 * 1단계: Pain Point 제시 (사용자 클릭 필요)
 */
const PainPointSection: React.FC<{ setStage: (stage: Stage) => void }> = ({ setStage }) => {
    return (
        <section className="p-8 bg-red-50 border-l-4 border-red-600 shadow-xl mb-12">
            <h2 className="text-3xl font-extrabold text-red-700 mb-4">{mockData.painPointTitle}</h2>
            <p className="text-xl mb-6">🚨 현황 진단: 현재의 구조는 지속 가능하지 않습니다.</p>
            
            {/* 핵심 지표 시뮬레이션 Placeholder */}
            <div className="bg-red-100 p-4 rounded-lg inline-block mr-4 my-2">
                PUE 값: <span className="text-3xl font-bold text-red-800">{mockData.pueValue}</span> (지속적 상승)
            </div>

            <div className="mt-6 p-4 bg-gray-50 border-l-4 border-gray-300">
                {/* Progressive Disclosure: 클릭하면 상세 내용 공개 */}
                <button 
                    onClick={() => alert(`[애니메이션 로직 실행] '과부하' 시각화 애니메이션 및 누수 비용 계산기가 활성화됩니다.`)}
                    className="text-red-600 font-semibold cursor-pointer hover:underline"
                >
                    ▶️ 중앙 집중식 전력망의 에너지 누수 과정 확인하기 (클릭)
                </button>
            </div>

            <button 
                onClick={() => setStage('ANALYSIS')}
                className="mt-8 px-8 py-3 bg-indigo-600 text-white font-bold rounded-lg hover:bg-indigo-700 transition duration-200"
            >
                → 이 문제의 근본적인 해결책 알아보기 (다음 단계로 이동)
            </button>
        </section>
    );
};

/**
 * 2단계: 분석 로직 제시 (사용자 클릭 필요)
 */
const AnalysisSection: React.FC<{ setStage: (stage: Stage) => void }> = ({ setStage }) => {
    return (
        <section className="p-8 bg-blue-50 border-l-4 border-blue-600 shadow-xl mb-12">
            <h2 className="text-3xl font-extrabold text-blue-700 mb-4">{mockData.analysisConceptName}</h2>
            <p className="text-xl mb-6">💡 혁신적인 접근: 시스템 아키텍처의 근본적 재설계가 필요합니다.</p>

            {/* 핵심 로직 플로우 (Progressive Disclosure) */}
            <div className="space-y-4 mt-8">
                <h3 className="text-2xl font-semibold text-blue-600 border-b pb-2">핵심 논리 흐름</h3>
                {mockData.keyLogicSteps.map((step, index) => (
                    <div key={index} className={`p-4 rounded-lg ${index === 0 ? 'bg-white shadow' : 'bg-blue-100 border-l-4 border-blue-400'}`}>
                        <strong className="text-xl text-blue-800">{step.step}.</strong> {step.detail}
                    </div>
                ))}
            </div>

            <button 
                onClick={() => setStage('SOLUTION')}
                className="mt-12 px-8 py-3 bg-green-600 text-white font-bold rounded-lg hover:bg-green-700 transition duration-200"
            >
                ✅ 이 논리를 기반으로 한 최종 투자 결론 확인하기 (최종 단계로 이동)
            </button>
        </section>
    );
};

/**
 * 3단계: 솔루션 및 CTA 제시 (최종 목적지)
 */
const SolutionSection: React.FC = () => {
    return (
        <section className="p-12 bg-green-50 border-l-4 border-green-600 shadow-2xl mb-12">
            <h2 className="text-4xl font-extrabold text-green-800 mb-4">최종 목표: 시스템 자립성 및 회복 탄력성 확보</h2>
            <p className="text-2xl text-gray-700 mb-8">{mockData.solutionGoal}</p>

            {/* 최종 의사결정 Mock-up 영역 */}
            <div className="grid grid-cols-3 gap-6 items-center bg-white p-10 rounded-xl border">
                <div>
                    <h3 className="text-xl font-bold text-indigo-700">리스크 분석 (Risk)</h3>
                    <p className="text-sm text-gray-500 mt-2">현재 방식 유지 시 예상되는 재무적 손실 규모.</p>
                </div>
                <div>
                    <h3 className="text-xl font-bold text-green-700">기회 포착 (Opportunity)</h3>
                    <p className="text-sm text-gray-500 mt-2">새로운 아키텍처로 달성 가능한 OPEX 절감률.</p>
                </div>
                 <div>
                    <h3 className="text-xl font-bold text-red-700">투자 필요 (Action)</h3>
                    <p className="text-sm text-gray-500 mt-2">지금 당장 아키텍처 전환에 대한 투자가 필수.</p>
                </div>
            </div>

            {/* CTA 버튼 */}
            <div className="mt-10 text-center">
                <button 
                    className="text-4xl font-black py-4 px-12 bg-yellow-500 text-gray-900 rounded-full hover:bg-yellow-600 transition duration-300 transform hover:scale-105"
                >
                    {mockData.ctaMessage} <span className="text-lg">(지금 결정하세요)</span>
                </button>
            </div>
        </section>
    );
};


/**
 * 메인 보고서 컴포넌트 (상태 관리 주체)
 */
const ReportGenerator: React.FC = () => {
    // 현재 단계(State)를 useState로 관리하며, 이 상태가 UI 전체의 흐름을 제어합니다.
    const [currentStage, setCurrentStage] = useState<Stage>('PAIN_POINT');

    const handleSetStage = (stage: Stage) => {
        setCurrentStage(stage);
    };

    return (
        <div className="max-w-4xl mx-auto bg-white p-8 shadow-lg rounded-xl">
            <h1 className="text-4xl font-black text-center mb-10 text-gray-900">AI 컴퓨팅 에너지 자립화 보고서</h1>
            {/* 3단계 인터랙티브 컴포넌트들을 현재 상태에 따라 조건부 렌더링 */}
            {currentStage === 'PAIN_POINT' && (
                <PainPointSection setStage={handleSetStage} />
            )}
            {currentStage === 'ANALYSIS' && (
                <AnalysisSection setStage={handleSetStage} />
            )}
            {currentStage === 'SOLUTION' && (
                <SolutionSection />
            )}
        </div>
    );
};

export default ReportGenerator;