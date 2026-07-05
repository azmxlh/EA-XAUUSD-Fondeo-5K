#property strict
#include <Trade\Trade.mqh>

// ================== GLOBAL VARIABLES ==================
CTrade trade;

// RISK MANAGEMENT
double CurrentLot = 0.01;
double DailyProfit = 0;
double DailyLoss = 0;
double AccumulatedLoss = 0;
double InitialBalance = 5000;

const double DAILY_TP = 500;
const double DAILY_SL = 100;
const double ACCUMULATED_RISK = 500;
const int MIN_DURATION_MINUTES = 5;

// INDICATORS AND PARAMETERS
const int RSI_PERIOD = 14;
const int ATR_PERIOD = 14;
const int BB_PERIOD = 20;
const double BB_DEVIATION = 2.0;
const int MACD_FAST = 12;
const int MACD_SLOW = 26;
const int MACD_SIGNAL = 9;

// INSTITUTIONAL LEVELS
double MainResistance = 0;
double MainSupport = 0;
double AccumulationZone = 0;
double DistributionZone = 0;

// SESSION CONTROL
int PreviousDay = -1;
bool PausedToday = false;

// STATISTICS
struct TradeStats {
    int totalTrades;
    int winningTrades;
    int losingTrades;
    double winRate;
};

TradeStats stats = {0, 0, 0, 0};

//+------------------------------------------------------------------+
//| INIT                                                             |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("╔════════════════════════════════════╗");
    Print("║  EA XAUUSD FUNDING $5K (Wall St)  ║");
    Print("║  Timeframe: M5 (5 minutes)        ║");
    Print("║  Capital: $5,000                  ║");
    Print("║  Strategy: Smart Money + Confluence ║");
    Print("╚════════════════════════════════════╝");
    
    InitialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    CalculateInstitutionalLevels();
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| TICK - HEART OF THE EA                                           |
//+------------------------------------------------------------------+
void OnTick()
{
    // RESET BY DAY - FIX: Use TimeCurrent() instead of Day()
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    if (PreviousDay != dt.day)
    {
        DailyProfit = 0;
        DailyLoss = 0;
        PausedToday = false;
        PreviousDay = dt.day;
        
        Print("═══════ NEW DAY - Balance: $", AccountInfoDouble(ACCOUNT_BALANCE), " ═══════");
        CalculateInstitutionalLevels();
    }
    
    // 1. VERIFY CRITICAL LIMITS
    if (!VerifyCriticalLimits()) return;
    
    // 2. RECALCULATE LEVELS DYNAMICALLY
    CalculateInstitutionalLevels();
    
    // 3. MANAGE OPEN TRADES
    ManageOpenTrades();
    
    // 4. CHECK ENTRY OPPORTUNITIES
    if (IsOperationHours24x7())
    {
        CheckEntrySignals();
    }
    
    // 5. SHOW DASHBOARD
    ShowDashboard();
}

//+------------------------------------------------------------------+
//| 🎯 CALCULATION OF INSTITUTIONAL LEVELS (Smart Money)              |
//+------------------------------------------------------------------+
void CalculateInstitutionalLevels()
{
    // Data from last HIGH-LOW (volatility)
    double High24 = iHigh(_Symbol, PERIOD_D1, 0);
    double Low24 = iLow(_Symbol, PERIOD_D1, 0);
    double Close = iClose(_Symbol, PERIOD_M5, 0);
    
    // VOLATILITY RANGE
    double VolatilityRange = High24 - Low24;
    
    // PIVOT POINT (Central trading point)
    double PP = (High24 + Low24 + Close) / 3;
    
    // DAILY RESISTANCE AND SUPPORT
    MainResistance = PP + (VolatilityRange * 0.618);
    MainSupport = PP - (VolatilityRange * 0.618);
    
    // ACCUMULATION ZONE (where institutions buy)
    AccumulationZone = MainSupport - (VolatilityRange * 0.382);
    
    // DISTRIBUTION ZONE (where institutions sell)
    DistributionZone = MainResistance + (VolatilityRange * 0.382);
}

