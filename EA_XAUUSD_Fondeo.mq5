#property strict
#include <Trade\Trade.mqh>

// ================== VARIABLES GLOBALES ==================
CTrade trade;

// GESTIÓN DE RIESGO
double LotActual = 0.01;
double GananciaDiaria = 0;
double PerdidaDiaria = 0;
double PerdidaAcumulada = 0;
double BalanceInicial = 5000;

const double TP_DIARIO = 500;
const double SL_DIARIO = 100;
const double RIESGO_ACUMULADO = 500;
const int DURACION_MIN_MINUTOS = 5;

// INDICADORES Y PARÁMETROS
const int RSI_PERIOD = 14;
const int ATR_PERIOD = 14;
const int BB_PERIOD = 20;
const double BB_DESV = 2.0;
const int MACD_FAST = 12;
const int MACD_SLOW = 26;
const int MACD_SIGNAL = 9;

// NIVELES INSTITUCIONALES
double ResistenciaPrincipal = 0;
double SoportePrincipal = 0;
double ZonaAcumulacion = 0;
double ZonaDistribucion = 0;

// CONTROL DE SESIONES
int DiaAnterior = -1;
bool PausadoHoy = false;

// ESTADÍSTICAS
struct TradeStats {
    int totalTrades;
    int tradesGanadores;
    int tradesPerdedores;
    double winRate;
};

TradeStats stats = {0, 0, 0, 0};

//+------------------------------------------------------------------+
//| INIT                                                             |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("╔════════════════════════════════════╗");
    Print("║  EA XAUUSD FONDEO $5K (Wall St)   ║");
    Print("║  Timeframe: M5 (5 minutos)        ║");
    Print("║  Capital: $5,000                  ║");
    Print("║  Estrategia: Smart Money + Confluence ║");
    Print("╚════════════════════════════════════╝");
    
    BalanceInicial = AccountInfoDouble(ACCOUNT_BALANCE);
    CalcularNivelesInstitucionales();
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| TICK - CORAZÓN DEL EA                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    // RESETEAR POR DÍA
    if (DiaAnterior != Day())
    {
        GananciaDiaria = 0;
        PerdidaDiaria = 0;
        PausadoHoy = false;
        DiaAnterior = Day();
        
        Print("═══════ NUEVO DÍA - Balance: $", AccountInfoDouble(ACCOUNT_BALANCE), " ═══════");
        CalcularNivelesInstitucionales();
    }
    
    // 1. VERIFICAR LÍMITES CRÍTICOS
    if (!VerificarLimitesCriticos()) return;
    
    // 2. RECALCULAR NIVELES DINÁMICAMENTE
    CalcularNivelesInstitucionales();
    
    // 3. GESTIÓN DE TRADES ABIERTOS
    GestionarTradesAbiertos();
    
    // 4. VERIFICAR OPORTUNIDADES DE ENTRADA
    if (EsHorarioOperacion24x7())
    {
        VerificarSenalesEntrada();
    }
    
    // 5. MOSTRAR DASHBOARD
    MostrarDashboard();
}

//+------------------------------------------------------------------+
//| 🎯 CÁLCULO DE NIVELES INSTITUCIONALES (Smart Money)              |
//+------------------------------------------------------------------+
void CalcularNivelesInstitucionales()
{
    // Datos del último HIGH-LOW (volatilidad)
    double High24 = iHigh(_Symbol, PERIOD_D1, 0);
    double Low24 = iLow(_Symbol, PERIOD_D1, 0);
    double Close = iClose(_Symbol, PERIOD_M5, 0);
    
    // RANGO DE VOLATILIDAD
    double RangoVolatilidad = High24 - Low24;
    
    // PIVOT POINT (Punto central de trading)
    double PP = (High24 + Low24 + Close) / 3;
    
    // RESISTENCIA Y SOPORTE DIARIOS
    ResistenciaPrincipal = PP + (RangoVolatilidad * 0.618);
    SoportePrincipal = PP - (RangoVolatilidad * 0.618);
    
    // ZONA DE ACUMULACIÓN (donde institucionales compran)
    ZonaAcumulacion = SoportePrincipal - (RangoVolatilidad * 0.382);
    
    // ZONA DE DISTRIBUCIÓN (donde institucionales venden)
    ZonaDistribucion = ResistenciaPrincipal + (RangoVolatilidad * 0.382);
}

