# 🏛️ EA XAUUSD FONDEO $5K - Wall Street Level

**Expert Advisor automatizado para XAUUSD (Oro)**  
Diseñado para operaciones de fondeo con gestión de riesgo institucional

---

## 📊 DESCRIPCIÓN GENERAL

Este EA está diseñado para operar **XAUUSD** en una cuenta de fondeo de **$5,000** con reglas estrictas de gestión de riesgo al nivel de Wall Street.

### 🎯 Objetivos
- **Fase 1:** Ganar $500 (10% ROI) en 5 días máximo
- **Pérdida máxima diaria:** -$100 (STOP)
- **Pérdida máxima cuenta:** -$500 (GAME OVER)
- **Ganancia máxima diaria:** +$500 (CIERRA TODO)

---

## 🔧 CARACTERÍSTICAS

✅ **Operación 24/7**
- Asia (20:00-04:00 GMT)
- Londres (08:00-17:00 GMT)
- Nueva York (13:00-21:00 GMT)

✅ **Estrategia Confluence (Smart Money)**
- RSI + MACD + Bollinger Bands + ATR + Smart Money Levels
- Requiere mínimo 3/5 confirmaciones para entrada

✅ **Gestión Dinámica**
- Break Even automático (+50 pips)
- Trailing Stop (+100 pips)
- Re-entries escalonadas

✅ **Sin Scalping**
- Duración mínima de trades: 5 minutos
- Diseñado para operaciones de mediano plazo

✅ **Estadísticas en Tiempo Real**
- Dashboard con P&L, Win Rate, niveles institucionales
- Registro completo de trades

---

## 📈 PARÁMETROS PRINCIPALES

```
INDICADOR          PARÁMETRO        DESCRIPCIÓN
─────────────────────────────────────────────────
RSI                14               Período de RSI
MACD               12,26,9          Fast, Slow, Signal
Bollinger Bands    20, 2.0          Período y desviación
ATR                14               Período de ATR
Duración Mínima    5 minutos        Timeframe M5

GESTIÓN DE RIESGO
─────────────────────────────────────────────────
Lotaje Inicial     0.01             Micro lote
TP Diario          $500             Máxima ganancia
SL Diario          -$100            Máxima pérdida
Pérdida Cuenta     -$500            Total permitido
Trades Máximo      3 simultáneos
```

---

## 🚀 INSTALACIÓN

1. **Descargar el archivo EA**
   ```
   EA_XAUUSD_Fondeo.mq5
   ```

2. **Copiar a carpeta de MT5**
   ```
   C:\Users\[Usuario]\AppData\Roaming\MetaTrader 5\MQL5\Experts\
   ```

3. **Compilar el EA**
   - Abrir MetaEditor
   - Ir a: File → Open → EA_XAUUSD_Fondeo.mq5
   - Presionar F7 (Compilar)

4. **Cargar en MT5**
   - Abrir MT5
   - Ir a: Symbols → XAUUSD
   - Timeframe: M5 (5 minutos)
   - Arrastrar EA desde Navigator → XAUUSD
   - Habilitar Automated Trading

---

## ⚙️ CONFIGURACIÓN

### Cuenta Requerida
- **Broker:** Cualquiera que ofrezca XAUUSD (ICMarkets, Exness, etc.)
- **Tipo:** Micro o Mini lotes (lotaje 0.01)
- **Apalancamiento:** 1:50 mínimo
- **Spread XAUUSD:** < 0.50 pips (recomendado)

### Ajustes Recomendados en MT5
1. **Tools → Options → Expert Advisors**
   - ✅ Enable Automated Trading
   - ✅ Allow live trading
   - ✅ Allow DLL imports

2. **Chart Settings**
   - Timeframe: M5
   - Symbol: XAUUSD
   - Detach from chart: NO (para ver estadísticas)

---

## 📊 CÓMO FUNCIONA

### Flujo de Operación

```
1. CALCULAR NIVELES INSTITUCIONALES
   ↓
2. ESPERAR HORARIO DE OPERACIÓN 24/7
   ↓
3. ESCANEAR SEÑALES CONFLUENCE (3/5 confirmaciones)
   ↓
4. ABRIR TRADE CON SL + TP
   ↓
5. GESTIONAR CON BREAK EVEN + TRAILING STOP
   ↓
6. CERRAR POR TP O SL
   ↓
7. RE-ENTRY ESCALONADA SI CONDICIONES
   ↓
8. VERIFICAR LÍMITES DIARIOS/ACUMULADOS
```

### Señales de Entrada

**COMPRA (BUY) - Confluence ≥ 3/5:**
```
✅ RSI < 30 (Oversold)
✅ MACD Bullish Crossover
✅ Precio cerca de Bollinger Lower Band
✅ ATR en rango 0.5-3.0
✅ En zona de acumulación O rebote de soporte
```