//+------------------------------------------------------------------+
//| ✅ CHECK ENTRY SIGNALS (CONFLUENCE)                             |
//+------------------------------------------------------------------+
void CheckEntrySignals()
{
    // DO NOT OPERATE if there are many open trades
    if (CountOpenTrades() >= 3) return;
    
    double Close = iClose(_Symbol, PERIOD_M5, 0);
    double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // ========== INDICATOR 1: RSI ==========
    double RSI = iRSI(_Symbol, PERIOD_M5, RSI_PERIOD, PRICE_CLOSE);
    bool RSI_Oversold = RSI < 30;
    bool RSI_Overbought = RSI > 70;
    
    // ========== INDICATOR 2: MACD (CORRECTED) ==========
    int macdHandle = iMACD(_Symbol, PERIOD_M5, MACD_FAST, MACD_SLOW, MACD_SIGNAL, PRICE_CLOSE);
    double macdLine[], macdSignal[];
    ArraySetAsSeries(macdLine, true);
    ArraySetAsSeries(macdSignal, true);
    
    CopyBuffer(macdHandle, 0, 0, 1, macdLine);
    CopyBuffer(macdHandle, 1, 0, 1, macdSignal);
    
    double MACD = (ArraySize(macdLine) > 0) ? macdLine[0] : 0;
    double MACD_Signal = (ArraySize(macdSignal) > 0) ? macdSignal[0] : 0;
    bool MACD_BullishCrossover = MACD > MACD_Signal;
    bool MACD_BearishCrossover = MACD < MACD_Signal;
    
    // ========== INDICATOR 3: BOLLINGER BANDS (CORRECTED) ==========
    // FIX: iBands correct syntax: iBands(symbol, period, shift, deviation, applied_price)
    int bandHandle = iBands(_Symbol, PERIOD_M5, BB_PERIOD, 0, BB_DEVIATION, PRICE_CLOSE);
    double bbUpper[], bbLower[], bbMiddle[];
    
    ArraySetAsSeries(bbUpper, true);
    ArraySetAsSeries(bbLower, true);
    ArraySetAsSeries(bbMiddle, true);
    
    CopyBuffer(bandHandle, 1, 0, 1, bbUpper);
    CopyBuffer(bandHandle, 2, 0, 1, bbLower);
    CopyBuffer(bandHandle, 0, 0, 1, bbMiddle);
    
    double BB_Upper = (ArraySize(bbUpper) > 0) ? bbUpper[0] : Ask + 100 * _Point;
    double BB_Lower = (ArraySize(bbLower) > 0) ? bbLower[0] : Ask - 100 * _Point;
    double BB_Middle = (ArraySize(bbMiddle) > 0) ? bbMiddle[0] : Close;
    
    bool Price_NearBBLower = Close < BB_Middle && Close > BB_Lower;
    bool Price_NearBBUpper = Close > BB_Middle && Close < BB_Upper;
    
    // ========== INDICATOR 4: ATR (Volatility) ==========
    double ATR = iATR(_Symbol, PERIOD_M5, ATR_PERIOD);
    bool OptimalVolatility = ATR > 0.5 && ATR < 3.0;
    
    // ========== INDICATOR 5: SMART MONEY LEVELS ==========
    double Price = Close;
    double VolatilityRange = iHigh(_Symbol, PERIOD_D1, 0) - iLow(_Symbol, PERIOD_D1, 0);
    bool In_AccumulationZone = Price >= AccumulationZone && Price <= MainSupport;
    bool In_DistributionZone = Price >= MainResistance && Price <= DistributionZone;
    bool Support_Bounce = Price >= MainSupport && Price <= MainSupport + (VolatilityRange * 0.05);
    bool Resistance_Bounce = Price >= MainResistance - (VolatilityRange * 0.05) && Price <= MainResistance;
    
    // ========== SIGNAL BUY: CONFLUENCE ==========
    int ConfluenceBuy = 0;
    if (RSI_Oversold) ConfluenceBuy++;
    if (MACD_BullishCrossover) ConfluenceBuy++;
    if (Price_NearBBLower) ConfluenceBuy++;
    if (OptimalVolatility) ConfluenceBuy++;
    if (In_AccumulationZone || Support_Bounce) ConfluenceBuy++;
    
    if (ConfluenceBuy >= 3)
    {
        OpenBuy(Ask, ConfluenceBuy);
    }
    
    // ========== SIGNAL SELL: CONFLUENCE ==========
    int ConfluenceSell = 0;
    if (RSI_Overbought) ConfluenceSell++;
    if (MACD_BearishCrossover) ConfluenceSell++;
    if (Price_NearBBUpper) ConfluenceSell++;
    if (OptimalVolatility) ConfluenceSell++;
    if (In_DistributionZone || Resistance_Bounce) ConfluenceSell++;
    
    if (ConfluenceSell >= 3)
    {
        OpenSell(Bid, ConfluenceSell);
    }
}

