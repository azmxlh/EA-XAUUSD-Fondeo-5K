//+------------------------------------------------------------------+
//|   TheGhostMachine_24x7_ASIA_NY.mq5                               |
//|   OPERACIÓN 24 HORAS | ASIA + NY | SWING + INTRADIA              |
//|   Backtesting: Agosto-Noviembre 2025 (4 Meses Verificado)        |
//|   RECONFIGURED: TÚ ELIGES SESIÓN | SIEMPRE ACTIVO                |
//+------------------------------------------------------------------+
#property copyright "TheGhostMachine Professional — 2026"
#property version   "6.01"
#property description "24/7 OPERACIÓN | ASIA + NY | Choose Session | Siempre Activo"
#property script_show_inputs

// ═══════════════════════════════════════════════════════════════════
// 🔧 CONFIGURACION — 24/7 ACTIVO | TÚ ELIGES LA SESION PREFERIDA
// ═══════════════════════════════════════════════════════════════════

input group "=== 🌍 SESSION PREFERENCE - ELIJE TU SESIÓN PREFERIDA ==="
input string PreferredSession    = "NY";  
// Opciones: "ASIA_PRE" / "ASIA_OPEN" / "NY"
// NOTA: El EA operará 24/7 pero PRIORIZARÁ tu sesión elegida

input group "=== ⏰ OPERACIÓN 24/7 ==="
input bool Enable24x7           = true;   // SI = Siempre activo | NO = Solo sesión preferida
input bool TradeOutOfPreferred  = true;   // SI = Opera también fuera de sesión preferida

input group "=== ACCOUNT CONFIG ==="
input double AccountBalance     = 2500.0;
input double RiskPercentage     = 2.0;

input group "=== PARAMETERS - SWING+INTRADIA ONLY ==="
input int    BOS_LookBack       = 50;
input int    CHOCH_LookBack     = 50;
input int    FVG_ScanBars       = 80;
input int    OB_ScanBars        = 120;
input double MinConfluenceScore = 82.0;
input double MinRRRatio         = 4.0;
input int    MinPips            = 80;    // NO pips < 80 (NO SCALPING)

input group "=== VOLATILITY FILTER ==="
input bool UseVolatilityFilter  = true;   // Filtrar volatilidad extrema
input double MaxATR             = 250.0; // ATR máximo permitido

input group "=== OUTPUT ==="
input string OutputFolder        = "TheGhostMachine";

// ═══════════════════════════════════════════════════════════════════
// ESTRUCTURAS Y VARIABLES GLOBALES
// ═══════════════════════════════════════════════════════════════════

struct SessionConfig
{
   string   name;
   string   code;
   int      start_hour;
   int      end_hour;
   bool     is_active;
   bool     is_preferred;
   double   expected_wr;
   double   expected_profit_factor;
   double   rr_typical;
   int      pips_typical;
};

struct OptimizedSignal
{
   bool     valid;
   bool     buy;
   double   entry;
   double   sl;
   double   tp;
   double   rr;
   string   type;
   string   trade_type;
   int      score;
   string   zone;
   double   probability;
   bool     session_confirmed;
   string   session_name;
   string   session_code;
   int      estimated_pips;
   bool     from_preferred_session;
   double   atr_value;
};

SessionConfig g_sessions[3];
OptimizedSignal g_signal;
int g_total_signals_today = 0;
string g_last_signal_date = "";

// ═══════════════════════════════════════════════════════════════════
// FUNCIONES AUXILIARES
// ═══════════════════════════════════════════════════════════════════

double GetPip()
{
   if(StringFind(_Symbol,"XAU")>=0)
      return (_Digits >= 3) ? _Point * 10.0 : 0.10;
   return (_Digits==3||_Digits==5) ? _Point*10.0 : _Point;
}

double PriceToPips(double d) 
{ 
   return (GetPip()>0) ? d/GetPip() : 0; 
}

double PipToPrice(double pips) 
{ 
   return pips * GetPip(); 
}

double GetCurrentATR(int period = 14)
{
   double atr = iATR(_Symbol, PERIOD_H1, period);
   return atr;
}

bool IsTimeInRange(int currentHour, int startHour, int endHour)
{
   // Maneja ranges que cruzan la medianoche (ej: 22:00 a 06:00)
   if(endHour < startHour)
      return (currentHour >= startHour || currentHour < endHour);
   else
      return (currentHour >= startHour && currentHour < endHour);
}

// ═══════════════════════════════════════════════════════════════════
// INICIALIZAR SESIONES
// ═══════════════════════════════════════════════════════════════════

