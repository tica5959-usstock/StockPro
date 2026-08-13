//+------------------------------------------------------------------+
//|                                           StockPro_Scalper.mq4   |
//|                                                                  |
//|  추세필터(상위TF) + 모멘텀 눌림목 진입(하위TF) 스캘핑 EA          |
//|  대상: GOLD# / USDJPY#   권장 TF: M5 ~ M15                       |
//|                                                                  |
//|  청산 모드는 입력변수로 선택:                                     |
//|    - 고정 TP                                                     |
//|    - 트레일링                                                    |
//|    - 부분청산 + 러너 트레일링 (권장)                              |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property description "StockPro Momentum Scalper - GOLD# / USDJPY#"

//+------------------------------------------------------------------+
//| 열거형                                                            |
//+------------------------------------------------------------------+
enum ENUM_EXIT_MODE
{
   EXIT_FIXED_TP      = 0,  // 고정 TP (트레일링 없음)
   EXIT_TRAILING      = 1,  // 트레일링만 (TP 없음)
   EXIT_PARTIAL_RUNNER= 2   // 부분청산 + 러너 트레일링 (권장)
};

enum ENUM_OSC_TYPE
{
   OSC_RSI   = 0,  // RSI
   OSC_STOCH = 1   // Stochastic
};

enum ENUM_LOT_MODE
{
   LOT_RISK_PERCENT = 0,  // 리스크 % 기반 자동 계산 (권장)
   LOT_FIXED        = 1   // 고정 랏
};

//+------------------------------------------------------------------+
//| 입력변수 - 기본                                                   |
//+------------------------------------------------------------------+
input string  __s1__            = "===== 기본 =====";        // .
input int     InpMagicNumber    = 20260813;                   // 매직넘버 (차트별로 다르게)
input string  InpOrderComment   = "SP_Scalper";               // 주문 코멘트
input int     InpSlippage       = 30;                         // 허용 슬리피지 (points)
input bool    InpEnableTrading  = true;                       // 신규 진입 허용

//+------------------------------------------------------------------+
//| 입력변수 - 진입 신호                                              |
//+------------------------------------------------------------------+
input string  __s2__            = "===== 진입 신호 =====";    // .
input ENUM_TIMEFRAMES InpTrendTF= PERIOD_H1;                  // 추세 판단 타임프레임
input int     InpEmaFast        = 50;                         // 추세 EMA (빠름)
input int     InpEmaSlow        = 200;                        // 추세 EMA (느림)
input bool    InpUseAdx         = true;                       // ADX 추세강도 필터 사용
input int     InpAdxPeriod      = 14;                         // ADX 기간
input double  InpAdxMin         = 20.0;                       // ADX 최소값 (미만이면 거래 안함)

input ENUM_TIMEFRAMES InpEntryTF= PERIOD_CURRENT;             // 진입 트리거 타임프레임
input ENUM_OSC_TYPE   InpOscType= OSC_RSI;                    // 오실레이터 종류
input bool    InpSignalOnBarClose = true;                     // 봉 마감 확정 후 판단 (리페인트 방지)

input int     InpRsiPeriod      = 14;                         // RSI 기간
input double  InpRsiBuyLevel    = 40.0;                       // RSI 매수 눌림목 레벨
input double  InpRsiSellLevel   = 60.0;                       // RSI 매도 눌림목 레벨

input int     InpStochK         = 5;                          // Stochastic %K
input int     InpStochD         = 3;                          // Stochastic %D
input int     InpStochSlow      = 3;                          // Stochastic Slowing
input double  InpStochBuyLevel  = 30.0;                       // Stoch 매수 과매도 레벨
input double  InpStochSellLevel = 70.0;                       // Stoch 매도 과매수 레벨

//+------------------------------------------------------------------+
//| 입력변수 - 리스크 / 자금관리                                       |
//+------------------------------------------------------------------+
input string  __s3__            = "===== 리스크 =====";       // .
input ENUM_LOT_MODE InpLotMode  = LOT_RISK_PERCENT;           // 랏 계산 방식
input double  InpRiskPercent    = 0.4;                        // 거래당 리스크 (계좌 %)
input double  InpFixedLot       = 0.01;                       // 고정 랏 (고정 모드일 때)
input bool    InpAllowMinLotUp  = false;                      // 최소랏 미달 시 최소랏으로 올림(리스크 초과 감수)

input int     InpAtrPeriod      = 14;                         // ATR 기간
input ENUM_TIMEFRAMES InpAtrTF  = PERIOD_M15;                 // ATR 타임프레임
input double  InpSlAtrMult      = 1.5;                        // 손절 = ATR x (배수)
input double  InpTpRR           = 1.5;                        // 익절 R:R 배수 (SL 대비)

input int     InpMaxPositions   = 1;                          // 동시 보유 최대 포지션 수
input double  InpDailyLossPct   = 3.0;                        // 일일 손실 한도 (%, 0=사용안함)
input double  InpDailyProfitPct = 0.0;                        // 일일 익절 한도 (%, 0=사용안함)
input int     InpMaxConsecLoss  = 4;                          // 연속 손절 허용 횟수 (0=사용안함)
input int     InpCooldownMin    = 60;                         // 서킷브레이커 쿨다운 (분)

//+------------------------------------------------------------------+
//| 입력변수 - 청산                                                   |
//+------------------------------------------------------------------+
input string  __s4__            = "===== 청산 =====";         // .
input ENUM_EXIT_MODE InpExitMode= EXIT_PARTIAL_RUNNER;        // 청산 모드
input bool    InpUseBreakeven   = true;                       // 브레이크이븐 이동 사용
input double  InpBeTriggerR     = 0.6;                        // BE 발동 시점 (R 배수)
input int     InpBeOffsetPoints = 20;                         // BE 오프셋 (points, 비용 커버)

input double  InpTrailAtrMult   = 1.2;                        // 트레일링 폭 = ATR x (배수)
input int     InpTrailStepPoints= 50;                         // 트레일링 최소 갱신 간격 (points)
input double  InpTrailStartR    = 1.0;                        // 트레일링 시작 시점 (R 배수)

input double  InpPartialPct     = 60.0;                       // 1차 부분청산 비율 (%)
input double  InpPartialTriggerR= 1.0;                        // 부분청산 발동 시점 (R 배수)
input bool    InpRunnerClearTP  = true;                       // 러너 전환 시 TP 제거(트레일링이 상단 결정)

//+------------------------------------------------------------------+
//| 입력변수 - 필터                                                   |
//+------------------------------------------------------------------+
input string  __s5__            = "===== 필터 =====";         // .
input int     InpMaxSpreadPts   = 0;                          // 최대 허용 스프레드 (points, 0=사용안함)
input double  InpMaxSpreadAtrR  = 0.15;                       // 스프레드/ATR 최대 비율 (0=사용안함)
input bool    InpUseSessionFilt = true;                       // 세션 시간 필터 사용
input int     InpSessionStartHr = 8;                          // 거래 시작 시각 (서버시간 0-23)
input int     InpSessionEndHr   = 21;                         // 거래 종료 시각 (서버시간 0-23)
input bool    InpUseFridayStop  = true;                       // 금요일 마감 전 진입 중단
input int     InpFridayStopHr   = 19;                         // 금요일 진입 중단 시각
input int     InpMinBarsBetween = 2;                          // 진입 간 최소 봉 간격

//+------------------------------------------------------------------+
//| 입력변수 - 대시보드                                               |
//+------------------------------------------------------------------+
input string  __s6__            = "===== 대시보드 =====";     // .
input bool    InpShowDash       = true;                       // 대시보드 표시
input ENUM_BASE_CORNER InpDashCorner = CORNER_LEFT_UPPER;     // 표시 위치 (모서리)
input int     InpDashX          = 12;                         // 가로 여백 (px)
input int     InpDashY          = 22;                         // 세로 여백 (px)
input int     InpDashWidth      = 268;                        // 패널 폭 (px)
input int     InpDashOpacity    = 78;                         // 불투명도 (0=투명 ~ 100=불투명)
input string  InpDashFont       = "Malgun Gothic";            // 폰트 (한글 지원 폰트)
input int     InpDashFontSize   = 9;                          // 폰트 크기
input color   InpDashPanelColor = C'22,26,34';                // 패널 배경색
input color   InpDashAccent     = C'80,170,255';              // 강조색
input color   InpDashTextColor  = C'220,226,236';             // 기본 텍스트색
input color   InpDashDimColor   = C'138,148,166';             // 흐린 텍스트색
input color   InpDashProfitClr  = C'86,214,140';              // 수익 색
input color   InpDashLossClr    = C'242,110,110';             // 손실 색
input color   InpDashWarnClr    = C'240,180,80';              // 경고 색