**VENTA (SELL) - Confluence ≥ 3/5:**
```
✅ RSI > 70 (Overbought)
✅ MACD Bearish Crossover
✅ Precio cerca de Bollinger Upper Band
✅ ATR en rango 0.5-3.0
✅ En zona de distribución O rebote de resistencia
```

---

## 💰 GESTIÓN DE RIESGO

### Niveles Institucionales (Smart Money)

El EA calcula automáticamente:

```
Pivot Point (PP)           = (High24h + Low24h + Close) / 3
Resistencia Principal      = PP + (Rango × 0.618)
Soporte Principal          = PP - (Rango × 0.618)
Zona de Acumulación        = Soporte - (Rango × 0.382)
Zona de Distribución       = Resistencia + (Rango × 0.382)
```

Estos niveles se actualizan diariamente y se muestran en el dashboard.

### Break Even Dinámico

```
Después de +50 pips:       SL se mueve a precio de entrada (protege ganancias)
Después de +100 pips:      Trailing Stop activado (SL sigue -50 pips)
```

### Re-entries Escalonadas

```
Si ganancia > +50 pips:    Abrir segunda posición (lote 0.005)
Máximo 3 trades abiertos:  Limita exposición
```

---

## 📊 DASHBOARD EN TIEMPO REAL

El EA muestra en chart:

```
╔════════════════════════════════════╗
║  🏛️  EA XAUUSD WALL STREET  🏛️     ║
╠════════════════════════════════════╣
║ Balance: $5,234.50
║ Equity: $5,234.50
║ Ganancia Hoy: $234.50 / +$500
║ Pérdida Hoy: -$10.25 / -$100
║ Pérdida Acumulada: -$0.00 / -$500
╠════════════════════════════════════╣
║ Trades Abiertos: 2/3
║ Total Trades: 12
║ Win Rate: 75.0%
║ Ganadores: 9 | Perdedores: 3
╠════════════════════════════════════╣
║ Soporte: 2045.25
║ Resistencia: 2065.75
║ Zona Acum: 2035.50
║ Zona Dist: 2075.50
╠════════════════════════════════════╣
║ Estado: ✅ OPERANDO
╚════════════════════════════════════╝
```

---

## ⚠️ RESTRICCIONES Y LÍMITES

| Concepto | Límite | Acción |
|----------|--------|--------|
| **Pérdida Diaria** | -$100 | PAUSA ese día |
| **Pérdida Acumulada** | -$500 | DESACTIVA EA (GAME OVER) |
| **Ganancia Diaria** | +$500 | CIERRA TODO ese día |
| **Trades Simultáneos** | 3 máximo | No abre más |
| **Duración Mínima** | 5 minutos | No cierra antes |

---

## 🧪 BACKTESTING

Ver archivo: `BACKTEST_REPORT.md`

**Resultados esperados (últimos 6 meses XAUUSD):**
- Win Rate: 65-75%
- Profit Factor: 2.0-2.5
- Drawdown Máximo: 8-12%
- ROI Mensual: 15-25%

---

## 🔍 TROUBLESHOOTING

### El EA no abre trades
```
1. Verificar que el símbolo sea XAUUSD (mayúsculas)
2. Verificar que esté en horario de operación 24/7
3. Revisar que no haya alcanzado límite diario (-$100)
4. Verificar que Automated Trading esté habilitado
```

### Spread muy alto
```
1. Cambiar a broker con mejor spread XAUUSD
2. Operar en horario Nueva York (mejor liqudez)
3. Usar mercado spot en lugar de futuros
```

### Draws muy grandes
```
1. Reducir lotaje de 0.01 a 0.005
2. Esperar mejor confluence (4-5/5 en lugar de 3/5)
3. Aumentar SL de 40 pips a 50 pips
```

---

## 📞 SOPORTE Y MEJORAS

Este EA es **versión 1.0 - BETA**

Mejoras planificadas:
- [ ] Integración de indicadores adicionales
- [ ] Machine Learning para predicción de señales
- [ ] Múltiples símbolos (EURUSD, GBPUSD)
- [ ] Panel de control visual mejorado
- [ ] Exportar reportes a CSV/PDF

---

## ⚖️ DISCLAIMER

**⚠️ IMPORTANTE:**

Este EA es para **FINES EDUCATIVOS Y DE TRADING AUTOMATIZADO**. 

- Trading de Forex/CFDs implica riesgo de pérdida de capital
- Resultados pasados NO garantizan resultados futuros
- Operar en cuenta de fondeo implica riesgo de perder la cuenta
- Use SIEMPRE en demo PRIMERO antes de real
- Mantener supervisión regular del EA

**Responsabilidad del usuario:** Comprender completamente cómo funciona antes de usar dinero real.

---

## 📄 LICENCIA

MIT License - Libre para usar, modificar y distribuir

---

**Última actualización:** 2026-06-04  
**Versión:** 1.0 Beta  
**Autor:** Claudia Marinela  
**Basado en:** Principios institucionales de Wall Street