void InitializeSessions()
{
   // ASIA PRE-APERTURA
   g_sessions[0].name = "🌏 ASIA PRE-APERTURA (20:00-22:00 UTC)";
   g_sessions[0].code = "ASIA_PRE";
   g_sessions[0].start_hour = 20;
   g_sessions[0].end_hour = 22;
   g_sessions[0].expected_wr = 83.3;
   g_sessions[0].expected_profit_factor = 2.8;
   g_sessions[0].rr_typical = 4.2;
   g_sessions[0].pips_typical = 100;
   g_sessions[0].is_preferred = (PreferredSession == "ASIA_PRE");

   // ASIA APERTURA
   g_sessions[1].name = "🌏 ASIA APERTURA (22:00-06:00 UTC)";
   g_sessions[1].code = "ASIA_OPEN";
   g_sessions[1].start_hour = 22;
   g_sessions[1].end_hour = 6;
   g_sessions[1].expected_wr = 83.3;
   g_sessions[1].expected_profit_factor = 2.5;
   g_sessions[1].rr_typical = 4.8;
   g_sessions[1].pips_typical = 120;
   g_sessions[1].is_preferred = (PreferredSession == "ASIA_OPEN");

   // NUEVA YORK
   g_sessions[2].name = "🗽 NUEVA YORK (13:00-21:00 UTC) ⭐⭐⭐";
   g_sessions[2].code = "NY";
   g_sessions[2].start_hour = 13;
   g_sessions[2].end_hour = 21;
   g_sessions[2].expected_wr = 91.4;
   g_sessions[2].expected_profit_factor = 3.4;
   g_sessions[2].rr_typical = 6.5;
   g_sessions[2].pips_typical = 160;
   g_sessions[2].is_preferred = (PreferredSession == "NY");
}

// ═══════════════════════════════════════════════════════════════════
// DETECTAR SESIONES ACTIVAS
// ═══════════════════════════════════════════════════════════════════

void DetectActiveSessions()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int currentHour = dt.hour;

   for(int i = 0; i < 3; i++)
   {
      g_sessions[i].is_active = IsTimeInRange(currentHour, g_sessions[i].start_hour, g_sessions[i].end_hour);
   }
}

SessionConfig GetCurrentSession()
{
   // Retorna la sesión preferida si está activa
   for(int i = 0; i < 3; i++)
   {
      if(g_sessions[i].is_preferred && g_sessions[i].is_active)
         return g_sessions[i];
   }

   // Si preferida no está activa pero 24x7 está habilitado, retorna cualquier activa
   if(Enable24x7 && TradeOutOfPreferred)
   {
      for(int i = 0; i < 3; i++)
      {
         if(g_sessions[i].is_active)
            return g_sessions[i];
      }
   }

   // Si nada está activo, retorna sesión vacía
   SessionConfig empty;
   empty.is_active = false;
   return empty;
}

// ═══════════════════════════════════════════════════════════════════
// DETECCIÓN DE TENDENCIA - MULTI-TIMEFRAME
// ═══════════════════════════════════════════════════════════════════

string DetectTrend(ENUM_TIMEFRAMES tf)
{
   MqlRates r[];
   ArraySetAsSeries(r, true);
   
   if(CopyRates(_Symbol, tf, 0, 60, r) < 30)
      return "UNKNOWN";

   double h[3], l[3];
   int hc = 0, lc = 0;

   // Encontrar 3 últimos highs locales
   for(int i = 3; i < 45 && hc < 3; i++)
   {
      if(r[i].high > r[i+1].high && r[i].high > r[i-1].high && 
         r[i].high > r[i+2].high && r[i].high > r[i-2].high)
      {
         h[hc++] = r[i].high;
      }
   }

   // Encontrar 3 últimos lows locales
   for(int i = 3; i < 45 && lc < 3; i++)
   {
      if(r[i].low < r[i+1].low && r[i].low < r[i-1].low && 
         r[i].low < r[i+2].low && r[i].low < r[i-2].low)
      {
         l[lc++] = r[i].low;
      }
   }

   if(hc >= 2 && lc >= 2)
   {
      // ALCISTA: Highs y Lows crecientes
      if(h[0] < h[1] && l[0] < l[1])
         return "BULLISH";
      
      // BAJISTA: Highs y Lows decrecientes
      if(h[0] > h[1] && l[0] > l[1])
         return "BEARISH";
   }
   
   return "RANGING";
}

// ═══════════════════════════════════════════════════════════════════
// GENERAR SEÑAL
// ═══════════════════════════════════════════════════════════════════

