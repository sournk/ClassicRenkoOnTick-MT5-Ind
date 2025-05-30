//+------------------------------------------------------------------+
//|                                   ClassicRenkoOnTick-MT5-Ind.mq5 |
//+------------------------------------------------------------------+

#property copyright   "Denis Kislitsyn"
#property link        "https://kislitsyn.me/peronal/algo"
#property description "Classic Renko Indicator updating on every single tick"
#property description "1.06: [+] 'Renko Type': Classic or Offset"
#property description "1.05: [+] 'Bar Limit Count' for performance (0-off)"
#property description "1.04: [+] Warning label about axis X is virtual"
#property description "1.03: [*] Human-readable time buffers splitted to date, time and ms"
#property description "1.02: [*] Two new buffers with time stamp representation in human-readable format"
#property description "1.01: [*] 'History Depth, sec' can be 0 for no history load on start"
#property version     "1.06"
#property icon        "img\\logo\\logo_64.ico"
#property strict

#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   6

#property indicator_label1   "Renko Open;Renko High;Renko Low;Renko Close"
#property indicator_type1    DRAW_COLOR_CANDLES
#property indicator_color1   clrGreen, clrRed

#property indicator_label2   "Renko Start TimeStamp"
#property indicator_type2    DRAW_NONE
#property indicator_color2   clrRed

#property indicator_label3   "Renko Duration, ms"
#property indicator_type3    DRAW_NONE
#property indicator_color3   clrRed

#property indicator_label4   "Renko Start Human Date"
#property indicator_type4    DRAW_NONE
#property indicator_color4   clrRed

#property indicator_label5   "Renko Start Human Time"
#property indicator_type5    DRAW_NONE
#property indicator_color5   clrRed

#property indicator_label6   "Renko Start Human MS"
#property indicator_type6    DRAW_NONE
#property indicator_color6   clrRed


#include <ChartObjects\ChartObjectsTxtControls.mqh>

enum ENUM_PRICE_SOURCE {
  PRICE_SOURCE_ASK = 0, // Ask
  PRICE_SOURCE_BID = 1, // Bid
};


//  Classic           Offset
//   ↑↓    ↑           ↑   ↑
//  ↑  ↓  ↑           ↑ ↓ ↑
// ↑    ↓↑           ↑   ↓
enum ENUM_RENKO_TYPE {
  RENKO_TYPE_CLASSIC = 0, // Classic
  RENKO_TYPE_OFFSET = 1, // Offset
};

input   uint                BrickSizePoints = 20.0;               // Brick Size, pnt
input   ENUM_PRICE_SOURCE   PriceSource     = PRICE_SOURCE_BID;   // Price Source
input   ENUM_RENKO_TYPE     RenkoType       = RENKO_TYPE_CLASSIC; // Renko Type
sinput  uint                HistoryDepthSec = 3600;               // Initial History Depth, sec
sinput  uint                BarLimitCnt     = 100;                // Bar Limit Count for performance (0-off)
sinput  bool                ShowWarning     = true;               // Show Warning

// buffer
double OpenBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];
double ColorBuffer[];
double TimeBuffer[];
double TimeDurBuffer[];
double HumanDateBuffer[];
double HumanTimeBuffer[];
double HumanMSBuffer[];

double brickSize;
double lastClose;
long   lastTime;
int    lastRateIdx;
int    lastRenkoCnt;

struct RenkoBar {
  int    index;
  double open;
  double close;
  long   start_time;
  long   span_ms;
  int    dir;
};

RenkoBar renkoSeries[];

void CreateWarningLabel() {
  // Add warning labels  
  int sub_window = ChartWindowFind();
  ObjectsDeleteAll(0, "LBL_WANINIG_", sub_window);
  
  if(!ShowWarning) return;
    
  CChartObjectLabel label;
  label.Create(0, "LBL_WANINIG_H1", sub_window, 10, 20);
  label.Description("WARNING:");
  label.Detach();
  
  label.Create(0, "LBL_WANINIG_P1", sub_window, 10, 35);
  label.Description("1. The X axis of Renko subwindow is virtual");
  label.Detach();
  
  label.Create(0, "LBL_WANINIG_P2", sub_window, 10, 50);
  label.Description("2. Real time of Renko bars is available ONLY in buffers");
  label.Detach();
}

