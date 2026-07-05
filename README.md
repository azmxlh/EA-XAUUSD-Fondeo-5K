# 🏛️ EA XAUUSD FONDEO $5K - Wall Street Level

**Automated Expert Advisor for XAUUSD (Gold)**  
Designed for funded account operations with institutional-level risk management

---

## 📊 GENERAL OVERVIEW

This EA is designed to trade **XAUUSD** on a funded account of **$5,000** with strict risk management rules at Wall Street institutional level.

### 🎯 Objectives
- **Phase 1:** Earn $500 (10% ROI) within maximum 5 days
- **Maximum daily loss:** -$100 (STOP)
- **Maximum account loss:** -$500 (GAME OVER)
- **Maximum daily profit:** +$500 (CLOSE ALL)

---

## 🔧 FEATURES

✅ **24/7 Operation**
- Asia (20:00-04:00 GMT)
- London (08:00-17:00 GMT)
- New York (13:00-21:00 GMT)

✅ **Confluence Strategy (Smart Money)**
- RSI + MACD + Bollinger Bands + ATR + Smart Money Levels
- Requires minimum 3/5 confirmations for entry

✅ **Dynamic Management**
- Automatic Break Even (+50 pips)
- Trailing Stop (+100 pips)
- Staggered re-entries

✅ **No Scalping**
- Minimum trade duration: 5 minutes
- Designed for medium-term operations

✅ **Real-Time Statistics**
- Dashboard with P&L, Win Rate, institutional levels
- Complete trade log

---

## 📈 MAIN PARAMETERS

```
INDICATOR          PARAMETER        DESCRIPTION
─────────────────────────────────────────────────
RSI                14               RSI Period
MACD               12,26,9          Fast, Slow, Signal
Bollinger Bands    20, 2.0          Period and deviation
ATR                14               ATR Period
Minimum Duration   5 minutes        Timeframe M5

RISK MANAGEMENT
─────────────────────────────────────────────────
Initial Lot Size   0.01             Micro lot
Daily TP           $500             Maximum profit
Daily SL           -$100            Maximum loss
Account Loss       -$500            Total allowed
Max Simultaneous   3 simultaneous
Trades
```

---

## 🚀 INSTALLATION

1. **Download the EA file**
   ```
   EA_XAUUSD_Fondeo.mq5
   ```

2. **Copy to MT5 folder**
   ```
   C:\Users\[User]\AppData\Roaming\MetaTrader 5\MQL5\Experts\
   ```

3. **Compile the EA**
   - Open MetaEditor
   - Go to: File → Open → EA_XAUUSD_Fondeo.mq5
   - Press F7 (Compile)

4. **Load in MT5**
   - Open MT5
   - Go to: Symbols → XAUUSD
   - Timeframe: M5 (5 minutes)
   - Drag EA from Navigator → XAUUSD
   - Enable Automated Trading

---

## ⚙️ CONFIGURATION

### Required Account
- **Broker:** Any offering XAUUSD (ICMarkets, Exness, etc.)
- **Type:** Micro or Mini lots (lot size 0.01)
- **Leverage:** Minimum 1:50
- **XAUUSD Spread:** < 0.50 pips (recommended)

### Recommended MT5 Settings
1. **Tools → Options → Expert Advisors**
   - ✅ Enable Automated Trading
   - ✅ Allow live trading
   - ✅ Allow DLL imports

2. **Chart Settings**
   - Timeframe: M5
   - Symbol: XAUUSD
   - Detach from chart: NO (to view statistics)

---

## 📊 HOW IT WORKS

### Operation Flow

```
1. CALCULATE INSTITUTIONAL LEVELS
   ↓
2. WAIT FOR 24/7 OPERATION HOURS
   ↓
3. SCAN CONFLUENCE SIGNALS (3/5 confirmations)
   ↓
4. OPEN TRADE WITH SL + TP
   ↓
5. MANAGE WITH BREAK EVEN + TRAILING STOP
   ↓
6. CLOSE BY TP OR SL
   ↓
7. STAGGERED RE-ENTRY IF CONDITIONS MET
   ↓
8. VERIFY DAILY/ACCUMULATED LIMITS
```

### Entry Signals

**BUY - Confluence ≥ 3/5:**
```
✅ RSI < 30 (Oversold)
✅ MACD Bullish Crossover
✅ Price near Bollinger Lower Band
✅ ATR in range 0.5-3.0
✅ In accumulation zone OR support bounce
```

