//+------------------------------------------------------------------+
//|                                                       Sc41py.mq5 |
//|                                            Copyright 2023, Miles |
//|                                        https://www.tradinghub.ch |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Miles"
#property link      "https://www.tradinghub.ch"
#property version   "1.00"

// Global flags to track if trades have been opened
bool longTradeOpened = false;
bool shortTradeOpened = false;

// Add input variables
input double lotSize = 0.01;
input double takeProfit = 60.0;
input double stopLoss = 30.0;
input int RSI_Period = 14;
input double RSI_LongThreshold = 28.0;
input double RSI_ShortThreshold = 72.0;
input int MACD_FastEMA = 12;
input int MACD_SlowEMA = 26;
input int MACD_SignalPeriod = 9;
input double maxSpread = 5.0; // Spread allowed in points
input int slippage = 3; // Slippage allowed in points

input string allowedTradingStartTimeMonday = "00:00";
input string allowedTradingEndTimeMonday = "23:59";

input string allowedTradingStartTimeTuesday = "00:00";
input string allowedTradingEndTimeTuesday = "23:59";

input string allowedTradingStartTimeWednesday = "00:00";
input string allowedTradingEndTimeWednesday = "23:59";

input string allowedTradingStartTimeThursday = "00:00";
input string allowedTradingEndTimeThursday = "23:59";

input string allowedTradingStartTimeFriday = "00:00";
input string allowedTradingEndTimeFriday = "23:59";



// Add enumeration for trading modes
enum TradeMode {
    LongAndShort,
    OnlyLong,
    OnlyShort
};

// Add input variable for trade mode selection
input TradeMode tradeMode = TradeMode::LongAndShort;

// Add input variable to disable opening new trades
input bool disableNewTrades = false;

datetime TimeStringToDateTime(string timeStr)
{
    MqlDateTime mqlTime;
    TimeToStruct(TimeCurrent(), mqlTime);

    int hours, minutes;
    string hoursStr = StringSubstr(timeStr, 0, 2);
    string minutesStr = StringSubstr(timeStr, 3, 2);
    hours = int(hoursStr);
    minutes = int(minutesStr);

    mqlTime.hour = hours;
    mqlTime.min = minutes;
    mqlTime.sec = 0;

    return StructToTime(mqlTime);
}





void OnTick()
{
    // Return early if opening new trades is disabled
    if (disableNewTrades)
    {
        return;
    }

    // Check if trading is allowed based on the day of the week and time
    if (!IsTradingAllowed())
    {
        return; // Exit the function without opening trades
    }

    // Calculate the spread
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double spread = (currentAsk - currentBid) / _Point;

    // Check if the spread exceeds the maximum spread
    if (spread > maxSpread)
    {
        return; // Exit the function without opening trades
    }

    // Round the spread to 2 digits after the comma
    double roundedSpread = NormalizeDouble(spread, 2);

    double myRSIArray[];

    int myRSIDefinition = iRSI(_Symbol,_Period,RSI_Period,PRICE_CLOSE);

    ArraySetAsSeries(myRSIArray,true);

    CopyBuffer(myRSIDefinition,0,0,3,myRSIArray);

    double MYRSIValue=NormalizeDouble(myRSIArray[0],2);

    // Calculate the MACD and its signal line
    double macdArray[], signalArray[];
    ArraySetAsSeries(macdArray, true);
    ArraySetAsSeries(signalArray, true);
    int macdHandle = iMACD(_Symbol, _Period, MACD_FastEMA, MACD_SlowEMA, MACD_SignalPeriod, PRICE_CLOSE);
    CopyBuffer(macdHandle, 0, 0, 3, macdArray);
    CopyBuffer(macdHandle, 1, 0, 3, signalArray);

    double MACDValue = NormalizeDouble(macdArray[0], _Digits);
    double SignalValue = NormalizeDouble(signalArray[0], _Digits);

    // Get the current server time
    datetime serverTime = TimeCurrent();

    // Comment the rounded spread, RSI value, MACD value, Signal value, and server time on the graph
    Comment("Spread: ", roundedSpread, " points");
    Comment("myRSIValue: ", MYRSIValue);
    Comment("MACD Value: ", MACDValue);
    Comment("Signal Value: ", SignalValue);
    Comment("Server Time: ", TimeToString(serverTime, TIME_DATE | TIME_SECONDS));

    // Check if the RSI goes above RSI_ShortThreshold, no short trade is already open, and shortTradeOpened flag is false
    // Also, add the condition that the MACD value should be below the Signal value
    if (MYRSIValue > RSI_ShortThreshold && !IsTradeOpen(ORDER_TYPE_SELL) && !shortTradeOpened && (tradeMode == TradeMode::LongAndShort || tradeMode == TradeMode::OnlyShort) && MACDValue < SignalValue)
    {
        // Enter a short trade
        EnterShortTrade();
        shortTradeOpened = true;
    }
    // Check if the RSI goes below RSI_LongThreshold, no long trade is already open, and longTradeOpened flag is false
    // Also, add the condition that the MACD value should be above the Signal value
    else if (MYRSIValue < RSI_LongThreshold && !IsTradeOpen(ORDER_TYPE_BUY) && !longTradeOpened && (tradeMode == TradeMode::LongAndShort || tradeMode == TradeMode::OnlyLong) && MACDValue > SignalValue)
    {
        // Enter a long trade
        EnterLongTrade();
        longTradeOpened = true;
    }
    // Reset the longTradeOpened flag when RSI goes above the long trade threshold
    else if (MYRSIValue >= RSI_LongThreshold)
    {
        longTradeOpened = false;
    }
    // Reset the shortTradeOpened flag when RSI goes below the short trade threshold
    else if (MYRSIValue <= RSI_ShortThreshold)
    {
        shortTradeOpened = false;
    }
}

