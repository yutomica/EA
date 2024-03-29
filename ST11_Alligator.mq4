/*

# ST11_Alligator
作成日：2018/2/20
更新日：2018/2/26

・時間足：
1M - 15M/30M
5M - 60M
15M - 4H
30M - 8H
1H - 1D

*/


#include <MyLib.mqh>

#define MAGIC 20180220
#define COMMENT "ST11_Alligator"

#define OBS_PERIOD PERIOD_D1
#define EXE_PERIOD PERIOD_H1

extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int BBPeriod = 20;
extern double Kairi_lev = 0.008;

extern int jaw_period = 13;
extern int jaw_shift = 8;
extern int teeth_period = 8;
extern int teeth_shift = 5;
extern int lips_period = 5;
extern int lips_shift = 3;

/*
エントリー関数
*/
int EntrySignal(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int ret = 0;
   
   double jaw[5];
   for(int i=1;i<=5;i++){jaw[i] = iAlligator(NULL,EXE_PERIOD,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_EMA,PRICE_MEDIAN,1,i);}
   double teeth[5];
   for(int j=1;j<=5;j++){teeth[j] = iAlligator(NULL,EXE_PERIOD,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_EMA,PRICE_MEDIAN,2,j);}
   double lips[5];
   for(int k=1;k<=5;k++){lips[k] = iAlligator(NULL,EXE_PERIOD,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_EMA,PRICE_MEDIAN,3,k);}  
      
   //Buy
   if(pos == 0 
      && jaw[1] < teeth[1] && teeth[1] < lips[1]
      && jaw[2] < teeth[2] && teeth[2] < lips[2]
      && jaw[3] < teeth[3] && teeth[3] < lips[3]
      && jaw[1] > jaw[2] && jaw[2] > jaw[3]
      && teeth[1] > teeth[2] && teeth[2] > teeth[3]
      && lips[1] > lips[2] && lips[2] > lips[3]
      
      && iClose(NULL,EXE_PERIOD,1) > jaw[1]
      && iClose(NULL,EXE_PERIOD,1) < teeth[1]
   ) ret = 1;
   
   //Sell
   if(pos == 0 
      && jaw[1] > teeth[1] && teeth[1] > lips[1]
      && jaw[2] > teeth[2] && teeth[2] > lips[2]
      && jaw[3] > teeth[3] && teeth[3] > lips[3]
      && jaw[1] < jaw[2] && jaw[2] < jaw[3]
      && teeth[1] < teeth[2] && teeth[2] < teeth[3]
      && lips[1] < lips[2] && lips[2] < lips[3]
      
      && iClose(NULL,EXE_PERIOD,1) < jaw[1]
      && iClose(NULL,EXE_PERIOD,1) > teeth[1]
   ) ret = -1;
   
   return(ret);
   
}




/*
フィルタ関数
*/
int FilterSignal(int signal)
{   
   double jaw[5];
   for(int i=1;i<=5;i++){jaw[i] = iAlligator(NULL,OBS_PERIOD,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_EMA,PRICE_MEDIAN,1,i);}
   double teeth[5];
   for(int j=1;j<=5;j++){teeth[j] = iAlligator(NULL,OBS_PERIOD,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_EMA,PRICE_MEDIAN,2,j);}
   double lips[5];
   for(int k=1;k<=5;k++){lips[k] = iAlligator(NULL,OBS_PERIOD,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,MODE_EMA,PRICE_MEDIAN,3,k);}  
   int ret = 0;
   
   //Buy Filter
   if(signal > 0 
      && jaw[1] < teeth[1] && teeth[1] < lips[1]
      && jaw[2] < teeth[2] && teeth[2] < lips[2]
      && jaw[3] < teeth[3] && teeth[3] < lips[3]
      && jaw[1] > jaw[2] && jaw[2] > jaw[3]
      && teeth[1] > teeth[2] && teeth[2] > teeth[3]
      && lips[1] > lips[2] && lips[2] > lips[3]
   ) ret = signal;
   
   //Sell Filter
   if(signal < 0 
      && jaw[1] > teeth[1] && teeth[1] > lips[1]
      && jaw[2] > teeth[2] && teeth[2] > lips[2]
      && jaw[3] > teeth[3] && teeth[3] > lips[3]
      && jaw[1] < jaw[2] && jaw[2] < jaw[3]
      && teeth[1] < teeth[2] && teeth[2] < teeth[3]
      && lips[1] < lips[2] && lips[2] < lips[3]
   ) ret = signal;  
   
   return(ret);
}

extern int TSPoint = 5;
int start()
{
   double spread = Ask - Bid;
   //ExitPosition(MAGIC);
   int sig_entry = EntrySignal(MAGIC);
   sig_entry = FilterSignal(sig_entry);
   
   int lotsize = (AccountBalance()*AccountLeverage( ))/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   double order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   if (order_lots > 2.0 ) order_lots = 2.0;
   order_lots = 0.1;
  

   
   //Buy Order
   if(sig_entry > 0)
   {
      //MyOrderClose(Slippage,MAGIC);
      MyOrderSend(OP_BUY,order_lots,Ask,Slippage,0,0,COMMENT,MAGIC);
      /*if(Close[2] < Ask - spread){
         MyOrderSend(OP_BUY,order_lots,Ask,Slippage,0,0,COMMENT,MAGIC);
      }*/
      
      /*if(MyOrderSend(OP_BUY,order_lots,Ask,Slippage,Ask-SL_level*Point,0,COMMENT,MAGIC))
      {
         //MySendMail(COMMENT+":Buy Order Executed",1);
      }*/
   }
   
   //Sell Order
   if(sig_entry < 0)
   {
      //MyOrderClose(Slippage,MAGIC);
      MyOrderSend(OP_SELL,order_lots,Bid,Slippage,0,0,COMMENT,MAGIC);
      /*if(Close[2] > Ask){
         MyOrderSend(OP_SELL,order_lots,Bid,Slippage,0,0,COMMENT,MAGIC);
      }*/
      /*if(MyOrderSend(OP_SELL,order_lots,Bid,Slippage,Bid+SL_level*Point,0,COMMENT,MAGIC))
      {
         //MySendMail(COMMENT+":Sell Order Executed",2);
      }*/
   }
   
   //TrailingStop
   MyTrailingStop(TSPoint,MAGIC);
   
   //TrailingStop_ATR
   //MyTrailingStopATR(ATRPeriod,ATRMult,MAGIC);
   
   //TimeStop_Exit
   TimeStop_Exit(Slippage,EXE_PERIOD,4,MAGIC);

   return(0);
}