//+------------------------------------------------------------------+
//| 전역 변수                                                         |
//+------------------------------------------------------------------+
string   g_prefix;                 // 오브젝트 이름 접두사
datetime g_lastBarTime   = 0;      // 진입TF 마지막 봉 시각
datetime g_lastEntryBar  = 0;      // 마지막 진입 봉 시각
datetime g_cooldownUntil = 0;      // 서킷브레이커 해제 시각
datetime g_lastCooldownTrig = 0;   // 쿨다운을 발동시킨 마지막 손절 청산시각 (재발동 방지)
bool     g_dashCollapsed = false;  // 대시보드 접힘 상태
int      g_panelHeight   = 400;    // 패널 높이 (동적 계산)

// 포지션 추적 레지스트리
// rDist = 진입 시점의 초기 손절 거리(1R). BE 이동 후에도 R 배수를 정확히 계산하기 위해 보관.
struct PosTrack
{
   int    ticket;
   double rDist;
   bool   partialDone;     // 부분청산이 실제로 체결됨 -> 잔여분은 러너(트레일링 대상)
   bool   partialSkipped;  // 최소랏 제약으로 쪼갤 수 없어 건너뜀 -> 고정 TP 유지
};
PosTrack g_track[];

// 통계 캐시
struct StatsData
{
   int      totalTrades;
   int      wins;
   int      losses;
   double   grossProfit;
   double   grossLoss;      // 양수로 저장
   double   netProfit;
   double   winRate;
   double   profitFactor;
   double   avgWin;
   double   avgLoss;
   double   expectancyR;
   double   maxDD;          // 금액
   double   maxDDPct;       // %
   int      todayTrades;
   double   todayProfit;
   int      consecLosses;
};
StatsData g_stats;
int      g_lastHistoryTotal = -1;
datetime g_lastStatsRefresh = 0;

// 현재 상태 (대시보드 표시용)
struct RuntimeState
{
   int      trendDir;         // 1 상승, -1 하락, 0 없음
   double   adxValue;
   bool     adxWeak;          // ADX가 임계값 미만
   double   oscValue;
   double   atrValue;
   int      spreadPts;
   bool     spreadOk;
   bool     sessionOk;
   bool     dailyLimitHit;
   bool     cooldownActive;
   string   blockReason;
   double   buyLots;
   double   sellLots;
   int      buyCount;
   int      sellCount;
   double   floatingPL;
   bool     partialFallback;  // 최소랏 미달로 부분청산 폴백됨
};
RuntimeState g_rt;

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   g_prefix = "SPD_" + IntegerToString(InpMagicNumber) + "_";

   if(InpEmaFast >= InpEmaSlow)
   {
      Print("[StockPro] 설정 오류: 빠른 EMA 기간이 느린 EMA보다 크거나 같습니다.");
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(InpRiskPercent <= 0.0 && InpLotMode == LOT_RISK_PERCENT)
   {
      Print("[StockPro] 설정 오류: 리스크 %는 0보다 커야 합니다.");
      return(INIT_PARAMETERS_INCORRECT);
   }
   if(InpPartialPct <= 0.0 || InpPartialPct >= 100.0)
   {
      if(InpExitMode == EXIT_PARTIAL_RUNNER)
      {
         Print("[StockPro] 설정 오류: 부분청산 비율은 0~100 사이여야 합니다.");
         return(INIT_PARAMETERS_INCORRECT);
      }
   }

   if(InpExitMode == EXIT_PARTIAL_RUNNER && InpTpRR <= InpPartialTriggerR)
   {
      Print("[StockPro] 설정 오류: 부분청산+러너 모드에서는 InpTpRR(", InpTpRR,
            ")이 InpPartialTriggerR(", InpPartialTriggerR, ")보다 커야 합니다. ",
            "그렇지 않으면 부분청산 전에 TP가 먼저 체결됩니다.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   ArrayResize(g_track, 0);
   ZeroStats();
   RebuildTracking();   // 재시작 시 보유 포지션 복구

   RefreshStats(true);
   EventSetTimer(1);

   if(InpShowDash)
      BuildDashboard();

   Print("[StockPro] 초기화 완료 | ", _Symbol, " | 매직 ", InpMagicNumber,
         " | 청산모드 ", ExitModeName(InpExitMode));

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   DeleteDashboard();
}

//+------------------------------------------------------------------+
//| OnTimer - 대시보드 갱신                                           |
//+------------------------------------------------------------------+
void OnTimer()
{
   RefreshStats(false);
   ScanOpenPositions();
   PruneTracking();
   UpdateMarketState();
   if(InpShowDash)
      UpdateDashboard();
}

//+------------------------------------------------------------------+
//| 대시보드용 시장/필터 상태 갱신                                     |
//| OnTick의 진입 경로는 필터에서 조기 return되기 때문에,              |
//| 표시용 값은 여기서 매초 독립적으로 갱신한다.                        |
//+------------------------------------------------------------------+
void UpdateMarketState()
{
   g_rt.atrValue = iATR(_Symbol, InpAtrTF, InpAtrPeriod, 1);

   // EMA 배열 방향 (ADX와 무관하게 표시)
   double emaF = iMA(_Symbol, InpTrendTF, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE, 1);
   double emaS = iMA(_Symbol, InpTrendTF, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE, 1);
   g_rt.trendDir = (emaF > emaS) ? 1 : ((emaF < emaS) ? -1 : 0);

   if(InpUseAdx)
   {
      g_rt.adxValue = iADX(_Symbol, InpTrendTF, InpAdxPeriod, PRICE_CLOSE, MODE_MAIN, 1);
      g_rt.adxWeak  = (g_rt.adxValue < InpAdxMin);
   }
   else g_rt.adxWeak = false;

   // 오실레이터 현재값
   int sh = InpSignalOnBarClose ? 1 : 0;
   ENUM_TIMEFRAMES tf = EntryTF();
   if(InpOscType == OSC_RSI)
      g_rt.oscValue = iRSI(_Symbol, tf, InpRsiPeriod, PRICE_CLOSE, sh);
   else
      g_rt.oscValue = iStochastic(_Symbol, tf, InpStochK, InpStochD, InpStochSlow,
                                  MODE_SMA, 0, MODE_MAIN, sh);

   // 필터 상태 (부수효과로 g_rt 플래그 갱신)
   CheckSession();
   CheckSpread();
   CheckDailyLimit();
   g_rt.cooldownActive = (g_cooldownUntil > TimeCurrent());
}

//+------------------------------------------------------------------+
//| OnTick                                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1) 시장 상태 갱신
   g_rt.atrValue  = iATR(_Symbol, InpAtrTF, InpAtrPeriod, 1);
   g_rt.spreadPts = (int)MarketInfo(_Symbol, MODE_SPREAD);

   // 2) 보유 포지션 관리 (매 틱)
   ManageOpenPositions();

   // 3) 신규 진입 판단
   if(!InpEnableTrading) { g_rt.blockReason = "진입 비활성"; return; }

   // 봉 마감 확정 모드면 새 봉에서만 판단
   datetime curBar = iTime(_Symbol, EntryTF(), 0);
   bool newBar = (curBar != g_lastBarTime);
   if(newBar) g_lastBarTime = curBar;
   if(InpSignalOnBarClose && !newBar) return;

   if(!PassAllFilters()) return;

   // 표시용 g_rt.trendDir은 UpdateMarketState가 관리하므로 여기서 덮어쓰지 않는다.
   int trend = TrendDirection();
   if(trend == 0) { g_rt.blockReason = "추세 없음"; return; }

   int trigger = EntryTrigger(trend);
   if(trigger == 0) { g_rt.blockReason = "신호 대기"; return; }

   g_rt.blockReason = "";
   OpenPosition(trigger);
}

//+------------------------------------------------------------------+
//| 진입 타임프레임 해석                                              |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES EntryTF()
{
   if(InpEntryTF == PERIOD_CURRENT) return((ENUM_TIMEFRAMES)Period());
   return(InpEntryTF);
}

//+------------------------------------------------------------------+
//| 추세 방향 판단 (상위 TF)                                          |
//+------------------------------------------------------------------+
int TrendDirection()
{
   double emaF = iMA(_Symbol, InpTrendTF, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE, 1);
   double emaS = iMA(_Symbol, InpTrendTF, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE, 1);

   if(InpUseAdx)
   {
      g_rt.adxValue = iADX(_Symbol, InpTrendTF, InpAdxPeriod, PRICE_CLOSE, MODE_MAIN, 1);
      if(g_rt.adxValue < InpAdxMin) return(0);
   }

   if(emaF > emaS) return(1);
   if(emaF < emaS) return(-1);
   return(0);
}

//+------------------------------------------------------------------+
//| 진입 트리거 (하위 TF 오실레이터 눌림목 복귀)                       |
//+------------------------------------------------------------------+
int EntryTrigger(int trend)
{
   int sh = InpSignalOnBarClose ? 1 : 0;
   ENUM_TIMEFRAMES tf = EntryTF();

   if(InpOscType == OSC_RSI)
   {
      double r0 = iRSI(_Symbol, tf, InpRsiPeriod, PRICE_CLOSE, sh);
      double r1 = iRSI(_Symbol, tf, InpRsiPeriod, PRICE_CLOSE, sh + 1);
      g_rt.oscValue = r0;

      // 상승추세: RSI가 눌림목 레벨 아래로 갔다가 위로 복귀 -> 매수
      if(trend > 0 && r1 <= InpRsiBuyLevel && r0 > InpRsiBuyLevel) return(1);
      // 하락추세: RSI가 반등 레벨 위로 갔다가 아래로 복귀 -> 매도
      if(trend < 0 && r1 >= InpRsiSellLevel && r0 < InpRsiSellLevel) return(-1);
   }
   else
   {
      double k0 = iStochastic(_Symbol, tf, InpStochK, InpStochD, InpStochSlow,
                              MODE_SMA, 0, MODE_MAIN, sh);
      double d0 = iStochastic(_Symbol, tf, InpStochK, InpStochD, InpStochSlow,
                              MODE_SMA, 0, MODE_SIGNAL, sh);
      double k1 = iStochastic(_Symbol, tf, InpStochK, InpStochD, InpStochSlow,
                              MODE_SMA, 0, MODE_MAIN, sh + 1);
      double d1 = iStochastic(_Symbol, tf, InpStochK, InpStochD, InpStochSlow,
                              MODE_SMA, 0, MODE_SIGNAL, sh + 1);
      g_rt.oscValue = k0;

      // 상승추세: 과매도 구간에서 %K가 %D를 상향 돌파 -> 매수
      if(trend > 0 && k1 <= d1 && k0 > d0 && k1 < InpStochBuyLevel) return(1);
      // 하락추세: 과매수 구간에서 %K가 %D를 하향 돌파 -> 매도
      if(trend < 0 && k1 >= d1 && k0 < d0 && k1 > InpStochSellLevel) return(-1);
   }
   return(0);
}

//+------------------------------------------------------------------+
//| 전체 필터 검사                                                    |
//+------------------------------------------------------------------+
bool PassAllFilters()
{
   // 쿨다운
   g_rt.cooldownActive = (g_cooldownUntil > TimeCurrent());
   if(g_rt.cooldownActive) { g_rt.blockReason = "서킷브레이커 쿨다운"; return(false); }

   // 일일 손실/익절 한도
   if(CheckDailyLimit()) { g_rt.blockReason = "일일 한도 도달"; return(false); }

   // 동시 포지션 수
   if(CountPositions() >= InpMaxPositions) { g_rt.blockReason = "최대 포지션 도달"; return(false); }

   // 세션 시간
   if(!CheckSession()) { g_rt.blockReason = "세션 시간 외"; return(false); }

   // 스프레드
   if(!CheckSpread()) { g_rt.blockReason = "스프레드 확대"; return(false); }

   // 진입 간 최소 봉 간격
   if(InpMinBarsBetween > 0 && g_lastEntryBar > 0)
   {
      int barsSince = iBarShift(_Symbol, EntryTF(), g_lastEntryBar, false);
      if(barsSince < InpMinBarsBetween) { g_rt.blockReason = "진입 간격 대기"; return(false); }
   }

   return(true);
}

//+------------------------------------------------------------------+
//| 세션 시간 검사                                                    |
//+------------------------------------------------------------------+
bool CheckSession()
{
   datetime now = TimeCurrent();
   int hr  = TimeHour(now);
   int dow = TimeDayOfWeek(now);

   if(InpUseFridayStop && dow == 5 && hr >= InpFridayStopHr)
   { g_rt.sessionOk = false; return(false); }

   if(!InpUseSessionFilt) { g_rt.sessionOk = true; return(true); }

   bool ok;
   if(InpSessionStartHr <= InpSessionEndHr)
      ok = (hr >= InpSessionStartHr && hr < InpSessionEndHr);
   else // 자정을 넘는 세션
      ok = (hr >= InpSessionStartHr || hr < InpSessionEndHr);

   g_rt.sessionOk = ok;
   return(ok);
}

//+------------------------------------------------------------------+
//| 스프레드 검사                                                     |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   int spread = (int)MarketInfo(_Symbol, MODE_SPREAD);
   g_rt.spreadPts = spread;

   if(InpMaxSpreadPts > 0 && spread > InpMaxSpreadPts)
   { g_rt.spreadOk = false; return(false); }

   if(InpMaxSpreadAtrR > 0.0 && g_rt.atrValue > 0.0)
   {
      double atrPts = g_rt.atrValue / _Point;
      if(atrPts > 0 && (spread / atrPts) > InpMaxSpreadAtrR)
      { g_rt.spreadOk = false; return(false); }
   }

   g_rt.spreadOk = true;
   return(true);
}