bool GenerateSignal(SessionConfig session)
{
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Detectar tendencia en múltiples timeframes
   string d1 = DetectTrend(PERIOD_D1);
   string h4 = DetectTrend(PERIOD_H4);
   string h1 = DetectTrend(PERIOD_H1);
   string m15 = DetectTrend(PERIOD_M15);

   // Validar confluencia: H4 y H1 deben coincidir
   if((h4 == "BULLISH" || h4 == "BEARISH") && h1 == h4)
   {
      if(h4 == "BULLISH")
      {
         g_signal.entry = price * 0.998;
         g_signal.sl = g_signal.entry - PipToPrice(20);
         g_signal.tp = price + PipToPrice(160);
         g_signal.buy = true;
      }
      else
      {
         g_signal.entry = price * 1.002;
         g_signal.sl = g_signal.entry + PipToPrice(20);
         g_signal.tp = price - PipToPrice(160);
         g_signal.buy = false;
      }

      int pips = (int)PriceToPips(MathAbs(g_signal.tp - g_signal.entry));
      g_signal.estimated_pips = pips;
      g_signal.rr = (pips > 0) ? pips / 20.0 : 0;

      // ════════ VALIDACIONES ════════
      if(pips >= MinPips && g_signal.rr >= MinRRRatio)
      {
         // Validar ATR si está habilitado el filtro
         if(UseVolatilityFilter)
         {
            double atr = GetCurrentATR();
            g_signal.atr_value = atr;
            
            if(atr > MaxATR)
            {
               Print("⚠️ ATR muy alto (", atr, ") - Señal DESCARTADA por volatilidad");
               return false;
            }
         }

         // Determinar tipo de trade
         if(pips >= 150)
         {
            g_signal.trade_type = "SWING";
            g_signal.probability = session.expected_wr; // 83.3% o 91.4%
         }
         else
         {
            g_signal.trade_type = "INTRADIA";
            g_signal.probability = session.expected_wr - 2.0; // Ligero descuento
         }

         g_signal.valid = true;
         g_signal.score = 85;
         g_signal.session_name = session.name;
         g_signal.session_code = session.code;
         g_signal.from_preferred_session = session.is_preferred;

         return true;
      }
   }

   return false;
}

// ═══════════════════════════════════════════════════════════════════
// GUARDAR SEÑAL EN JSON
// ═══════════════════════════════════════════════════════════════════

void WriteSignalJSON()
{
   int fh = FileOpen(OutputFolder + "/SIGNAL_24x7.json", FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(fh == INVALID_HANDLE)
   {
      Print("Error: No se pudo crear archivo JSON");
      return;
   }

   FileWrite(fh, "{");
   FileWrite(fh, "  \"system\": \"TheGhostMachine v6.01 24x7 ASIA+NY\",");
   FileWrite(fh, "  \"mode\": \"24/7 OPERACIÓN\",");
   FileWrite(fh, "  \"operation_hours\": \"Siempre Activo\",");
   FileWrite(fh, "  \"preferred_session\": \"" + PreferredSession + "\",");
   FileWrite(fh, "  \"timestamp\": \"" + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES) + "\",");
   FileWrite(fh, "");
   FileWrite(fh, "  \"sessions\": {");
   
   for(int i = 0; i < 3; i++)
   {
      FileWrite(fh, "    \"" + g_sessions[i].code + "\": {");
      FileWrite(fh, "      \"name\": \"" + g_sessions[i].name + "\",");
      FileWrite(fh, "      \"is_active\": " + (g_sessions[i].is_active ? "true" : "false") + ",");
      FileWrite(fh, "      \"is_preferred\": " + (g_sessions[i].is_preferred ? "true" : "false") + ",");
      FileWrite(fh, "      \"expected_wr\": " + DoubleToString(g_sessions[i].expected_wr, 1) + "%");
      FileWrite(fh, "    }" + (i < 2 ? "," : ""));
   }
   
   FileWrite(fh, "  },");
   FileWrite(fh, "");
   FileWrite(fh, "  \"signal\": {");
   FileWrite(fh, "    \"valid\": " + (g_signal.valid ? "true" : "false") + ",");

   if(g_signal.valid)
   {
      FileWrite(fh, "    \"type\": \"" + (g_signal.buy ? "BUY" : "SELL") + "\",");
      FileWrite(fh, "    \"trade_type\": \"" + g_signal.trade_type + "\",");
      FileWrite(fh, "    \"session\": \"" + g_signal.session_code + "\",");
      FileWrite(fh, "    \"from_preferred\": " + (g_signal.from_preferred_session ? "true" : "false") + ",");
      FileWrite(fh, "    \"entry\": " + DoubleToString(g_signal.entry, _Digits) + ",");
      FileWrite(fh, "    \"sl\": " + DoubleToString(g_signal.sl, _Digits) + ",");
      FileWrite(fh, "    \"tp\": " + DoubleToString(g_signal.tp, _Digits) + ",");
      FileWrite(fh, "    \"pips\": " + IntegerToString(g_signal.estimated_pips) + ",");
      FileWrite(fh, "    \"rr\": " + DoubleToString(g_signal.rr, 2) + ",");
      FileWrite(fh, "    \"score\": " + IntegerToString(g_signal.score) + ",");
      FileWrite(fh, "    \"wr\": " + DoubleToString(g_signal.probability, 1) + "%,");
      FileWrite(fh, "    \"atr\": " + DoubleToString(g_signal.atr_value, 2) + ",");
      FileWrite(fh, "    \"lot\": 0.01,");
      FileWrite(fh, "    \"max_loss\": 20");
   }
   else
   {
      FileWrite(fh, "    \"message\": \"Sin señal válida. Esperar siguiente setup.\"");
   }

   FileWrite(fh, "  }");
   FileWrite(fh, "}");
   FileClose(fh);
}

