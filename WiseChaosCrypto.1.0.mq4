//+------------------------------------------------------------------+
//|                                               WiseChaosCrypto.1.0 |
//|                                                  Mario Lucangeli |
//|                                         https://www.lucangeli.it |
//+------------------------------------------------------------------+
#property copyright "Mario Lucangeli"
#property link      "https://www.lucangeli.it"
#property version   "1.00"
#property strict

//--- input parameters

input int shiftAB=10; // shiftAB apertura ordine in Ask/Bid
input int FractalLimit=7; // limiteFrattali

input bool UseWiseChaosCrypto=true;

input double lotSize=0.01; // Dimensione Ordine
input int magic=03052021; // magic number
string volumeString="";
double stoploss=0;
datetime expiry = TimeCurrent();

string volumeString3s="WiseChaosCrypto SHORT";
string volumeString3l="WiseChaosCrypto LONG";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int BarsToScan=100;                                //Bars To Scan (10=Last Ten Candles)
input bool EnableTrailingParam=true;                    //Enable Trailing Stop
int OrderOpRetry=5;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   static datetime candletime=0;
   if(candletime!=Time[0])
     {
     // expiry=TimeCurrent()+PeriodSeconds(PERIOD_CURRENT);
      if(UseWiseChaosCrypto==true)
         WiseChaosCrypto();
      if(BearishDivergent(1)==true)
         closeReverse(OP_SELL);
      if(BullishDivergent(1)==true)
         closeReverse(OP_BUY);
      if(EnableTrailingParam)
         fractalTrailingStop();
      candletime=Time[0];
     }
//---
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WiseChaosCrypto()
  {
   double
   jaws=iAlligator(Symbol(),0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_GATORJAW,1),
   teeth=iAlligator(Symbol(),0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_GATORTEETH,1),// punto denti dell'allogatore linea rossa
   lips=iAlligator(Symbol(),0,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN,MODE_GATORLIPS,1);

//For loop to scan the last limiteFrattali candles starting from the oldest and finishing with the most recent
   for(int i=FractalLimit; i>=0; i--)
     {
      //If there is a fractal on the candle the value will be greater than zero and equal to the highest or lowest price
      double fractalUp=iFractals(Symbol(),PERIOD_CURRENT,MODE_UPPER,i);
      double fractalDown=iFractals(Symbol(),PERIOD_CURRENT,MODE_LOWER,i);
      //If there is an upper fractal I store the value and set true the FractalsUp variable

      //--- PARAMETRI ORDINE
      expiry=TimeCurrent()+PeriodSeconds(PERIOD_CURRENT);
      double
      highBarPrice=iHigh(Symbol(),PERIOD_CURRENT,1), // prezzo più alto del periodo corrente
      lowBarPrice=iLow(Symbol(),PERIOD_CURRENT,1), // prezzo più basso del periodo corrente

      openLevelBuy=fractalUp,
      stopLossBuy=fractalStopLossBuy();
      //SetStoplosses(OP_BUY,stopLossBuy);

      double
      openLevelSell=fractalDown,
      stopLossSell=fractalStopLossSell();
      //SetStoplosses(OP_SELL,stopLossSell);

      if(fractalUp!=NULL && Ask>teeth && highBarPrice<fractalUp && fractalUp>lips) // && Ask<fractalUp
        {
         if(AccountFreeMarginCheck(Symbol(),OP_BUY,lotSize)>0)
           {
            if(OrderSend(Symbol(),OP_BUYSTOP,lotSize,openLevelBuy+shiftAB*Point,3,stopLossBuy-shiftAB*Point,0,"Terzo Uomo Saggio",magic,expiry,clrGreen))
               Alert(volumeString3l, ", ", Symbol(), ", ", Period());
           }
         else
           {
            Print(volumeString);
           }
        }
      // se esiste il frattale
      //& il prezzo di vendita è sotto ai denti
      // & il prezzo piu basso dell'ultima barra è maggiore al frattale inferiore
      // & il frattale inferiore è minore della mascella
      if(fractalDown!=NULL && Bid<teeth && lowBarPrice>fractalDown && fractalDown<jaws)
        {
         if(AccountFreeMarginCheck(Symbol(),OP_SELL,lotSize)>0)
           {
            if(OrderSend(Symbol(),OP_SELLSTOP,lotSize,openLevelSell-shiftAB*Point,3,stopLossSell+shiftAB*Point,0,"Terzo Uomo Saggio",magic,expiry,clrRosyBrown))
               Alert(volumeString3s, ", ", Symbol(), ", ", Period());
           }
         else
           {
            Print(volumeString);
           }
        }
     }
   return;
  }