//+------------------------------------------------------------------+
//| 일일 한도 검사                                                    |
//+------------------------------------------------------------------+
bool CheckDailyLimit()
{
   double balance = AccountBalance();
   if(balance <= 0.0) return(false);

   double pct = (g_stats.todayProfit / balance) * 100.0;

   if(InpDailyLossPct > 0.0 && pct <= -InpDailyLossPct)
   { g_rt.dailyLimitHit = true; return(true); }

   if(InpDailyProfitPct > 0.0 && pct >= InpDailyProfitPct)
   { g_rt.dailyLimitHit = true; return(true); }

   g_rt.dailyLimitHit = false;
   return(false);
}

//+------------------------------------------------------------------+
//| 신규 포지션 진입                                                  |
//+------------------------------------------------------------------+
void OpenPosition(int dir)
{
   double atr = g_rt.atrValue;
   if(atr <= 0.0) { Print("[StockPro] ATR 값이 유효하지 않아 진입을 건너뜁니다."); return; }

   double slDist = atr * InpSlAtrMult;
   slDist = ClampToStopLevel(slDist);

   double price, sl, tp;
   int    type;

   RefreshRates();

   if(dir > 0)
   {
      type  = OP_BUY;
      price = NormalizeDouble(Ask, _Digits);
      sl    = NormalizeDouble(price - slDist, _Digits);
      tp    = (InpExitMode == EXIT_TRAILING)
              ? 0.0
              : NormalizeDouble(price + slDist * InpTpRR, _Digits);
   }
   else
   {
      type  = OP_SELL;
      price = NormalizeDouble(Bid, _Digits);
      sl    = NormalizeDouble(price + slDist, _Digits);
      tp    = (InpExitMode == EXIT_TRAILING)
              ? 0.0
              : NormalizeDouble(price - slDist * InpTpRR, _Digits);
   }

   double lots = CalcLots(slDist);
   if(lots <= 0.0)
   {
      g_rt.blockReason = "랏 계산 실패(최소랏 미달)";
      return;
   }

   // 부분청산 모드인데 랏을 쪼갤 수 없으면 고정 TP로 폴백
   double minLot = MarketInfo(_Symbol, MODE_MINLOT);
   g_rt.partialFallback = (InpExitMode == EXIT_PARTIAL_RUNNER && lots < minLot * 2.0);

   int ticket = OrderSend(_Symbol, type, lots, price, InpSlippage, sl, tp,
                          InpOrderComment, InpMagicNumber, 0,
                          (dir > 0 ? clrDodgerBlue : clrTomato));

   if(ticket < 0)
   {
      int err = GetLastError();
      Print("[StockPro] 주문 실패 err=", err, " ", ErrorText(err),
            " | lots=", DoubleToString(lots, 2),
            " sl=", DoubleToString(sl, _Digits),
            " tp=", DoubleToString(tp, _Digits));
      return;
   }

   // 초기 1R 거리를 등록해 두어야 BE 이동 후에도 R 배수가 정확히 계산된다.
   TrackAdd(ticket, slDist, false);

   g_lastEntryBar = iTime(_Symbol, EntryTF(), 0);
   Print("[StockPro] 진입 #", ticket, " ", (dir > 0 ? "BUY" : "SELL"),
         " lots=", DoubleToString(lots, 2),
         " SL=", DoubleToString(sl, _Digits),
         " TP=", DoubleToString(tp, _Digits),
         (g_rt.partialFallback ? " [부분청산 불가 -> 고정TP 폴백]" : ""));
}

