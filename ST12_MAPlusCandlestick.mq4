
/*

# ST12_MAPlusCandlestick
作成日：2018/3/10
更新日：2018/3/11

・移動平均線とローソク足に着目したトレード

*/


#include <MyLib.mqh>

#define MAGIC 20180310
#define COMMENT "ST12_MAPlusCandlestick"


extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int FastMAPeriod = 7;
extern int MiddleMAPeriod = 25;
extern int SlowMAPeriod = 50;
extern int TSPoint = 5;
extern int FilterRange = 3;
extern int TimeStopBars = 2;

/*
エントリー関数
*/
int EntrySignal(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int ret = 0;
 
   double FMA_2 = iMA(NULL,0,FastMAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   double FMA_1 = iMA(NULL,0,FastMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   double MMA_2 = iMA(NULL,0,MiddleMAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   double MMA_1 = iMA(NULL,0,MiddleMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   double SMA_2 = iMA(NULL,0,SlowMAPeriod,0,MODE_SMA,PRICE_CLOSE,2);
   double SMA_1 = iMA(NULL,0,SlowMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   
   //Buy
   if(pos == 0       
      && SMA_2 < MMA_2 && MMA_2 < FMA_2
      && SMA_1 < MMA_1 && MMA_1 < FMA_1
      && SMA_2 < SMA_1
      && MMA_2 < MMA_1
      && FMA_2 < FMA_1
      && High[2] > FMA_2 && Low[2] < FMA_2
      && Close[1] > FMA_1
      //&& Close[0] > MMA_1
   ) ret = 1;
   //Sell
   if(pos == 0 
      && SMA_2 > MMA_2 && MMA_2 > FMA_2
      && SMA_1 > MMA_1 && MMA_1 > FMA_1
      && SMA_2 > SMA_1
      && MMA_2 > MMA_1
      && FMA_2 > FMA_1
      && High[2] > FMA_2 && Low[2] < FMA_2
      && Close[1] < FMA_1
      //&& Close[0] < MMA_1
   ) ret = -1;
   
   return(ret);
   
}

/*
フィルタ関数
*/
int FilterSignal(int signal)
{  
   int ret = 0;
   double range_1 = High[1] - Low[1];
   double range_0 = High[0] - Low[0];
   if(range_1 * FilterRange > range_0) ret = signal;
   
   return(ret);
}

int start()
{

   double SL;
   int sig_entry = EntrySignal(MAGIC);
   
   int lotsize = (AccountBalance()*AccountLeverage( ))/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   double order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   if (order_lots > 2.0 ) order_lots = 2.0;
   order_lots = 0.1;
   
   //Buy Order
   if(sig_entry > 0 && Ask > Low[1])
   {
      SL = Low[1];
      if(Bid - SL <= MarketInfo(Symbol(), MODE_STOPLEVEL)*Point){SL = Bid - MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;}
      if(MyOrderSend(OP_BUY,order_lots,Ask,Slippage,SL,0,COMMENT,MAGIC))
      {
         //MySendMail(COMMENT+":Buy Order Executed",1);
      }
   }
   
   //Sell Order
   if(sig_entry < 0 && Bid < High[1])
   {
      SL = High[1];
      if(SL - Ask <= MarketInfo(Symbol(), MODE_STOPLEVEL)*Point){SL = Ask + MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;}
      if(MyOrderSend(OP_SELL,order_lots,Bid,Slippage,SL,0,COMMENT,MAGIC))
      {
         //MySendMail(COMMENT+":Sell Order Executed",2);
      }
   }
   
   //TrailingStop
   MyTrailingStop(TSPoint,MAGIC);   
   
   //TimeStop_Exit
   TimeStop_Exit(Slippage,PERIOD_M30,TimeStopBars,MAGIC);
   
   return(0);
}