//+------------------------------------------------------------------+
//| Close all of a particular type of order CHE COSA FA????                         |
//+------------------------------------------------------------------+
void closeReverse(int type)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderMagicNumber()==magic)
           {
            if(OrderType()==type)
              {
               double closingPrice=NULL;
               if(type==OP_BUY)
                  closingPrice=Bid;
               if(type==OP_SELL)
                  closingPrice=Ask;
               if(OrderClose(OrderTicket(),OrderLots(),closingPrice,10,clrAzure))
                 {
                  Print("Order Closed");
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double fractalStopLossBuy()
  {
   double fractalDown=0;
   for(int i = 0; i < BarsToScan; i++)
     {
      fractalDown=iFractals(Symbol(),PERIOD_CURRENT,MODE_LOWER,i);
      if(fractalDown>0)
         break;
     }
   double stopLossValue=fractalDown;
   Comment(StringFormat("fractalDown: ",stopLossValue));
   return stopLossValue;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double fractalStopLossSell()
  {
   double fractalUp=0;
   for(int i = 0; i < BarsToScan; i++)
     {
      fractalUp=iFractals(Symbol(),PERIOD_CURRENT,MODE_UPPER,i);
      if(fractalUp>0)
         break;
     }
   double stopLossValue=fractalUp;
   Comment(StringFormat("fractalUp: ",stopLossValue));
   return stopLossValue;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fractalTrailingStop()
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)

         double newStopLoss=0;

      double stopLossBuy=fractalStopLossBuy();
      double stopLossSell=fractalStopLossSell();
      double stopLossPrice=OrderStopLoss();

      double Spread=MarketInfo(NULL,MODE_SPREAD)*MarketInfo(NULL,MODE_POINT);
      double StopLevel=MarketInfo(NULL,MODE_STOPLEVEL)*MarketInfo(NULL,MODE_POINT);

      // posizione long BUY
      if(OrderType()==OP_BUY && stopLossBuy<MarketInfo(NULL,MODE_BID)-StopLevel)
        {
         double newStopLoss=stopLossBuy;
         if(newStopLoss>stopLossPrice+StopLevel || stopLossPrice==0)
           {
            ModifyOrder(OrderTicket(),OrderOpenPrice(),newStopLoss);
           }
        }

      //posizione short vendo SELL
      if(OrderType()==OP_SELL && stopLossSell>MarketInfo(NULL,MODE_ASK)+StopLevel+Spread)
        {
         double newStopLoss=(stopLossSell);
         if(newStopLoss<stopLossPrice-StopLevel || stopLossPrice==0)
           {
            ModifyOrder(OrderTicket(),OrderOpenPrice(),newStopLoss);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyOrder(int Ticket, double OpenPrice, double stopLossPrice)
  {
   if(OrderSelect(Ticket,SELECT_BY_TICKET)==false)
      for(int i=1; i<=OrderOpRetry; i++)
        {
         bool res=OrderModify(Ticket,OpenPrice,stopLossPrice,0,0,Blue);
         if(res)
           {
            Print("TRADE - UPDATE SUCCESS - Order ",Ticket," new stop loss ",stopLossPrice," new take profit ");
            break;
           }
        }
   return;
  }

//+------------------------------//+------------------------------------------------------------------+
//| A bullish divergent bar is a bar that has a lower low and closes |
//| in the top half of the bar.                                      |
//| Integer --> Boolean                                              |
//+------------------------------------------------------------------+
bool BullishDivergent(int bar)
  {
   double low=iLow(Symbol(),PERIOD_CURRENT,bar),
          median=(iHigh(Symbol(),PERIOD_CURRENT,bar)+low)/2;
   if(low<iLow(Symbol(),PERIOD_CURRENT,bar+1)
      && iClose(Symbol(),PERIOD_CURRENT,bar)>median)
     {
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//| A bearish divergent bar is a bar that has a higher high and      |
//| closes in the bottom half of the bar.                            |
//| Integer --> Boolean                                              |
//+------------------------------------------------------------------+
bool BearishDivergent(int bar)
  {
   double high=iHigh(Symbol(),PERIOD_CURRENT,bar),
          median=(iLow(Symbol(),PERIOD_CURRENT,bar)+high)/2;
   if(high>iHigh(Symbol(),PERIOD_CURRENT,bar+1)
      && iClose(Symbol(),PERIOD_CURRENT,bar)<median)
     {
      return true;
     }
   return false;
  }
//  ------------------------------------+
//| FINE
//+------------------------------------------------------------------+