//+------------------------------------------------------------------+
//| 랏 사이즈 계산                                                    |
//+------------------------------------------------------------------+
double CalcLots(double slDistance)
{
   double minLot = MarketInfo(_Symbol, MODE_MINLOT);
   double maxLot = MarketInfo(_Symbol, MODE_MAXLOT);
   double step   = MarketInfo(_Symbol, MODE_LOTSTEP);
   if(step <= 0.0) step = 0.01;

   double lots;

   if(InpLotMode == LOT_FIXED)
   {
      lots = InpFixedLot;
   }
   else
   {
      double riskAmount = AccountBalance() * (InpRiskPercent / 100.0);

      double tickValue = MarketInfo(_Symbol, MODE_TICKVALUE);
      double tickSize  = MarketInfo(_Symbol, MODE_TICKSIZE);
      if(tickSize <= 0.0 || tickValue <= 0.0)
      {
         Print("[StockPro] TICKVALUE/TICKSIZE 조회 실패. 랏 계산 불가.");
         return(0.0);
      }

      // 1랏 기준 손절 시 손실 금액
      double lossPerLot = (slDistance / tickSize) * tickValue;
      if(lossPerLot <= 0.0) return(0.0);

      lots = riskAmount / lossPerLot;
   }

   // 스텝 단위로 내림 (리스크 초과 방지)
   lots = MathFloor(lots / step + 0.0000001) * step;

   if(lots < minLot)
   {
      if(InpAllowMinLotUp)
      {
         lots = minLot;
         Print("[StockPro] 경고: 계산 랏이 최소랏 미달 -> 최소랏(", DoubleToString(minLot, 2),
               ") 사용. 설정 리스크를 초과합니다.");
      }
      else
      {
         Print("[StockPro] 계산 랏(", DoubleToString(lots, 4), ")이 최소랏 미달. 진입 건너뜀. ",
               "계좌 잔고를 늘리거나 리스크 %를 높이세요.");
         return(0.0);
      }
   }
   if(lots > maxLot) lots = maxLot;

   int lotDigits = LotDigits(step);
   lots = NormalizeDouble(lots, lotDigits);

   // 증거금 확인
   double marginNeeded = MarketInfo(_Symbol, MODE_MARGINREQUIRED) * lots;
   if(marginNeeded > AccountFreeMargin())
   {
      Print("[StockPro] 여유증거금 부족. 필요=", DoubleToString(marginNeeded, 2),
            " 여유=", DoubleToString(AccountFreeMargin(), 2));
      return(0.0);
   }

   return(lots);
}

//+------------------------------------------------------------------+
//| 랏 소수점 자리수                                                  |
//+------------------------------------------------------------------+
int LotDigits(double step)
{
   if(step >= 1.0)   return(0);
   if(step >= 0.1)   return(1);
   if(step >= 0.01)  return(2);
   return(3);
}

//+------------------------------------------------------------------+
//| 보유 포지션 관리 (BE / 부분청산 / 트레일링)                        |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != InpMagicNumber)        continue;
      if(OrderSymbol()      != _Symbol)               continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      double openPrice = OrderOpenPrice();
      double curSL     = OrderStopLoss();
      double lots      = OrderLots();
      int    ticket    = OrderTicket();
      bool   isBuy     = (OrderType() == OP_BUY);

      RefreshRates();
      double curPrice = isBuy ? Bid : Ask;

      // 진입 시점의 1R 거리 (레지스트리 우선, 없으면 추정 후 등록)
      double rDist = TrackRDist(ticket, openPrice, curSL);
      if(rDist <= 0.0) continue;

      double profitDist = isBuy ? (curPrice - openPrice) : (openPrice - curPrice);
      double rMultiple  = profitDist / rDist;

      // --- 1) 부분청산 (PARTIAL_RUNNER 모드) ---
      if(InpExitMode == EXIT_PARTIAL_RUNNER && !PartialAttempted(ticket))
      {
         if(rMultiple >= InpPartialTriggerR)
         {
            // 부분청산이 체결되면 원본 티켓은 닫히고 잔여분에 새 티켓이 부여된다.
            // 이번 틱에서는 여기서 종료하고, 다음 틱에 새 티켓으로 BE/트레일링을 처리한다.
            if(TryPartialClose(ticket, lots, isBuy, rDist)) continue;
         }
      }

      // --- 2) 브레이크이븐 이동 ---
      if(InpUseBreakeven && rMultiple >= InpBeTriggerR)
         TryMoveBreakeven(ticket, openPrice, curSL, isBuy);

      // --- 3) 트레일링 ---
      // PARTIAL_RUNNER에서는 실제로 부분청산된 "러너"만 트레일링한다.
      // 최소랏 제약으로 쪼개지 못한 포지션은 고정 TP를 그대로 유지한다.
      if(InpExitMode == EXIT_TRAILING ||
         (InpExitMode == EXIT_PARTIAL_RUNNER && PartialExecuted(ticket)))
      {
         if(rMultiple >= InpTrailStartR)
            TryTrailStop(ticket, curPrice, curSL, isBuy);
      }
   }
}

//+------------------------------------------------------------------+
//| 부분청산 시도                                                     |
//+------------------------------------------------------------------+
bool TryPartialClose(int ticket, double lots, bool isBuy, double rDist)
{
   double minLot = MarketInfo(_Symbol, MODE_MINLOT);
   double step   = MarketInfo(_Symbol, MODE_LOTSTEP);
   if(step <= 0.0) step = 0.01;

   // 최소랏의 2배 미만이면 쪼갤 수 없음 -> 전량 고정 TP 유지 (폴백)
   if(lots < minLot * 2.0)
   {
      MarkPartialSkipped(ticket);
      g_rt.partialFallback = true;
      return(false);
   }

   double closeLots = lots * (InpPartialPct / 100.0);
   closeLots = MathFloor(closeLots / step + 0.0000001) * step;
   closeLots = NormalizeDouble(closeLots, LotDigits(step));

   // 청산분과 잔여분 모두 최소랏 이상이어야 함
   if(closeLots < minLot)
      closeLots = minLot;
   if((lots - closeLots) < minLot)
      closeLots = NormalizeDouble(lots - minLot, LotDigits(step));

   if(closeLots < minLot || closeLots >= lots)
   {
      MarkPartialSkipped(ticket);
      g_rt.partialFallback = true;
      return(false);
   }

   RefreshRates();
   double price = isBuy ? Bid : Ask;

   if(!OrderClose(ticket, closeLots, NormalizeDouble(price, _Digits), InpSlippage, clrGold))
   {
      int err = GetLastError();
      Print("[StockPro] 부분청산 실패 #", ticket, " err=", err, " ", ErrorText(err));
      return(false);
   }

   MarkPartialDone(ticket);
   InheritRemainder(ticket, rDist);   // 잔여 티켓에 1R 정보 승계

   Print("[StockPro] 부분청산 #", ticket, " ", DoubleToString(closeLots, 2),
         " / ", DoubleToString(lots, 2), " 랏 청산 -> 잔여분 트레일링 전환");
   return(true);
}

//+------------------------------------------------------------------+
//| 브레이크이븐 이동                                                 |
//+------------------------------------------------------------------+
void TryMoveBreakeven(int ticket, double openPrice, double curSL, bool isBuy)
{
   double offset = InpBeOffsetPoints * _Point;
   double newSL  = isBuy ? (openPrice + offset) : (openPrice - offset);
   newSL = NormalizeDouble(newSL, _Digits);

   // 이미 BE 이상이면 스킵
   if(isBuy  && curSL >= newSL - _Point * 0.5) return;
   if(!isBuy && curSL <= newSL + _Point * 0.5 && curSL > 0.0) return;

   ModifyStopLoss(ticket, newSL, isBuy, "BE");
}

//+------------------------------------------------------------------+
//| 트레일링 스톱                                                     |
//+------------------------------------------------------------------+
void TryTrailStop(int ticket, double curPrice, double curSL, bool isBuy)
{
   double trailDist = g_rt.atrValue * InpTrailAtrMult;
   trailDist = ClampToStopLevel(trailDist);
   if(trailDist <= 0.0) return;

   double newSL = isBuy ? (curPrice - trailDist) : (curPrice + trailDist);
   newSL = NormalizeDouble(newSL, _Digits);

   double stepDist = InpTrailStepPoints * _Point;

   // 최소 갱신 간격 미달이면 서버 요청 자체를 보내지 않음
   if(isBuy)
   {
      if(curSL > 0.0 && newSL - curSL < stepDist) return;
      if(newSL <= curSL) return;
   }
   else
   {
      if(curSL > 0.0 && curSL - newSL < stepDist) return;
      if(curSL > 0.0 && newSL >= curSL) return;
   }

   ModifyStopLoss(ticket, newSL, isBuy, "TRAIL");
}