bool IsTradingAllowed()
{
    // Get the current server time
    datetime currentServerTime = TimeCurrent();
    MqlDateTime mqlTime;
    TimeToStruct(currentServerTime, mqlTime);

    // Get the allowed trading start and end times for the current day of the week
    string allowedStartStr, allowedEndStr;
    switch (mqlTime.day_of_week)
    {
        case 1: // Monday
            allowedStartStr = allowedTradingStartTimeMonday;
            allowedEndStr = allowedTradingEndTimeMonday;
            break;
        case 2: // Tuesday
            allowedStartStr = allowedTradingStartTimeTuesday;
            allowedEndStr = allowedTradingEndTimeTuesday;
            break;
        case 3: // Wednesday
            allowedStartStr = allowedTradingStartTimeWednesday;
            allowedEndStr = allowedTradingEndTimeWednesday;
            break;
        case 4: // Thursday
            allowedStartStr = allowedTradingStartTimeThursday;
            allowedEndStr = allowedTradingEndTimeThursday;
            break;
        case 5: // Friday
            allowedStartStr = allowedTradingStartTimeFriday;
            allowedEndStr = allowedTradingEndTimeFriday;
            break;
        default: // Saturday and Sunday
            return false;
    }

    // Convert allowed trading start and end times to datetime objects
    datetime allowedStart = TimeStringToDateTime(allowedStartStr);
    datetime allowedEnd = TimeStringToDateTime(allowedEndStr);

    // Check if trading is allowed within the specified time range
    if (currentServerTime >= allowedStart && currentServerTime <= allowedEnd)
    {
        return true;
    }

    return false;
}



bool IsTradeOpen(ENUM_ORDER_TYPE orderType)
{
    for (int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        string symbol = PositionGetString(POSITION_SYMBOL);
        ENUM_ORDER_TYPE positionType = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
       
        if (symbol == _Symbol && positionType == orderType)
        {
            return true;
        }
    }

    return false;
}

void EnterLongTrade()
{
    // Trade parameters
    double tradeVolume = lotSize;
    // Use input variable for slippage
    int allowedSlippage = slippage;

    // Get the current Bid and Ask prices
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    // Calculate Stop Loss and Take Profit levels
    double calculatedStopLoss = currentAsk - stopLoss * _Point;
    double calculatedTakeProfit = currentAsk + takeProfit * _Point;

    // Create a trade request
    MqlTradeRequest tradeRequest;
    ZeroMemory(tradeRequest);

    tradeRequest.action = TRADE_ACTION_DEAL;
    tradeRequest.symbol = _Symbol;
    tradeRequest.volume = tradeVolume;
    tradeRequest.type = ORDER_TYPE_BUY;
    tradeRequest.price = currentAsk;
    tradeRequest.sl = calculatedStopLoss;
    tradeRequest.tp = calculatedTakeProfit;
    tradeRequest.deviation = allowedSlippage;
    tradeRequest.type_filling = ORDER_FILLING_FOK;
    tradeRequest.type_time = ORDER_TIME_GTC;
    tradeRequest.comment = "LongTrade";

    // Execute the trade request
    MqlTradeResult tradeResult;
    ZeroMemory(tradeResult);

    int tradeResultStatus = OrderSend(tradeRequest, tradeResult);

    // Check for errors
    if (tradeResult.retcode != TRADE_RETCODE_DONE)
    {
        Print("Error opening long trade: ", tradeResult.retcode);
    }
    else
    {
        Print("Long trade opened successfully: ", tradeResult.order);
    }
}


void EnterShortTrade()
{
    // Trade parameters
    double tradeVolume = lotSize;
    // Use input variable for slippage
    int allowedSlippage = slippage;

    // Get the current Bid and Ask prices
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    // Calculate Stop Loss and Take Profit levels
    double calculatedStopLoss = currentBid + stopLoss * _Point;
    double calculatedTakeProfit = currentBid - takeProfit * _Point;

    // Create a trade request
    MqlTradeRequest tradeRequest;
    ZeroMemory(tradeRequest);

    tradeRequest.action = TRADE_ACTION_DEAL;
    tradeRequest.symbol = _Symbol;
    tradeRequest.volume = tradeVolume;
    tradeRequest.type = ORDER_TYPE_SELL;
    tradeRequest.price = currentBid;
    tradeRequest.sl = calculatedStopLoss;
    tradeRequest.tp = calculatedTakeProfit;
    tradeRequest.deviation = allowedSlippage;
    tradeRequest.type_filling = ORDER_FILLING_FOK;
    tradeRequest.type_time = ORDER_TIME_GTC;
    tradeRequest.comment = "ShortTrade";

    // Execute the trade request
    MqlTradeResult tradeResult;
    ZeroMemory(tradeResult);

    int tradeResultStatus = OrderSend(tradeRequest, tradeResult);

    // Check for errors
    if (tradeResult.retcode != TRADE_RETCODE_DONE)
    {
        Print("Error opening short trade: ", tradeResult.retcode);
    }
    else
    {
        Print("Short trade opened successfully: ", tradeResult.order);
    }
}