//+------------------------------------------------------------------+
//| ✅ VERIFICAR SEÑALES DE ENTRADA (CONFLUENCE)                     |
//+------------------------------------------------------------------+
void VerificarSenalesEntrada()
{
    // NO OPERAR si hay muchos trades abiertos
    if (NumTradesAbiertos() >= 3) return;
    
    double Close = iClose(_Symbol, PERIOD_M5, 0);
    double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // ========== INDICADOR 1: RSI ==========
    double RSI = iRSI(_Symbol, PERIOD_M5, RSI_PERIOD, PRICE_CLOSE);
    bool RSI_Oversold = RSI < 30;
    bool RSI_Overbought = RSI > 70;
    
    // ========== INDICADOR 2: MACD (CORREGIDO) ==========
    // iMACD retorna un handle, no un valor. Necesitamos CopyBuffer
    int macdHandle = iMACD(_Symbol, PERIOD_M5, MACD_FAST, MACD_SLOW, MACD_SIGNAL, PRICE_CLOSE);
    double macdLine[], macdSignal[];
    ArraySetAsSeries(macdLine, true);
    ArraySetAsSeries(macdSignal, true);
    
    CopyBuffer(macdHandle, 0, 0, 1, macdLine);      // MACD line
    CopyBuffer(macdHandle, 1, 0, 1, macdSignal);    // Signal line
    
    double MACD = (ArraySize(macdLine) > 0) ? macdLine[0] : 0;
    double MACD_Signal = (ArraySize(macdSignal) > 0) ? macdSignal[0] : 0;
    bool MACD_BullishCrossover = MACD > MACD_Signal;
    bool MACD_BearishCrossover = MACD < MACD_Signal;
    
    // ========== INDICADOR 3: BOLLINGER BANDS (CORREGIDO) ==========
    // iBands retorna un handle, necesitamos CopyBuffer
    int bandHandle = iBands(_Symbol, PERIOD_M5, BB_PERIOD, 0, BB_DESV);
    double bbUpper[], bbLower[], bbMiddle[];
    
    ArraySetAsSeries(bbUpper, true);
    ArraySetAsSeries(bbLower, true);
    ArraySetAsSeries(bbMiddle, true);
    
    CopyBuffer(bandHandle, 1, 0, 1, bbUpper);   // Upper band
    CopyBuffer(bandHandle, 2, 0, 1, bbLower);   // Lower band
    CopyBuffer(bandHandle, 0, 0, 1, bbMiddle);  // Middle band
    
    double BB_Upper = (ArraySize(bbUpper) > 0) ? bbUpper[0] : Ask + 100 * _Point;
    double BB_Lower = (ArraySize(bbLower) > 0) ? bbLower[0] : Ask - 100 * _Point;
    double BB_Middle = (ArraySize(bbMiddle) > 0) ? bbMiddle[0] : Close;
    
    bool Precio_NearBBLower = Close < BB_Middle && Close > BB_Lower;
    bool Precio_NearBBUpper = Close > BB_Middle && Close < BB_Upper;
    
    // ========== INDICADOR 4: ATR (Volatilidad) ==========
    double ATR = iATR(_Symbol, PERIOD_M5, ATR_PERIOD);
    bool Volatilidad_Optima = ATR > 0.5 && ATR < 3.0;
    
    // ========== INDICADOR 5: SMART MONEY LEVELS ==========
    double Precio = Close;
    double RangoVolatilidad = iHigh(_Symbol, PERIOD_D1, 0) - iLow(_Symbol, PERIOD_D1, 0);
    bool En_ZonaAcumulacion = Precio >= ZonaAcumulacion && Precio <= SoportePrincipal;
    bool En_ZonaDistribucion = Precio >= ResistenciaPrincipal && Precio <= ZonaDistribucion;
    bool Rebote_Soporte = Precio >= SoportePrincipal && Precio <= SoportePrincipal + (RangoVolatilidad * 0.05);
    bool Rebote_Resistencia = Precio >= ResistenciaPrincipal - (RangoVolatilidad * 0.05) && Precio <= ResistenciaPrincipal;
    
    // ========== SIGNAL BUY: CONFLUENCE ==========
    int ConfluenceBuy = 0;
    if (RSI_Oversold) ConfluenceBuy++;
    if (MACD_BullishCrossover) ConfluenceBuy++;
    if (Precio_NearBBLower) ConfluenceBuy++;
    if (Volatilidad_Optima) ConfluenceBuy++;
    if (En_ZonaAcumulacion || Rebote_Soporte) ConfluenceBuy++;
    
    if (ConfluenceBuy >= 3)
    {
        AbrirCompra(Ask, ConfluenceBuy);
    }
    
    // ========== SIGNAL SELL: CONFLUENCE ==========
    int ConfluenceSell = 0;
    if (RSI_Overbought) ConfluenceSell++;
    if (MACD_BearishCrossover) ConfluenceSell++;
    if (Precio_NearBBUpper) ConfluenceSell++;
    if (Volatilidad_Optima) ConfluenceSell++;
    if (En_ZonaDistribucion || Rebote_Resistencia) ConfluenceSell++;
    
    if (ConfluenceSell >= 3)
    {
        AbrirVenta(Bid, ConfluenceSell);
    }
}