//+------------------------------------------------------------------+
//| SL 수정 (StopLevel 클램프 + 중복 요청 방지)                        |
//+------------------------------------------------------------------+
void ModifyStopLoss(int ticket, double newSL, bool isBuy, string tag)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;

   double curSL = OrderStopLoss();
   double curTP = OrderTakeProfit();

   // 값이 사실상 같으면 요청하지 않음 (에러 1 방지)
   if(MathAbs(curSL - newSL) < _Point * 0.5) return;

   // StopLevel / FreezeLevel 준수 확인
   RefreshRates();
   double stopLevel   = MarketInfo(_Symbol, MODE_STOPLEVEL) * _Point;
   double freezeLevel = MarketInfo(_Symbol, MODE_FREEZELEVEL) * _Point;
   double minDist     = MathMax(stopLevel, freezeLevel);

   double market = isBuy ? Bid : Ask;
   if(isBuy)
   {
      if(market - newSL < minDist) newSL = NormalizeDouble(market - minDist, _Digits);
      if(newSL >= market) return;
   }
   else
   {
      if(newSL - market < minDist) newSL = NormalizeDouble(market + minDist, _Digits);
      if(newSL <= market) return;
   }

   // 클램프 후 다시 중복 확인
   if(MathAbs(curSL - newSL) < _Point * 0.5) return;

   // StopLevel 클램프가 손절을 뒤로 밀어(= 리스크 확대) 버리는 경우 방지.
   // BE/트레일링 모두 "조이는" 방향으로만 이동해야 한다.
   if(curSL > 0.0)
   {
      if(isBuy  && newSL < curSL) return;
      if(!isBuy && newSL > curSL) return;
   }

   if(!OrderModify(ticket, OrderOpenPrice(), newSL, curTP, 0, clrAqua))
   {
      int err = GetLastError();
      if(err != 1) // 1 = 변경사항 없음
         Print("[StockPro] SL 수정 실패(", tag, ") #", ticket,
               " err=", err, " ", ErrorText(err),
               " newSL=", DoubleToString(newSL, _Digits));
   }
}

//+------------------------------------------------------------------+
//| StopLevel 하한으로 거리 클램프                                     |
//+------------------------------------------------------------------+
double ClampToStopLevel(double dist)
{
   double stopLevel   = MarketInfo(_Symbol, MODE_STOPLEVEL) * _Point;
   double freezeLevel = MarketInfo(_Symbol, MODE_FREEZELEVEL) * _Point;
   double minDist     = MathMax(stopLevel, freezeLevel);
   double spread      = MarketInfo(_Symbol, MODE_SPREAD) * _Point;

   // 최소한 스프레드보다는 넓게
   minDist = MathMax(minDist, spread * 1.5);

   if(dist < minDist) return(minDist);
   return(dist);
}

//+------------------------------------------------------------------+
//| 포지션 추적 레지스트리                                            |
//+------------------------------------------------------------------+
int TrackIndex(int ticket)
{
   for(int i = 0; i < ArraySize(g_track); i++)
      if(g_track[i].ticket == ticket) return(i);
   return(-1);
}

void TrackAdd(int ticket, double rDist, bool partialDone)
{
   if(TrackIndex(ticket) >= 0) return;
   int n = ArraySize(g_track);
   ArrayResize(g_track, n + 1);
   g_track[n].ticket         = ticket;
   g_track[n].rDist          = rDist;
   g_track[n].partialDone    = partialDone;
   g_track[n].partialSkipped = false;
}

// 1R 거리 조회. 미등록이면 현재 SL 거리 -> ATR 순으로 추정 후 등록.
double TrackRDist(int ticket, double openPrice, double curSL)
{
   int idx = TrackIndex(ticket);
   if(idx >= 0 && g_track[idx].rDist > 0.0) return(g_track[idx].rDist);

   // SL이 없는(0) 포지션에서 openPrice와의 차이를 쓰면 값이 터지므로 ATR로 대체
   double r = (curSL > 0.0) ? MathAbs(openPrice - curSL) : 0.0;
   if(r <= 0.0) r = g_rt.atrValue * InpSlAtrMult;
   if(r <= 0.0) return(0.0);

   if(idx >= 0) g_track[idx].rDist = r;
   else         TrackAdd(ticket, r, IsPartialComment(ticket));

   return(r);
}

bool IsPartialComment(int ticket)
{
   // MT4는 부분청산 시 잔여 포지션 코멘트를 "from #원본티켓"으로 바꾼다.
   if(OrderSelect(ticket, SELECT_BY_TICKET))
      if(StringFind(OrderComment(), "from #") >= 0) return(true);
   return(false);
}

// 부분청산이 실제로 체결된 포지션(= 러너). 트레일링 대상 판정에 사용.
bool PartialExecuted(int ticket)
{
   int idx = TrackIndex(ticket);
   if(idx >= 0 && g_track[idx].partialDone) return(true);
   return(IsPartialComment(ticket));
}

// 부분청산을 이미 시도한 포지션(체결 또는 건너뜀). 재시도 방지에 사용.
bool PartialAttempted(int ticket)
{
   int idx = TrackIndex(ticket);
   if(idx >= 0 && (g_track[idx].partialDone || g_track[idx].partialSkipped)) return(true);
   return(IsPartialComment(ticket));
}

void MarkPartialDone(int ticket)
{
   int idx = TrackIndex(ticket);
   if(idx >= 0) { g_track[idx].partialDone = true; return; }
   TrackAdd(ticket, 0.0, true);
}

// 최소랏 제약으로 쪼갤 수 없는 경우: 트레일링 대상으로 승격시키지 않고 고정 TP를 유지한다.
void MarkPartialSkipped(int ticket)
{
   int idx = TrackIndex(ticket);
   if(idx < 0) { TrackAdd(ticket, 0.0, false); idx = TrackIndex(ticket); }
   if(idx >= 0) g_track[idx].partialSkipped = true;
}

//+------------------------------------------------------------------+
//| 부분청산 후 생성된 잔여 티켓을 찾아 승계 등록                       |
//+------------------------------------------------------------------+
void InheritRemainder(int oldTicket, double rDist)
{
   string marker = "from #" + IntegerToString(oldTicket);

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != InpMagicNumber)        continue;
      if(OrderSymbol()      != _Symbol)               continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      if(StringFind(OrderComment(), marker) >= 0)
      {
         int newTicket = OrderTicket();
         TrackAdd(newTicket, rDist, true);

         // 러너의 TP를 제거해야 트레일링이 실제로 상단을 결정할 수 있다.
         // TP를 남겨두면 트레일링이 TP 직전 좁은 구간에서만 동작해 의미가 없어진다.
         if(InpRunnerClearTP) ClearTakeProfit(newTicket);
         return;
      }
   }
}

//+------------------------------------------------------------------+
//| TP 제거 (러너를 트레일링 전용으로 전환)                            |
//+------------------------------------------------------------------+
void ClearTakeProfit(int ticket)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;
   if(OrderTakeProfit() == 0.0) return;   // 이미 없음

   if(!OrderModify(ticket, OrderOpenPrice(), OrderStopLoss(), 0.0, 0, clrAqua))
   {
      int err = GetLastError();
      if(err != 1)
         Print("[StockPro] 러너 TP 제거 실패 #", ticket, " err=", err, " ", ErrorText(err));
   }
   else
      Print("[StockPro] 러너 #", ticket, " TP 제거 -> 트레일링으로 상단 관리");
}

//+------------------------------------------------------------------+
//| 재시작 시 보유 포지션 추적 정보 복구                               |
//+------------------------------------------------------------------+
void RebuildTracking()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != InpMagicNumber)        continue;
      if(OrderSymbol()      != _Symbol)               continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      double r = MathAbs(OrderOpenPrice() - OrderStopLoss());
      if(OrderStopLoss() == 0.0) r = 0.0;

      TrackAdd(OrderTicket(), r, StringFind(OrderComment(), "from #") >= 0);
   }
}

//+------------------------------------------------------------------+
//| 청산된 티켓의 추적 정보 정리                                       |
//+------------------------------------------------------------------+
void PruneTracking()
{
   int n = ArraySize(g_track);
   if(n == 0) return;

   PosTrack keep[];
   ArrayResize(keep, 0);

   for(int i = 0; i < n; i++)
   {
      if(!OrderSelect(g_track[i].ticket, SELECT_BY_TICKET)) continue;
      if(OrderCloseTime() != 0) continue;   // 이미 청산됨

      int k = ArraySize(keep);
      ArrayResize(keep, k + 1);
      keep[k] = g_track[i];
   }

   ArrayResize(g_track, ArraySize(keep));
   for(int i = 0; i < ArraySize(keep); i++) g_track[i] = keep[i];
}