**SELL - Confluence ≥ 3/5:**
```
✅ RSI > 70 (Overbought)
✅ MACD Bearish Crossover
✅ Price near Bollinger Upper Band
✅ ATR in range 0.5-3.0
✅ In distribution zone OR resistance bounce
```

---

## 💰 RISK MANAGEMENT

### Institutional Levels (Smart Money)

The EA automatically calculates:

```
Pivot Point (PP)           = (High24h + Low24h + Close) / 3
Main Resistance            = PP + (Range × 0.618)
Main Support               = PP - (Range × 0.618)
Accumulation Zone          = Support - (Range × 0.382)
Distribution Zone          = Resistance + (Range × 0.382)
```

These levels are updated daily and displayed on the dashboard.

### Dynamic Break Even

```
After +50 pips:            SL moves to entry price (protects gains)
After +100 pips:           Trailing Stop activated (SL follows -50 pips)
```

### Staggered Re-entries

```
If profit > +50 pips:      Open second position (lot 0.005)
Maximum 3 open trades:     Limits exposure
```

---

## 📊 REAL-TIME DASHBOARD

The EA displays on chart:

```
╔════════════════════════════════════╗
║  🏛️  EA XAUUSD WALL STREET  🏛️     ║
╠════════════════════════════════════╣
║ Balance: $5,234.50
║ Equity: $5,234.50
║ Today's Profit: $234.50 / +$500
║ Today's Loss: -$10.25 / -$100
║ Accumulated Loss: -$0.00 / -$500
╠════════════════════════════════════╣
║ Open Trades: 2/3
║ Total Trades: 12
║ Win Rate: 75.0%
║ Winners: 9 | Losers: 3
╠════════════════════════════════════╣
║ Support: 2045.25
║ Resistance: 2065.75
║ Accum Zone: 2035.50
║ Dist Zone: 2075.50
╠════════════════════════════════════╣
║ Status: ✅ OPERATING
╚════════════════════════════════════╝
```

---

## ⚠️ RESTRICTIONS AND LIMITS

| Concept | Limit | Action |
|----------|--------|--------|
| **Daily Loss** | -$100 | PAUSE that day |
| **Accumulated Loss** | -$500 | DISABLE EA (GAME OVER) |
| **Daily Profit** | +$500 | CLOSE ALL that day |
| **Simultaneous Trades** | 3 maximum | Won't open more |
| **Minimum Duration** | 5 minutes | Won't close earlier |

---

## 🧪 BACKTESTING

See file: `BACKTEST_REPORT.md`

**Expected results (last 6 months XAUUSD):**
- Win Rate: 65-75%
- Profit Factor: 2.0-2.5
- Maximum Drawdown: 8-12%
- Monthly ROI: 15-25%

---

## 🔍 TROUBLESHOOTING

### EA is not opening trades
```
1. Verify symbol is XAUUSD (uppercase)
2. Verify it's within 24/7 operation hours
3. Check that it hasn't reached daily limit (-$100)
4. Verify Automated Trading is enabled
```

### Spread too high
```
1. Switch to broker with better XAUUSD spread
2. Trade during New York hours (better liquidity)
3. Use spot market instead of futures
```

### Large drawdowns
```
1. Reduce lot size from 0.01 to 0.005
2. Wait for better confluence (4-5/5 instead of 3/5)
3. Increase SL from 40 pips to 50 pips
```

---

## 📞 SUPPORT AND IMPROVEMENTS

This EA is **version 1.0 - BETA**

Planned improvements:
- [ ] Integration of additional indicators
- [ ] Machine Learning for signal prediction
- [ ] Multiple symbols (EURUSD, GBPUSD)
- [ ] Improved visual control panel
- [ ] Export reports to CSV/PDF

---

## ⚖️ DISCLAIMER

**⚠️ IMPORTANT:**

This EA is for **EDUCATIONAL AND AUTOMATED TRADING PURPOSES ONLY**.

- Forex/CFDs trading involves risk of capital loss
- Past results DO NOT guarantee future results
- Trading on a funded account involves risk of losing the account
- ALWAYS test on demo FIRST before using real money
- Maintain regular supervision of the EA

**User responsibility:** Fully understand how it works before using real money.

---

## 📄 LICENSE

MIT License - Free to use, modify, and distribute

---

**Last updated:** 2026-07-05  
**Version:** 1.0 Beta  
**Author:** Claudia Marinela  
**Based on:** Wall Street institutional principles