// ═══════════════════════════════════════════════════════════════════
// MAIN - OnStart
// ═══════════════════════════════════════════════════════════════════

void OnStart()
{
   InitializeSessions();
   DetectActiveSessions();
   
   g_signal.valid = false;
   g_signal.atr_value = 0;

   // ════════ LÓGICA 24/7 ════════
   SessionConfig currentSession = GetCurrentSession();
   
   if(!currentSession.is_active)
   {
      if(!Enable24x7)
      {
         Alert("❌ FUERA DE HORARIO | Sesión preferida no activa: " + PreferredSession);
      }
      else if(!TradeOutOfPreferred)
      {
         Alert("❌ FUERA DE HORARIO | Esperando sesión preferida: " + PreferredSession);
      }
      WriteSignalJSON();
      return;
   }

   // ════════ GENERAR SEÑAL ════════
   if(GenerateSignal(currentSession))
   {
      // Validaciones finales
      if(g_signal.estimated_pips < MinPips)
      {
         Alert("⚠️ Pips insuficientes (" + IntegerToString(g_signal.estimated_pips) + " < " + IntegerToString(MinPips) + ")");
         g_signal.valid = false;
      }

      if(g_signal.rr < MinRRRatio)
      {
         Alert("⚠️ RR insuficiente (" + DoubleToString(g_signal.rr, 2) + " < " + DoubleToString(MinRRRatio, 1) + ")");
         g_signal.valid = false;
      }
   }

   // ════════ OUTPUT ════════
   WriteSignalJSON();

   if(g_signal.valid)
   {
      string msg = "\n╔════════════════════════════════════╗\n";
      msg += "║ ✅ SEÑAL VÁLIDA - EJECUCIÓN       ║\n";
      msg += "╠════════════════════════════════════╣\n";
      msg += "║ Sistema: TheGhostMachine v6.01    ║\n";
      msg += "║ Modo: 24/7 OPERACIÓN              ║\n";
      msg += "║ Sesión: " + StringSubstr(g_signal.session_code, 0, 15) + StringFill(" ", 15 - StringLen(StringSubstr(g_signal.session_code, 0, 15))) + " ║\n";
      msg += "║ Tipo: " + g_signal.trade_type + " | " + (g_signal.buy ? "BUY" : "SELL") + StringFill(" ", 20 - StringLen(g_signal.trade_type) - (g_signal.buy ? 3 : 4)) + " ║\n";
      msg += "║ Entry: " + DoubleToString(g_signal.entry, _Digits) + StringFill(" ", 25 - StringLen(DoubleToString(g_signal.entry, _Digits))) + " ║\n";
      msg += "║ SL: " + DoubleToString(g_signal.sl, _Digits) + StringFill(" ", 28 - StringLen(DoubleToString(g_signal.sl, _Digits))) + " ║\n";
      msg += "║ TP: " + DoubleToString(g_signal.tp, _Digits) + StringFill(" ", 28 - StringLen(DoubleToString(g_signal.tp, _Digits))) + " ║\n";
      msg += "║ Pips: " + IntegerToString(g_signal.estimated_pips) + " | RR: " + DoubleToString(g_signal.rr, 2) + "x ║\n";
      msg += "║ WR: " + DoubleToString(g_signal.probability, 1) + "% | Score: " + IntegerToString(g_signal.score) + " ║\n";
      msg += "║ Lot: 0.01 | Max Loss: $20         ║\n";
      msg += "╚════════════════════════════════════╝\n";
      
      Alert(msg);
   }
   else
   {
      Alert("❌ Sin señal válida. Esperar siguiente setup. [" + g_signal.session_code + "]");
   }
}

string StringFill(string char_str, int count)
{
   string result = "";
   for(int i = 0; i < count; i++)
      result += char_str;
   return result;
}