//+------------------------------------------------------------------+
//| 현재 포지션 수                                                    |
//+------------------------------------------------------------------+
int CountPositions()
{
   int cnt = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != InpMagicNumber)        continue;
      if(OrderSymbol()      != _Symbol)               continue;
      if(OrderType() == OP_BUY || OrderType() == OP_SELL) cnt++;
   }
   return(cnt);
}

//+------------------------------------------------------------------+
//| 보유 포지션 스캔 (대시보드용)                                      |
//+------------------------------------------------------------------+
void ScanOpenPositions()
{
   g_rt.buyLots = 0.0;  g_rt.sellLots = 0.0;
   g_rt.buyCount = 0;   g_rt.sellCount = 0;
   g_rt.floatingPL = 0.0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != InpMagicNumber)        continue;
      if(OrderSymbol()      != _Symbol)               continue;

      if(OrderType() == OP_BUY)
      {
         g_rt.buyLots  += OrderLots();
         g_rt.buyCount++;
         g_rt.floatingPL += OrderProfit() + OrderSwap() + OrderCommission();
      }
      else if(OrderType() == OP_SELL)
      {
         g_rt.sellLots += OrderLots();
         g_rt.sellCount++;
         g_rt.floatingPL += OrderProfit() + OrderSwap() + OrderCommission();
      }
   }
}

//+------------------------------------------------------------------+
//| 통계 초기화                                                       |
//+------------------------------------------------------------------+
void ZeroStats()
{
   g_stats.totalTrades  = 0;
   g_stats.wins         = 0;
   g_stats.losses       = 0;
   g_stats.grossProfit  = 0.0;
   g_stats.grossLoss    = 0.0;
   g_stats.netProfit    = 0.0;
   g_stats.winRate      = 0.0;
   g_stats.profitFactor = 0.0;
   g_stats.avgWin       = 0.0;
   g_stats.avgLoss      = 0.0;
   g_stats.expectancyR  = 0.0;
   g_stats.maxDD        = 0.0;
   g_stats.maxDDPct     = 0.0;
   g_stats.todayTrades  = 0;
   g_stats.todayProfit  = 0.0;
   g_stats.consecLosses = 0;
}

//+------------------------------------------------------------------+
//| 거래 이력 스캔 -> 통계 산출 (MDD 포함)                             |
//+------------------------------------------------------------------+
void RefreshStats(bool force)
{
   int histTotal = OrdersHistoryTotal();

   // 이력 변화가 없고 최근에 갱신했으면 스킵
   if(!force && histTotal == g_lastHistoryTotal &&
      TimeCurrent() - g_lastStatsRefresh < 2)
      return;

   g_lastHistoryTotal = histTotal;
   g_lastStatsRefresh = TimeCurrent();

   ZeroStats();

   datetime times[];
   double   profits[];
   int      n = 0;

   ArrayResize(times,   histTotal);
   ArrayResize(profits, histTotal);

   datetime dayStart = DayStart(TimeCurrent());

   for(int i = 0; i < histTotal; i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderMagicNumber() != InpMagicNumber)         continue;
      if(OrderSymbol()      != _Symbol)                continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      double pl = OrderProfit() + OrderSwap() + OrderCommission();

      times[n]   = OrderCloseTime();
      profits[n] = pl;
      n++;

      if(OrderCloseTime() >= dayStart)
      {
         g_stats.todayTrades++;
         g_stats.todayProfit += pl;
      }
   }

   ArrayResize(times,   n);
   ArrayResize(profits, n);

   if(n == 0) return;

   // 청산 시각 순 정렬 (MDD는 순서에 의존)
   SortByTime(times, profits, 0, n - 1);

   double   runningBalance = 0.0;
   double   peak           = 0.0;
   int      consec         = 0;
   datetime lastCloseTime  = 0;

   for(int i = 0; i < n; i++)
   {
      double pl = profits[i];
      lastCloseTime = times[i];

      g_stats.totalTrades++;
      g_stats.netProfit += pl;

      if(pl > 0.0)
      {
         g_stats.wins++;
         g_stats.grossProfit += pl;
         consec = 0;
      }
      else if(pl < 0.0)
      {
         g_stats.losses++;
         g_stats.grossLoss += MathAbs(pl);
         consec++;
      }

      runningBalance += pl;
      if(runningBalance > peak) peak = runningBalance;

      double dd = peak - runningBalance;
      if(dd > g_stats.maxDD) g_stats.maxDD = dd;
   }

   g_stats.consecLosses = consec;

   if(g_stats.totalTrades > 0)
      g_stats.winRate = (g_stats.wins * 100.0) / g_stats.totalTrades;

   if(g_stats.grossLoss > 0.0)
      g_stats.profitFactor = g_stats.grossProfit / g_stats.grossLoss;
   else if(g_stats.grossProfit > 0.0)
      g_stats.profitFactor = 999.0;

   if(g_stats.wins > 0)   g_stats.avgWin  = g_stats.grossProfit / g_stats.wins;
   if(g_stats.losses > 0) g_stats.avgLoss = g_stats.grossLoss / g_stats.losses;

   // 기댓값(R) 근사: 평균손실을 1R로 간주
   if(g_stats.avgLoss > 0.0 && g_stats.totalTrades > 0)
      g_stats.expectancyR = (g_stats.netProfit / g_stats.totalTrades) / g_stats.avgLoss;

   double baseBalance = AccountBalance() - g_stats.netProfit;
   if(baseBalance > 0.0)
      g_stats.maxDDPct = (g_stats.maxDD / baseBalance) * 100.0;

   // 연속 손절 서킷브레이커
   // 같은 손절 건으로 쿨다운이 무한 재발동되지 않도록, 발동을 유발한 청산시각을 기록해
   // 그보다 새로운 손절이 발생했을 때만 다시 발동시킨다.
   if(InpMaxConsecLoss > 0 && InpCooldownMin > 0 &&
      consec >= InpMaxConsecLoss && lastCloseTime > g_lastCooldownTrig)
   {
      g_lastCooldownTrig = lastCloseTime;
      g_cooldownUntil    = TimeCurrent() + InpCooldownMin * 60;
      Print("[StockPro] 연속 손절 ", consec, "회 -> ", InpCooldownMin, "분 쿨다운 진입");
   }
}

//+------------------------------------------------------------------+
//| 시각 기준 정렬 (퀵소트, 두 배열 동기화)                            |
//+------------------------------------------------------------------+
void SortByTime(datetime &t[], double &p[], int lo, int hi)
{
   if(lo >= hi) return;

   int i = lo, j = hi;
   datetime pivot = t[(lo + hi) / 2];

   while(i <= j)
   {
      while(t[i] < pivot) i++;
      while(t[j] > pivot) j--;
      if(i <= j)
      {
         datetime tt = t[i]; t[i] = t[j]; t[j] = tt;
         double   tp = p[i]; p[i] = p[j]; p[j] = tp;
         i++; j--;
      }
   }
   if(lo < j) SortByTime(t, p, lo, j);
   if(i < hi) SortByTime(t, p, i, hi);
}

//+------------------------------------------------------------------+
//| 당일 0시 (서버시간)                                               |
//+------------------------------------------------------------------+
datetime DayStart(datetime t)
{
   return(t - (t % 86400));
}

//+------------------------------------------------------------------+
//|                        대시보드 (GUI)                             |
//+------------------------------------------------------------------+

// 반투명 근사: MT4는 오브젝트 알파를 지원하지 않으므로
// 패널색을 차트 배경색 쪽으로 블렌딩해 투명도를 시뮬레이션한다.
color BlendColor(color fg, color bg, double alpha)
{
   if(alpha >= 1.0) return(fg);
   if(alpha <= 0.0) return(bg);

   // MT4 color 는 0x00BBGGRR 포맷
   int f = (int)fg;
   int b0= (int)bg;

   int fr = ( f        & 0xFF);
   int fgr= (( f >>  8) & 0xFF);
   int fb = (( f >> 16) & 0xFF);

   int br = ( b0        & 0xFF);
   int bgr= ((b0 >>  8) & 0xFF);
   int bb = ((b0 >> 16) & 0xFF);

   int r = (int)MathRound(fr  * alpha + br  * (1.0 - alpha));
   int g = (int)MathRound(fgr * alpha + bgr * (1.0 - alpha));
   int b = (int)MathRound(fb  * alpha + bb  * (1.0 - alpha));

   r = (int)MathMax(0, MathMin(255, r));
   g = (int)MathMax(0, MathMin(255, g));
   b = (int)MathMax(0, MathMin(255, b));

   return((color)(r | (g << 8) | (b << 16)));
}

bool DashRightCorner()
{
   return(InpDashCorner == CORNER_RIGHT_UPPER || InpDashCorner == CORNER_RIGHT_LOWER);
}

bool DashLowerCorner()
{
   return(InpDashCorner == CORNER_LEFT_LOWER || InpDashCorner == CORNER_RIGHT_LOWER);
}