//+------------------------------------------------------------------+
//| 📈 OPEN BUY WITH ADVANCED LOGIC                                  |
//+------------------------------------------------------------------+
void OpenBuy(double Ask, int ConfluenceLevel)
{
    double SL = Ask - 40 * _Point;
    double TP = Ask + (100 + (ConfluenceLevel * 20)) * _Point;
    
    string Reason = "BUY | Confluence: " + (string)ConfluenceLevel + "/5";
    
    if (trade.Buy(CurrentLot, _Symbol, Ask, SL, TP, Reason))
    {
        Print("✅ BUY OPENED | Ask: ", Ask, " | SL: ", SL, " | TP: ", TP, " | Reason: ", Reason);
        stats.totalTrades++;
    }
}

//+------------------------------------------------------------------+
//| 📉 OPEN SELL WITH ADVANCED LOGIC                                 |
//+------------------------------------------------------------------+
void OpenSell(double Bid, int ConfluenceLevel)
{
    double SL = Bid + 40 * _Point;
    double TP = Bid - (100 + (ConfluenceLevel * 20)) * _Point;
    
    string Reason = "SELL | Confluence: " + (string)ConfluenceLevel + "/5";
    
    if (trade.Sell(CurrentLot, _Symbol, Bid, SL, TP, Reason))
    {
        Print("✅ SELL OPENED | Bid: ", Bid, " | SL: ", SL, " | TP: ", TP, " | Reason: ", Reason);
        stats.totalTrades++;
    }
}

//+------------------------------------------------------------------+
//| 💰 MANAGE OPEN TRADES                                            |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionSelectByTicket(PositionGetTicket(i)))
        {
            if (PositionGetSymbol(i) == _Symbol)
            {
                ulong ticket = PositionGetTicket(i);
                long timeEntry = PositionGetInteger(POSITION_TIME);
                long minutesOpen = (TimeCurrent() - timeEntry) / 60;
                
                double EntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double Profit = PositionGetDouble(POSITION_PROFIT);
                int Type = PositionGetInteger(POSITION_TYPE);
                
                double CurrentPrice = (Type == POSITION_TYPE_BUY) 
                    ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                    : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                
                // ========== DYNAMIC BREAK EVEN ==========
                if ((Type == POSITION_TYPE_BUY && CurrentPrice > EntryPrice + 50 * _Point) ||
                    (Type == POSITION_TYPE_SELL && CurrentPrice < EntryPrice - 50 * _Point))
                {
                    double NewSL = EntryPrice;
                    if (PositionGetDouble(POSITION_SL) != NewSL)
                    {
                        trade.PositionModify(ticket, NewSL, PositionGetDouble(POSITION_TP));
                        Print("✅ BREAK EVEN activated | Ticket: ", ticket);
                    }
                }
                
                // ========== TRAILING STOP ==========
                if ((Type == POSITION_TYPE_BUY && CurrentPrice > EntryPrice + 100 * _Point) ||
                    (Type == POSITION_TYPE_SELL && CurrentPrice < EntryPrice - 100 * _Point))
                {
                    double TrailingSL = (Type == POSITION_TYPE_BUY) 
                        ? CurrentPrice - 50 * _Point
                        : CurrentPrice + 50 * _Point;
                    
                    if ((Type == POSITION_TYPE_BUY && TrailingSL > PositionGetDouble(POSITION_SL)) ||
                        (Type == POSITION_TYPE_SELL && TrailingSL < PositionGetDouble(POSITION_SL)))
                    {
                        trade.PositionModify(ticket, TrailingSL, PositionGetDouble(POSITION_TP));
                    }
                }
                
                // ========== SCALED RE-ENTRY ==========
                if (minutesOpen >= MIN_DURATION_MINUTES && Profit > 50)
                {
                    if (CountOpenTrades() < 3)
                    {
                        double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                        double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                        
                        if (Type == POSITION_TYPE_BUY)
                        {
                            OpenBuy(Ask, 3);
                        }
                        else
                        {
                            OpenSell(Bid, 3);
                        }
                    }
                }
                
                // ========== STATISTICS LOGGING ==========
                if (Profit > 0)
                    stats.winningTrades++;
                else
                    stats.losingTrades++;
            }
        }
    }
    
    // Calculate Win Rate
    if (stats.totalTrades > 0)
        stats.winRate = (stats.winningTrades / (double)stats.totalTrades) * 100;
}