//+------------------------------------------------------------------+
//| 📈 ABRIR COMPRA CON LÓGICA AVANZADA                              |
//+------------------------------------------------------------------+
void AbrirCompra(double Ask, int ConfluenceLevel)
{
    // SL: 40 pips
    double SL = Ask - 40 * _Point;
    
    // TP: Fibonacci
    double TP = Ask + (100 + (ConfluenceLevel * 20)) * _Point;
    
    string Razon = "BUY | Confluence: " + (string)ConfluenceLevel + "/5";
    
    if (trade.Buy(LotActual, _Symbol, Ask, SL, TP, Razon))
    {
        Print("✅ BUY ABIERTO | Ask: ", Ask, " | SL: ", SL, " | TP: ", TP, " | Razón: ", Razon);
        stats.totalTrades++;
    }
}

//+------------------------------------------------------------------+
//| 📉 ABRIR VENTA CON LÓGICA AVANZADA                               |
//+------------------------------------------------------------------+
void AbrirVenta(double Bid, int ConfluenceLevel)
{
    // SL: 40 pips
    double SL = Bid + 40 * _Point;
    
    // TP: Fibonacci
    double TP = Bid - (100 + (ConfluenceLevel * 20)) * _Point;
    
    string Razon = "SELL | Confluence: " + (string)ConfluenceLevel + "/5";
    
    if (trade.Sell(LotActual, _Symbol, Bid, SL, TP, Razon))
    {
        Print("✅ SELL ABIERTO | Bid: ", Bid, " | SL: ", SL, " | TP: ", TP, " | Razón: ", Razon);
        stats.totalTrades++;
    }
}

//+------------------------------------------------------------------+
//| 💰 GESTIÓN DE TRADES ABIERTOS                                    |
//+------------------------------------------------------------------+
void GestionarTradesAbiertos()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionSelectByTicket(PositionGetTicket(i)))
        {
            if (PositionGetSymbol(i) == _Symbol)
            {
                ulong ticket = PositionGetTicket(i);
                long timeEntry = PositionGetInteger(POSITION_TIME);
                long minutosAbiertos = (TimeCurrent() - timeEntry) / 60;
                
                double EntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double Profit = PositionGetDouble(POSITION_PROFIT);
                int Type = PositionGetInteger(POSITION_TYPE);
                
                double CurrentPrice = (Type == POSITION_TYPE_BUY) 
                    ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                    : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                
                // ========== BREAK EVEN DINÁMICO ==========
                if ((Type == POSITION_TYPE_BUY && CurrentPrice > EntryPrice + 50 * _Point) ||
                    (Type == POSITION_TYPE_SELL && CurrentPrice < EntryPrice - 50 * _Point))
                {
                    double NewSL = EntryPrice;
                    if (PositionGetDouble(POSITION_SL) != NewSL)
                    {
                        trade.PositionModify(ticket, NewSL, PositionGetDouble(POSITION_TP));
                        Print("✅ BREAK EVEN activado | Ticket: ", ticket);
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
                
                // ========== RE-ENTRY ESCALONADA ==========
                if (minutosAbiertos >= DURACION_MIN_MINUTOS && Profit > 50)
                {
                    if (NumTradesAbiertos() < 3)
                    {
                        double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                        double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                        
                        if (Type == POSITION_TYPE_BUY)
                        {
                            AbrirCompra(Ask, 3);
                        }
                        else
                        {
                            AbrirVenta(Bid, 3);
                        }
                    }
                }
                
                // ========== REGISTRO DE ESTADÍSTICAS ==========
                if (Profit > 0)
                    stats.tradesGanadores++;
                else
                    stats.tradesPerdedores++;
            }
        }
    }
    
    // Calcular Win Rate
    if (stats.totalTrades > 0)
        stats.winRate = (stats.tradesGanadores / (double)stats.totalTrades) * 100;
}

