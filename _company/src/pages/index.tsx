import React from 'react';
import ReportGenerator from '../components/ReportGenerator';

const HomePage: React.FC = () => {
    return (
        <div className="min-h-screen bg-gray-100 p-12">
            {/* 이 컴포넌트가 우리가 만든 인터랙티브 Mock-up입니다. */}
            <ReportGenerator />
        </div>
    );
};

export default HomePage;