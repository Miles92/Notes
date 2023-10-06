#include <Trade/Trade.mqh>

input double Lots = 0.01;
input double LotMultiplier = 2.0; // Multiplier for the lot size
input int MultiplierStartLevel = 3; // Level at which the multiplier starts affecting the lot size
input int MaxAllowedLevels = 10; // Max number of allowed levels


input ENUM_TIMEFRAMES RsiTimeFrame = PERIOD_H1;
input int RsiPeriods = 14;
input ENUM_APPLIED_PRICE RsiAppPrice = PRICE_CLOSE;
input double RsiSellTrigger = 70;
input double RsiBuyTrigger = 30;

input int TpPoints = 200;

int handleRsi;
double rsi[];
CTrade trade;

int barsTotal;

// Global variables to track the number of long and short trades
int longCounter = 0;
int shortCounter = 0;

int OnInit(){
   handleRsi = iRSI(_Symbol,RsiTimeFrame,RsiPeriods,RsiAppPrice);

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
  {
   
  }
  

void OnTick() {
    int bars = iBars(_Symbol, RsiTimeFrame);
    if (barsTotal != bars) {
        barsTotal = bars;
        
        CopyBuffer(handleRsi, MAIN_LINE, 1, 2, rsi);
        
        int longCounter = 0;
        int shortCounter = 0;
        
        // Count open positions
        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong posTicket = PositionGetTicket(i);
            if (PositionSelectByTicket(posTicket)) {
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                
                if (posType == POSITION_TYPE_BUY) {
                    longCounter++;
                } else if (posType == POSITION_TYPE_SELL) {
                    shortCounter++;
                }
            }
        }
        
           double currentLotSize = Lots;
           
         if (longCounter < MaxAllowedLevels) {  
           if (longCounter >= MultiplierStartLevel) {
               currentLotSize *= LotMultiplier;
           }
           if (rsi[1] < RsiBuyTrigger && rsi[0] > RsiBuyTrigger) {
               trade.Buy(currentLotSize);
           }
         }  
           currentLotSize = Lots;
         if (shortCounter < MaxAllowedLevels) {  
           if (shortCounter >= MultiplierStartLevel) {
               currentLotSize *= LotMultiplier;
           }
           if (rsi[1] > RsiSellTrigger && rsi[0] < RsiSellTrigger) {
               trade.Sell(currentLotSize);
           }
         }
    }
   
   int pointsBuy = 0;
   int pointsSell = 0;
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong posTicket = PositionGetTicket(i);
      
      if (PositionSelectByTicket(posTicket)) {
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         
         if (posType == POSITION_TYPE_BUY) {
            pointsBuy += (int)((bid - posOpenPrice) / _Point);
            longCounter++;
         } else if (posType == POSITION_TYPE_SELL) {
            pointsSell += (int)((posOpenPrice - ask) / _Point);
            shortCounter++;
         }
      }
   }
   
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong posTicket = PositionGetTicket(i);
      
      if (PositionSelectByTicket(posTicket)) {
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         
         if (pointsBuy > TpPoints) {
            if (posType == POSITION_TYPE_BUY) {
               trade.PositionClose(posTicket);
            }
         }
         
         if (pointsSell > TpPoints) {
            if (posType == POSITION_TYPE_SELL) {
               trade.PositionClose(posTicket);
            }
         }
      }
   }
   
   Comment("\nRSI[0]: ", DoubleToString(rsi[0], 5),
           "\nRSI[1]: ", DoubleToString(rsi[1], 5),
           "\nPoints Buy: ", pointsBuy,
           "\nPoints Sell: ", pointsSell,
           "\nLong Trades Open: ", longCounter,
           "\nShort Trades Open: ", shortCounter,
           "\nCurrent Long Level: ", (longCounter >= MultiplierStartLevel) ? "Multiplier Applied" : "Normal",
           "\nCurrent Short Level: ", (shortCounter >= MultiplierStartLevel) ? "Multiplier Applied" : "Normal");
}