// 패널 좌상단 기준 (dx, dy) -> 실제 코너 기준 좌표
int DashX(int dx)
{
   if(DashRightCorner()) return(InpDashX + InpDashWidth - dx);
   return(InpDashX + dx);
}

int DashY(int dy)
{
   if(DashLowerCorner()) return(InpDashY + g_panelHeight - dy);
   return(InpDashY + dy);
}

//+------------------------------------------------------------------+
//| 사각형(배경/구분선) 생성                                          |
//+------------------------------------------------------------------+
void DashRect(string id, int dx, int dy, int w, int h, color bg)
{
   string name = g_prefix + id;
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
      ObjectSetInteger(0, name, OBJPROP_BACK,       false);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
   }
   ObjectSetInteger(0, name, OBJPROP_CORNER,    InpDashCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, DashRightCorner() ? (InpDashX + InpDashWidth - dx - w) : (InpDashX + dx));
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, DashLowerCorner() ? (InpDashY + g_panelHeight - dy - h) : (InpDashY + dy));
   ObjectSetInteger(0, name, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,     h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,   bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR,     bg);
}

//+------------------------------------------------------------------+
//| 텍스트 라벨 생성/갱신                                             |
//+------------------------------------------------------------------+
void DashText(string id, int dx, int dy, string text, color clr,
              int fontSize, bool rightAlign, bool bold)
{
   string name = g_prefix + id;
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
      ObjectSetInteger(0, name, OBJPROP_BACK,       false);
   }

   ENUM_ANCHOR_POINT anchor = rightAlign ? ANCHOR_RIGHT_UPPER : ANCHOR_LEFT_UPPER;

   ObjectSetInteger(0, name, OBJPROP_CORNER,    InpDashCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, DashX(dx));
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, DashY(dy));
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,    anchor);
   ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  fontSize);
   ObjectSetString (0, name, OBJPROP_FONT,      bold ? (InpDashFont + " Bold") : InpDashFont);
   ObjectSetString (0, name, OBJPROP_TEXT,      text);
}

//+------------------------------------------------------------------+
//| 접기/펼치기 버튼                                                  |
//+------------------------------------------------------------------+
void DashButton()
{
   string name = g_prefix + "BTN";
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   }
   int w = 22, h = 16;
   ObjectSetInteger(0, name, OBJPROP_CORNER,    InpDashCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, DashRightCorner() ? (InpDashX + 8) : (InpDashX + InpDashWidth - w - 8));
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, DashLowerCorner() ? (InpDashY + g_panelHeight - 6 - h) : (InpDashY + 6));
   ObjectSetInteger(0, name, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,     h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,   BlendColor(InpDashAccent, InpDashPanelColor, 0.35));
   ObjectSetInteger(0, name, OBJPROP_COLOR,     InpDashTextColor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  7);
   ObjectSetString (0, name, OBJPROP_FONT,      "Tahoma");
   ObjectSetString (0, name, OBJPROP_TEXT,      g_dashCollapsed ? "▼" : "▲");
   ObjectSetInteger(0, name, OBJPROP_STATE,     false);
}