int OnInit() {
  if(BrickSizePoints <= 0) {
    Print("'Brick Size, pnt' must be a positive value");
    return(INIT_PARAMETERS_INCORRECT);
  }
  
  CreateWarningLabel();
  
  // Init bufs  
  SetIndexBuffer(0, OpenBuffer, INDICATOR_DATA);
  SetIndexBuffer(1, HighBuffer, INDICATOR_DATA);
  SetIndexBuffer(2, LowBuffer, INDICATOR_DATA);
  SetIndexBuffer(3, CloseBuffer, INDICATOR_DATA);
  SetIndexBuffer(4, ColorBuffer, INDICATOR_COLOR_INDEX);
  SetIndexBuffer(5, TimeBuffer, INDICATOR_DATA);
  SetIndexBuffer(6, TimeDurBuffer, INDICATOR_DATA);  
  SetIndexBuffer(7, HumanDateBuffer, INDICATOR_DATA);  
  SetIndexBuffer(8, HumanTimeBuffer, INDICATOR_DATA);  
  SetIndexBuffer(9, HumanMSBuffer, INDICATOR_DATA);  

  ArraySetAsSeries(OpenBuffer, false);
  ArraySetAsSeries(HighBuffer, false);
  ArraySetAsSeries(LowBuffer, false);
  ArraySetAsSeries(CloseBuffer, false);
  ArraySetAsSeries(ColorBuffer, false);
  ArraySetAsSeries(TimeBuffer, false);
  ArraySetAsSeries(TimeDurBuffer, false);
  ArraySetAsSeries(HumanDateBuffer, false);
  ArraySetAsSeries(HumanTimeBuffer, false);
  ArraySetAsSeries(HumanMSBuffer, false);

  brickSize = BrickSizePoints * _Point;
  IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
  IndicatorSetString(INDICATOR_SHORTNAME, "Renko(" + IntegerToString(BrickSizePoints) + "; " + IntegerToString(HistoryDepthSec) + ")");

  lastClose = 0;
  lastTime = 0;
  lastRateIdx = -1;
  lastRenkoCnt = -1;
  ArrayFree(renkoSeries);

  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Return price
//+------------------------------------------------------------------+
double GetPriceFromTick(MqlTick& _tick) {
  return (PriceSource == PRICE_SOURCE_BID) ? _tick.bid : _tick.ask;
}

//+------------------------------------------------------------------+
//| Init History
//+------------------------------------------------------------------+
void InitHistory() {
  if(HistoryDepthSec <= 0) return;
  
  MqlTick ticks[];
  datetime fromTime = TimeCurrent() - HistoryDepthSec;
  ulong fromMs = (ulong)fromTime * 1000;
  ulong toMs   = (ulong)TimeCurrent() * 1000;
  if(CopyTicksRange(_Symbol, ticks, COPY_TICKS_ALL, fromMs, toMs) <= 0) {
    Print("Failed to load ticks history");
    return;
  }
  
  lastClose = GetPriceFromTick(ticks[0]);
  lastTime = ticks[0].time_msc;
  for (int i = 1; i < ArraySize(ticks); i++) 
    AddTick(GetPriceFromTick(ticks[i]), ticks[i].time_msc);
}

//+------------------------------------------------------------------+
//| Proccess tick and build new Renko bars if needed
//+------------------------------------------------------------------+
void AddTick(double price, ulong tickTimeMs) {
  double diff = price - lastClose;
  int bricks = (int)MathFloor(MathAbs(diff) / brickSize);
  if (bricks > 0) 
    for(int j=0; j<bricks; j++) {
      RenkoBar bar;
      bar.index = ArraySize(renkoSeries);
      bar.open = lastClose; //(bar.index == 0) ? lastClose : renkoSeries[bar.index - 1].close;
      bar.close = (diff > 0) ? (bar.open + brickSize) : (bar.open - brickSize);
      bar.start_time = lastTime;
      bar.span_ms = (long)(tickTimeMs - lastTime);
      bar.dir = bar.close > bar.open ? +1 : -1;

      lastClose = lastClose + ((diff > 0) ? brickSize : -brickSize);
      
      // For offset mode skip new opposite bar which fills prev bar movement
      //  Classic           Offset
      //   ↑↓    ↑           ↑   ↑
      //  ↑  ↓  ↑           ↑ ↓ ↑
      // ↑    ↓↑           ↑   ↓
      if(RenkoType == RENKO_TYPE_OFFSET && ArraySize(renkoSeries) > 0) {
        RenkoBar bar_prev = renkoSeries[ArraySize(renkoSeries)-1];
        if(bar.close >= MathMin(bar_prev.open, bar_prev.close) &&
           bar.close <= MathMax(bar_prev.open, bar_prev.close))
          continue; 
      }

      lastTime = (long)tickTimeMs;            
      int size = ArraySize(renkoSeries);
      ArrayResize(renkoSeries, size + 1);
      renkoSeries[size] = bar;
    }
    
  // Delete bars over limit
  if(BarLimitCnt <= 0) return;
  
  while(ArraySize(renkoSeries) > (int)BarLimitCnt) 
    ArrayRemove(renkoSeries, 0, 1);
}

//+------------------------------------------------------------------+
//| On Calculate
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
                
  // 01. Fill buffers with EMPTY_VALUE
  if(prev_calculated < rates_total) {
    int start = MathMax(0, prev_calculated-ArraySize(renkoSeries)); // Also fill EMPTY_VALUE for prev Renko bars to full redraw
    int cnt = rates_total-start;
    ArrayFill(OpenBuffer,        start, cnt, EMPTY_VALUE);
    ArrayFill(CloseBuffer,       start, cnt, EMPTY_VALUE);
    ArrayFill(HighBuffer,        start, cnt, EMPTY_VALUE);
    ArrayFill(LowBuffer,         start, cnt, EMPTY_VALUE);
    ArrayFill(ColorBuffer,       start, cnt, EMPTY_VALUE);
    ArrayFill(TimeBuffer,        start, cnt, EMPTY_VALUE);
    ArrayFill(TimeDurBuffer,     start, cnt, EMPTY_VALUE);
    ArrayFill(HumanDateBuffer,   start, cnt, EMPTY_VALUE);
    ArrayFill(HumanTimeBuffer,   start, cnt, EMPTY_VALUE);
    ArrayFill(HumanMSBuffer,     start, cnt, EMPTY_VALUE);
  }
                
  // 02. Load Renko from history ticks
  if(prev_calculated == 0) InitHistory();
  
  // 03. Proccess current tick
  MqlTick tick;
  if(SymbolInfoTick(_Symbol, tick)) {
    // Init lastClose and lastTime if it's not done when loading history
    if(lastClose <= 0) {
      lastClose = GetPriceFromTick(tick);
      lastTime = tick.time_msc;
    }
    AddTick(GetPriceFromTick(tick), tick.time_msc);
  }
  int count = ArraySize(renkoSeries);
    
  // 04. Speed optimisation: Don't update buffers if no new Rekno bar added or no new bar added
  if(lastRateIdx == rates_total && lastRenkoCnt == count)
    return rates_total;
  lastRateIdx = rates_total;
  lastRenkoCnt = count;    
    
  // 05. Update indicator buffers
  int bufferIdx = rates_total - 1;
  for(int i=count-1; i>=0; i--) {
    if(bufferIdx < 0) break;
    double open = renkoSeries[i].open;
    double close = renkoSeries[i].close;
    OpenBuffer[bufferIdx]  = open;
    CloseBuffer[bufferIdx] = close;
    HighBuffer[bufferIdx]  = MathMax(open, close);
    LowBuffer[bufferIdx]   = MathMin(open, close);
    ColorBuffer[bufferIdx] = (close > open) ? 0 : 1;
    TimeBuffer[bufferIdx] = (double)renkoSeries[i].start_time;
    TimeDurBuffer[bufferIdx] = (double)renkoSeries[i].span_ms;
    HumanDateBuffer[bufferIdx] = DateToHuman(renkoSeries[i].start_time);
    HumanTimeBuffer[bufferIdx] = TimeToHuman(renkoSeries[i].start_time);
    HumanMSBuffer[bufferIdx] = double(renkoSeries[i].start_time % 1000);
    bufferIdx--;
  }
  
  return rates_total;
}

double DateToHuman(long _dt_msc){
  datetime dt = (datetime)(_dt_msc / 1000);
  string str = TimeToString(dt, TIME_DATE);
  StringReplace(str, ".", "");
  double res = (double)str;
  return res;
}

double TimeToHuman(long _dt_msc){
  datetime dt = (datetime)(_dt_msc / 1000);
  string str = TimeToString(dt, TIME_MINUTES | TIME_SECONDS);
  StringReplace(str, ":", "");
  double res = (double)str;
  return res;
}
//+------------------------------------------------------------------+
