#include <Trade/Trade.mqh>

enum ENUM_TRADE_TYPE {
   TRADE_LONG_ONLY,
   TRADE_SHORT_ONLY,
   TRADE_BOTH
};


input double Lots = 0.1;
input int TpPoints = 100;
input int SlPoints = 200;
input int TslPoints = 20;
input int TslTriggerPoints = 50;

input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input int DCCandles = 20;
input int Magic = 111;
input string OrderComment = "donchian Scalper";
input ENUM_TRADE_TYPE TradeType = TRADE_BOTH;

CTrade trade;

int barsTotal;


int OnInit(){
   barsTotal = iBars(_Symbol,Timeframe);
   trade.SetExpertMagicNumber(Magic);
   

   return(INIT_SUCCEEDED);
 
}

void OnDeinit(const int reason){

}

void OnTick() {

   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   ulong buyPos = 0;
   ulong sellPos = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--){
      ulong posTicket = PositionGetTicket(i);
      if(PositionSelectByTicket(posTicket)){
         if(PositionGetInteger(POSITION_MAGIC) == Magic){
            double posPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
            double posTp = PositionGetDouble(POSITION_TP);
            double posSl = PositionGetDouble(POSITION_SL);
            
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
               buyPos = posTicket;
               
               if(bid > posPriceOpen + TslTriggerPoints * _Point){
                  double sl = bid - TslPoints * _Point;
                  sl = NormalizeDouble(sl,_Digits);
                  
                  if(sl > posSl){
                     trade.PositionModify(posTicket,sl,posTp);
                  }
               }
            }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
               sellPos = posTicket;
               
               if(ask < posPriceOpen - TslTriggerPoints * _Point){
                  double sl = ask + TslPoints * _Point;
                  sl = NormalizeDouble(sl,_Digits);
                  
                  if(sl < posSl || posSl == 0){
                     trade.PositionModify(posTicket,sl,posTp);
                  }
               }
            }
         }
      } 
   }

   int bars = iBars(_Symbol,Timeframe);
   if(barsTotal != bars){
      barsTotal = bars;
   
      int indexHighest = iHighest(_Symbol,Timeframe,MODE_HIGH,DCCandles);
      int indexLowest = iLowest(_Symbol,Timeframe,MODE_LOW,DCCandles);
   
      double high = iHigh(_Symbol,Timeframe,indexHighest);
      double low = iLow(_Symbol,Timeframe,indexLowest);
      double middle = low + (high - low) / 2;   

      ulong buyOrder = 0;
      ulong sellOrder = 0;
      bool isBuyOrderUpdate = false;
      bool isSellOrderUpdate = false;
      for(int i = OrdersTotal()-1; i >= 0; i--){
         ulong orderTicket = OrderGetTicket(i);
         if(OrderSelect(orderTicket)){
            if(OrderGetInteger(ORDER_MAGIC) == Magic){
               double orderPriceOpen = OrderGetDouble(ORDER_PRICE_OPEN);
               
               if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP){
                  if(high < orderPriceOpen){
                     if(trade.OrderDelete(orderTicket)){
                        isBuyOrderUpdate = true;
                     }
                  }else{
                     buyOrder = orderTicket;
                  }
               }else if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP){
                  if(low > orderPriceOpen){
                     if(trade.OrderDelete(orderTicket)){
                        isSellOrderUpdate = true;
                     }
                  }else{
                     sellOrder = orderTicket;
                  }
               }
            }
         }
      }
      
     
      if((bid < middle || isBuyOrderUpdate) && buyOrder == 0 && buyPos <= 0 && (TradeType == TRADE_LONG_ONLY || TradeType == TRADE_BOTH)){
         double tp = high + TpPoints * _Point;
         tp = NormalizeDouble(tp,_Digits);
         double sl = high - SlPoints * _Point;
         sl = NormalizeDouble(sl,_Digits);
   
         if(trade.BuyStop(Lots,high,_Symbol,sl,tp,ORDER_TIME_GTC,0,OrderComment)){
            buyOrder = trade.ResultOrder();
         }
      }else if((bid > middle || isSellOrderUpdate) && sellOrder == 0 && sellPos <= 0 && (TradeType == TRADE_SHORT_ONLY || TradeType == TRADE_BOTH)){
         double tp = low - TpPoints * _Point;
         tp = NormalizeDouble(tp,_Digits);
         double sl = low + SlPoints * _Point;
         sl = NormalizeDouble(sl,_Digits);
   
         if(trade.SellStop(Lots,low,_Symbol,sl,tp,ORDER_TIME_GTC,0,OrderComment)){
            sellOrder = trade.ResultOrder();
         }
      }
      
      Comment("\nHigh: ",DoubleToString(high,_Digits)," (index; ",indexHighest,")",
            "\nLow: ",DoubleToString(low,_Digits)," (index: ",indexLowest,")",
            "\nBuy Order: ",buyOrder,
            "\nSell Order: ",sellOrder,
            "\nBuy Pos: ",buyPos,
            "\nSell Pos: ",sellPos);
   }
}