//+------------------------------------------------------------------+
//| 차트 클릭 이벤트 (대시보드 접기/펼치기)                            |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == g_prefix + "BTN")
   {
      g_dashCollapsed = !g_dashCollapsed;
      DeleteDashboard();
      BuildDashboard();
      UpdateDashboard();
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
//| 대시보드 골격 생성                                                |
//+------------------------------------------------------------------+
void BuildDashboard()
{
   UpdateDashboard();
}

//+------------------------------------------------------------------+
//| 대시보드 삭제                                                     |
//+------------------------------------------------------------------+
void DeleteDashboard()
{
   ObjectsDeleteAll(0, g_prefix);
}

//+------------------------------------------------------------------+
//| 레이아웃 상수                                                     |
//+------------------------------------------------------------------+
#define DASH_PAD_X     12
#define DASH_ROW_H     16
#define DASH_SEC_GAP   7
#define DASH_HEADER_H  30

//+------------------------------------------------------------------+
//| 대시보드 갱신 (메인 렌더러)                                        |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!InpShowDash) return;

   color chartBg = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
   double alpha  = InpDashOpacity / 100.0;
   color panelBg = BlendColor(InpDashPanelColor, chartBg, alpha);
   color secBg   = BlendColor(InpDashAccent, InpDashPanelColor, 0.14);
   secBg         = BlendColor(secBg, chartBg, alpha);

   int y = DASH_HEADER_H;

   // --- 높이 사전 계산 (섹션 5개 / 데이터 행 23개) ---
   if(g_dashCollapsed)
      g_panelHeight = DASH_HEADER_H + 6;
   else
      g_panelHeight = DASH_HEADER_H
                    + (5 * (DASH_ROW_H + 2))          // 섹션 헤더 5개
                    + (23 * DASH_ROW_H)               // 데이터 행 23개
                    + (5 * DASH_SEC_GAP) + 12;        // 섹션 간격 + 하단 여백

   // --- 패널 배경 ---
   DashRect("BG", 0, 0, InpDashWidth, g_panelHeight, panelBg);

   // --- 헤더 ---
   DashRect("HDR", 0, 0, InpDashWidth, DASH_HEADER_H,
            BlendColor(InpDashAccent, InpDashPanelColor, 0.30));

   string tfName = TFName(EntryTF());
   DashText("TITLE", DASH_PAD_X, 8, "StockPro Scalper",
            InpDashTextColor, InpDashFontSize + 1, false, true);
   DashText("SYMBOL", InpDashWidth - DASH_PAD_X - 26, 9,
            _Symbol + " · " + tfName, InpDashTextColor, InpDashFontSize - 1, true, false);

   DashButton();

   if(g_dashCollapsed) { ChartRedraw(); return; }

   // ================= 계좌 =================
   y += DASH_SEC_GAP;
   y = Section("S1", y, "계좌", secBg);

   double bal    = AccountBalance();
   double eq     = AccountEquity();
   double marUsed= AccountMargin();
   double marPct = (eq > 0.0) ? (marUsed / eq * 100.0) : 0.0;

   y = Row("R1", y, "잔고",        FormatNum(bal, 2), InpDashTextColor);
   y = Row("R2", y, "순자산",      FormatNum(eq, 2),
           eq >= bal ? InpDashProfitClr : InpDashLossClr);
   y = Row("R3", y, "증거금 사용률", FormatNum(marPct, 1) + " %",
           marPct > 30.0 ? InpDashWarnClr : InpDashDimColor);

   // ================= 오늘 =================
   y += DASH_SEC_GAP;
   y = Section("S2", y, "오늘", secBg);

   double todayPct = (bal != 0.0) ? (g_stats.todayProfit / bal * 100.0) : 0.0;
   y = Row("R4", y, "거래 횟수", IntegerToString(g_stats.todayTrades) + " 회", InpDashTextColor);
   y = Row("R5", y, "실현 손익",
           FormatSigned(g_stats.todayProfit, 2) + "  (" + FormatSigned(todayPct, 2) + "%)",
           PLColor(g_stats.todayProfit));

   string limitTxt;
   color  limitClr;
   if(InpDailyLossPct > 0.0)
   {
      double remain = InpDailyLossPct + todayPct;   // todayPct가 음수일 때 남은 여유
      if(remain < 0.0)              remain = 0.0;
      if(remain > InpDailyLossPct)  remain = InpDailyLossPct;  // 수익 중일 때 표시 정규화
      limitTxt = FormatNum(remain, 2) + "% 남음  / -" + FormatNum(InpDailyLossPct, 1) + "%";
      limitClr = (remain < InpDailyLossPct * 0.3) ? InpDashWarnClr : InpDashDimColor;
   }
   else { limitTxt = "미사용"; limitClr = InpDashDimColor; }
   y = Row("R6", y, "일일 손실한도", limitTxt, limitClr);

   // ================= 포지션 =================
   y += DASH_SEC_GAP;
   y = Section("S3", y, "현재 포지션", secBg);

   y = Row("R7", y, "매수",
           FormatNum(g_rt.buyLots, 2) + " 랏  (" + IntegerToString(g_rt.buyCount) + ")",
           g_rt.buyCount > 0 ? InpDashProfitClr : InpDashDimColor);
   y = Row("R8", y, "매도",
           FormatNum(g_rt.sellLots, 2) + " 랏  (" + IntegerToString(g_rt.sellCount) + ")",
           g_rt.sellCount > 0 ? InpDashLossClr : InpDashDimColor);
   y = Row("R9", y, "순노출",
           FormatSigned(g_rt.buyLots - g_rt.sellLots, 2) + " 랏", InpDashTextColor);
   y = Row("R10", y, "평가 손익",
           FormatSigned(g_rt.floatingPL, 2), PLColor(g_rt.floatingPL));

   // ================= 성과 =================
   y += DASH_SEC_GAP;
   y = Section("S4", y, "누적 성과", secBg);

   y = Row("R11", y, "총 거래", IntegerToString(g_stats.totalTrades) + " 회", InpDashTextColor);
   y = Row("R12", y, "승 / 패",
           IntegerToString(g_stats.wins) + " / " + IntegerToString(g_stats.losses),
           InpDashTextColor);
   y = Row("R13", y, "승률", FormatNum(g_stats.winRate, 1) + " %",
           g_stats.winRate >= 50.0 ? InpDashProfitClr : InpDashWarnClr);
   y = Row("R14", y, "누적 손익", FormatSigned(g_stats.netProfit, 2), PLColor(g_stats.netProfit));
   y = Row("R15", y, "Profit Factor",
           g_stats.profitFactor >= 999.0 ? "∞" : FormatNum(g_stats.profitFactor, 2),
           g_stats.profitFactor >= 1.0 ? InpDashProfitClr : InpDashLossClr);
   y = Row("R16", y, "기댓값 (R)", FormatSigned(g_stats.expectancyR, 3) + " R",
           PLColor(g_stats.expectancyR));
   y = Row("R17", y, "MDD",
           "-" + FormatNum(g_stats.maxDD, 2) + "  (" + FormatNum(g_stats.maxDDPct, 2) + "%)",
           g_stats.maxDD > 0.0 ? InpDashLossClr : InpDashDimColor);

   // ================= 신호 / 상태 =================
   y += DASH_SEC_GAP;
   y = Section("S5", y, "신호 · 상태", secBg);

   string trendTxt;
   color  trendClr;
   if(g_rt.trendDir > 0)      { trendTxt = "▲ 상승"; trendClr = InpDashProfitClr; }
   else if(g_rt.trendDir < 0) { trendTxt = "▼ 하락"; trendClr = InpDashLossClr; }
   else                       { trendTxt = "— 없음"; trendClr = InpDashDimColor; }

   if(InpUseAdx)
   {
      trendTxt += "  ADX " + FormatNum(g_rt.adxValue, 1);
      // ADX가 임계값 미만이면 방향이 있어도 진입하지 않으므로 흐리게 표시
      if(g_rt.adxWeak) { trendTxt += " ↓"; trendClr = InpDashDimColor; }
   }

   y = Row("R18", y, "추세 (" + TFName(InpTrendTF) + ")", trendTxt, trendClr);
   y = Row("R19", y, InpOscType == OSC_RSI ? "RSI" : "Stoch %K",
           FormatNum(g_rt.oscValue, 1), InpDashTextColor);
   y = Row("R20", y, "스프레드",
           IntegerToString(g_rt.spreadPts) + " pt  " + (g_rt.spreadOk ? "✓" : "✕"),
           g_rt.spreadOk ? InpDashDimColor : InpDashWarnClr);
   y = Row("R21", y, "청산 모드",
           ExitModeName(InpExitMode) + (g_rt.partialFallback ? " (폴백)" : ""),
           InpDashDimColor);
   y = Row("R22", y, "연속 손절",
           IntegerToString(g_stats.consecLosses) + " / " +
           (InpMaxConsecLoss > 0 ? IntegerToString(InpMaxConsecLoss) : "∞"),
           g_stats.consecLosses > 0 ? InpDashWarnClr : InpDashDimColor);

   // EA 상태 배지
   string statusTxt; color statusClr;
   GetStatus(statusTxt, statusClr);
   y = Row("R23", y, "상태", statusTxt, statusClr);

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| 섹션 헤더 렌더                                                    |
//+------------------------------------------------------------------+
int Section(string id, int y, string title, color bg)
{
   DashRect(id + "_BG", 0, y, InpDashWidth, DASH_ROW_H + 2, bg);
   DashText(id + "_T", DASH_PAD_X, y + 2, title, InpDashAccent, InpDashFontSize, false, true);
   return(y + DASH_ROW_H + 2);
}

//+------------------------------------------------------------------+
//| 데이터 행 렌더 (라벨 좌측 / 값 우측 정렬)                           |
//+------------------------------------------------------------------+
int Row(string id, int y, string label, string value, color valColor)
{
   DashText(id + "_L", DASH_PAD_X, y + 1, label, InpDashDimColor, InpDashFontSize, false, false);
   DashText(id + "_V", InpDashWidth - DASH_PAD_X, y + 1, value, valColor, InpDashFontSize, true, false);
   return(y + DASH_ROW_H);
}

//+------------------------------------------------------------------+
//| EA 현재 상태 판정                                                 |
//+------------------------------------------------------------------+
void GetStatus(string &txt, color &clr)
{
   if(!InpEnableTrading)      { txt = "진입 비활성";       clr = InpDashDimColor;  return; }
   if(g_rt.cooldownActive)
   {
      int mins = (int)((g_cooldownUntil - TimeCurrent()) / 60) + 1;
      txt = "쿨다운 " + IntegerToString(mins) + "분";  clr = InpDashWarnClr;  return;
   }
   if(g_rt.dailyLimitHit)     { txt = "일일 한도 도달";    clr = InpDashLossClr;   return; }
   if(!g_rt.sessionOk)        { txt = "세션 시간 외";      clr = InpDashDimColor;  return; }
   if(!g_rt.spreadOk)         { txt = "스프레드 대기";     clr = InpDashWarnClr;   return; }
   if(g_rt.blockReason != "") { txt = g_rt.blockReason;    clr = InpDashDimColor;  return; }

   txt = "● 정상 가동";
   clr = InpDashProfitClr;
}

//+------------------------------------------------------------------+
//| 포맷 유틸                                                         |
//+------------------------------------------------------------------+
color PLColor(double v)
{
   if(v > 0.0) return(InpDashProfitClr);
   if(v < 0.0) return(InpDashLossClr);
   return(InpDashDimColor);
}

// 천단위 구분 기호 삽입
string FormatNum(double v, int digits)
{
   string s = DoubleToString(v, digits);

   bool neg = false;
   if(StringGetChar(s, 0) == '-') { neg = true; s = StringSubstr(s, 1); }

   int dot = StringFind(s, ".");
   string intPart = (dot >= 0) ? StringSubstr(s, 0, dot) : s;
   string decPart = (dot >= 0) ? StringSubstr(s, dot)    : "";

   string res = "";
   int len = StringLen(intPart);
   for(int i = 0; i < len; i++)
   {
      if(i > 0 && (len - i) % 3 == 0) res += ",";
      res += StringSubstr(intPart, i, 1);
   }

   return((neg ? "-" : "") + res + decPart);
}

// 부호를 항상 표기
string FormatSigned(double v, int digits)
{
   string s = FormatNum(MathAbs(v), digits);
   if(v > 0.0) return("+" + s);
   if(v < 0.0) return("-" + s);
   return(s);
}

string ExitModeName(ENUM_EXIT_MODE m)
{
   if(m == EXIT_FIXED_TP)       return("고정 TP");
   if(m == EXIT_TRAILING)       return("트레일링");
   return("부분청산+러너");
}

string TFName(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return("M1");
      case PERIOD_M5:  return("M5");
      case PERIOD_M15: return("M15");
      case PERIOD_M30: return("M30");
      case PERIOD_H1:  return("H1");
      case PERIOD_H4:  return("H4");
      case PERIOD_D1:  return("D1");
      case PERIOD_W1:  return("W1");
      case PERIOD_MN1: return("MN1");
   }
   return("TF" + IntegerToString((int)tf));
}

//+------------------------------------------------------------------+
//| 에러 코드 -> 설명                                                 |
//+------------------------------------------------------------------+
string ErrorText(int code)
{
   switch(code)
   {
      case 1:   return("변경사항 없음");
      case 2:   return("일반 오류");
      case 3:   return("잘못된 파라미터");
      case 4:   return("서버 사용중");
      case 6:   return("접속 없음");
      case 8:   return("요청이 너무 잦음");
      case 129: return("잘못된 가격");
      case 130: return("잘못된 스탑 (StopLevel 위반)");
      case 131: return("잘못된 거래량");
      case 132: return("시장 폐장");
      case 133: return("거래 금지됨");
      case 134: return("증거금 부족");
      case 135: return("가격 변동됨");
      case 136: return("호가 없음");
      case 138: return("리쿼트");
      case 141: return("요청 과다");
      case 145: return("시장가 근접으로 수정 거부");
      case 146: return("거래 서브시스템 사용중");
      case 148: return("주문 수 한도 초과");
   }
   return("코드 " + IntegerToString(code));
}
//+------------------------------------------------------------------+