//+------------------------------------------------------------------+
//| ⚠️ VERIFY CRITICAL LIMITS                                        |
//+------------------------------------------------------------------+
bool VerifyCriticalLimits()
{
    // 1. ACCUMULATED LOSS
    if (AccumulatedLoss >= ACCUMULATED_RISK)
    {
        CloseAll();
        Alert("⛔ FUNDED ACCOUNT LOST");
        ExpertRemove();
        return false;
    }
    
    // 2. DAILY LOSS
    if (DailyLoss <= -DAILY_SL)
    {
        if (!PausedToday)
        {
            CloseAll();
            PausedToday = true;
            Alert("⚠️ DAILY LIMIT REACHED: -$", DAILY_SL);
        }
        return false;
    }
    
    // 3. DAILY PROFIT
    if (DailyProfit >= DAILY_TP)
    {
        CloseAll();
        Alert("✅ DAILY TARGET REACHED: +$", DAILY_TP);
        PausedToday = true;
        return false;
    }
    
    UpdatePyL();
    return true;
}

//+------------------------------------------------------------------+
//| 🕐 OPERATION HOURS 24/7                                          |
//+------------------------------------------------------------------+
bool IsOperationHours24x7()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int hour = dt.hour;
    
    // Asia: 20:00-04:00 GMT
    if (hour >= 20 || hour < 4) return true;
    
    // London: 08:00-17:00 GMT
    if (hour >= 8 && hour < 17) return true;
    
    // NY: 13:00-21:00 GMT
    if (hour >= 13 && hour < 21) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| 🎲 HELPER FUNCTIONS                                              |
//+------------------------------------------------------------------+

int CountOpenTrades()
{
    int counter = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionSelectByTicket(PositionGetTicket(i)))
        {
            if (PositionGetSymbol(i) == _Symbol)
                counter++;
        }
    }
    return counter;
}

void UpdatePyL()
{
    double CurrentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    DailyProfit = CurrentBalance - InitialBalance;
    AccumulatedLoss = InitialBalance - CurrentBalance;
}

void CloseAll()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionSelectByTicket(PositionGetTicket(i)))
        {
            if (PositionGetSymbol(i) == _Symbol)
            {
                trade.PositionClose(PositionGetTicket(i));
            }
        }
    }
}

void ShowDashboard()
{
    double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    Comment("╔════════════════════════════════════╗\n",
            "║  🏛️  EA XAUUSD WALL STREET  🏛️     ║\n",
            "╠════════════════════════════════════╣\n",
            "║ Balance: $", DoubleToString(Balance, 2), "\n",
            "║ Equity: $", DoubleToString(Equity, 2), "\n",
            "║ Daily Profit: $", DoubleToString(DailyProfit, 2), " / +$", DAILY_TP, "\n",
            "║ Daily Loss: $", DoubleToString(DailyLoss, 2), " / -$", DAILY_SL, "\n",
            "║ Accumulated Loss: -$", DoubleToString(AccumulatedLoss, 2), " / -$", ACCUMULATED_RISK, "\n",
            "╠════════════════════════════════════╣\n",
            "║ Open Trades: ", CountOpenTrades(), "/3\n",
            "║ Total Trades: ", stats.totalTrades, "\n",
            "║ Win Rate: ", DoubleToString(stats.winRate, 1), "%\n",
            "║ Winners: ", stats.winningTrades, " | Losers: ", stats.losingTrades, "\n",
            "╠════════════════════════════════════╣\n",
            "║ Support: ", DoubleToString(MainSupport, 2), "\n",
            "║ Resistance: ", DoubleToString(MainResistance, 2), "\n",
            "║ Accum Zone: ", DoubleToString(AccumulationZone, 2), "\n",
            "║ Dist Zone: ", DoubleToString(DistributionZone, 2), "\n",
            "╠════════════════════════════════════╣\n",
            "║ Status: ", PausedToday ? "⏸️ PAUSED" : (IsOperationHours24x7() ? "✅ OPERATING" : "❌ OUTSIDE HOURS"), "\n",
            "╚════════════════════════════════════╝");
}

void OnDeinit(const int reason)
{
    Print("════════════════════════════════════");
    Print("EA STOPPED");
    Print("Total Trades: ", stats.totalTrades);
    Print("Final Win Rate: ", DoubleToString(stats.winRate, 1), "%");
    Print("Final Balance: $", AccountInfoDouble(ACCOUNT_BALANCE));
    Print("════════════════════════════════════");
}