//+------------------------------------------------------------------+
//| ⚠️ VERIFICAR LÍMITES CRÍTICOS                                    |
//+------------------------------------------------------------------+
bool VerificarLimitesCriticos()
{
    // 1. PÉRDIDA ACUMULADA
    if (PerdidaAcumulada >= RIESGO_ACUMULADO)
    {
        CerrarTodo();
        Alert("⛔ CUENTA DE FONDEO PERDIDA");
        ExpertRemove();
        return false;
    }
    
    // 2. PÉRDIDA DIARIA
    if (PerdidaDiaria <= -SL_DIARIO)
    {
        if (!PausadoHoy)
        {
            CerrarTodo();
            PausadoHoy = true;
            Alert("⚠️ LÍMITE DIARIO ALCANZADO: -$", SL_DIARIO);
        }
        return false;
    }
    
    // 3. GANANCIA DIARIA
    if (GananciaDiaria >= TP_DIARIO)
    {
        CerrarTodo();
        Alert("✅ META DIARIA ALCANZADA: +$", TP_DIARIO);
        PausadoHoy = true;
        return false;
    }
    
    ActualizarPyL();
    return true;
}

//+------------------------------------------------------------------+
//| 🕐 HORARIO DE OPERACIÓN 24/7                                     |
//+------------------------------------------------------------------+
bool EsHorarioOperacion24x7()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int hora = dt.hour;
    
    // Asia: 20:00-04:00 GMT
    if (hora >= 20 || hora < 4) return true;
    
    // Londres: 08:00-17:00 GMT
    if (hora >= 8 && hora < 17) return true;
    
    // NY: 13:00-21:00 GMT
    if (hora >= 13 && hora < 21) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| 🎲 FUNCIONES AUXILIARES                                          |
//+------------------------------------------------------------------+

int NumTradesAbiertos()
{
    int contador = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionSelectByTicket(PositionGetTicket(i)))
        {
            if (PositionGetSymbol(i) == _Symbol)
                contador++;
        }
    }
    return contador;
}

void ActualizarPyL()
{
    double BalanceActual = AccountInfoDouble(ACCOUNT_BALANCE);
    GananciaDiaria = BalanceActual - BalanceInicial;
    PerdidaAcumulada = BalanceInicial - BalanceActual;
}

void CerrarTodo()
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

void MostrarDashboard()
{
    double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    Comment("╔════════════════════════════════════╗\n",
            "║  🏛️  EA XAUUSD WALL STREET  🏛️     ║\n",
            "╠════════════════════════════════════╣\n",
            "║ Balance: $", DoubleToString(Balance, 2), "\n",
            "║ Equity: $", DoubleToString(Equity, 2), "\n",
            "║ Ganancia Hoy: $", DoubleToString(GananciaDiaria, 2), " / +$", TP_DIARIO, "\n",
            "║ Pérdida Hoy: $", DoubleToString(PerdidaDiaria, 2), " / -$", SL_DIARIO, "\n",
            "║ Pérdida Acumulada: -$", DoubleToString(PerdidaAcumulada, 2), " / -$", RIESGO_ACUMULADO, "\n",
            "╠════════════════════════════════════╣\n",
            "║ Trades Abiertos: ", NumTradesAbiertos(), "/3\n",
            "║ Total Trades: ", stats.totalTrades, "\n",
            "║ Win Rate: ", DoubleToString(stats.winRate, 1), "%\n",
            "║ Ganadores: ", stats.tradesGanadores, " | Perdedores: ", stats.tradesPerdedores, "\n",
            "╠════════════════════════════════════╣\n",
            "║ Soporte: ", DoubleToString(SoportePrincipal, 2), "\n",
            "║ Resistencia: ", DoubleToString(ResistenciaPrincipal, 2), "\n",
            "║ Zona Acum: ", DoubleToString(ZonaAcumulacion, 2), "\n",
            "║ Zona Dist: ", DoubleToString(ZonaDistribucion, 2), "\n",
            "╠════════════════════════════════════╣\n",
            "║ Estado: ", PausadoHoy ? "⏸️ PAUSADO" : (EsHorarioOperacion24x7() ? "✅ OPERANDO" : "❌ FUERA HORARIO"), "\n",
            "╚════════════════════════════════════╝");
}

void OnDeinit(const int reason)
{
    Print("════════════════════════════════════");
    Print("EA DETENIDO");
    Print("Total Trades: ", stats.totalTrades);
    Print("Win Rate Final: ", DoubleToString(stats.winRate, 1), "%");
    Print("Balance Final: $", AccountInfoDouble(ACCOUNT_BALANCE));
    Print("════════════════════════════════════");
}
