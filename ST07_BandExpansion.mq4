/*

# ST07_BandExpansion
作成日：2016/9/2
更新日：2019/9/20

・ボリンジャーバンドが拡大するタイミングでエントリー
・反対側の2σの向きが変わったタイミングでエキジット

*/

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>
//#include <Original/Application.mqh>
#include <Original/Mylib.mqh>
#include <Original/Basic.mqh>
#include <Original/DateAndTime.mqh>
#include <Original/LotSizing.mqh>
#include <Original/TrailingStop.mqh>
#include <Original/TimeStop.mqh>
#include <Original/Mail.mqh>
#include <Original/Tracker.mqh>
//#include <Original/OrderHandle.mqh>
//#include <Original/OrderReliable.mqh>

#define MAGIC 20160902
#define COMMENT "ST07_BandExpansion"

extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int BBPeriod = 20;
extern double Trigger_range = 1.0;

//+------------------------------------------------------------------+
//| グローバル変数                                                   |
//+------------------------------------------------------------------+
// 共通
double gPipsPoint     = 0.0;
int    gSlippage      = 0;
color  gArrowColor[6] = {Blue, Red, Blue, Red, Blue, Red}; //BUY: Blue, SELL: Red
int    fileHandle;
int    sig_entry;
double order_lots;
double TP,SL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  if(Digits == 3 || Digits == 5){
  }
    
  /*Edge Validation*/
  string outfile = "_tmp.csv";
  fileHandle = FileOpen(outfile,FILE_CSV|FILE_WRITE,",");
  
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  FileClose(fileHandle);
}


/*
エントリー関数
*/
int EntrySignal(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   double BandExpansion[10];
   double U2sig_1;double L2sig_1;double U2sig_2;double L2sig_2;double U2sig_3;double L2sig_3;   
   int ret = 0;
   
   for(int i=0;i<10;i++){
      BandExpansion[i] = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,i) - iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,i);
   }
   U2sig_1 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,1);
   L2sig_1 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,1);
   U2sig_2 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,2);
   L2sig_2 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,2);
   U2sig_3 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,3);
   L2sig_3 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,3);
   
   if(pos == 0 
      && BandExpansion[5] > BandExpansion[4]
      && BandExpansion[4] > BandExpansion[3]
      && BandExpansion[3] > BandExpansion[2]
      && BandExpansion[2] > BandExpansion[1]
      //&& L2sig_3 < L2sig_2 && L2sig_2 < L2sig_1
      && Close[1] > U2sig_1 && Low[1] > L2sig_1
   ) ret = 1;
   if(pos == 0 
      && BandExpansion[5] > BandExpansion[4]
      && BandExpansion[4] > BandExpansion[3]
      && BandExpansion[3] > BandExpansion[2]
      && BandExpansion[2] > BandExpansion[1]
      //&& U2sig_3 < U2sig_2 && U2sig_2 < U2sig_1
      && Close[1] < L2sig_1 && High[1] < U2sig_1
   ) ret = -1;
   
   return(ret);
}

/*
エキジット関数
*/
void ExitPosition(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   double U2sig_3;double U2sig_2;double U2sig_1;double U2sig_0;
   double L2sig_3;double L2sig_2;double L2sig_1;double L2sig_0;
   double Middle_0;
   int ret = 0;

   U2sig_3 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,3);
   U2sig_2 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,2);
   U2sig_1 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,1);
   U2sig_0 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,0);
   L2sig_3 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,3);
   L2sig_2 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,2);
   L2sig_1 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,1);
   L2sig_0 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,0);
   Middle_0 = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_MAIN,0);

   //Buy Close
   if(
      (pos > 0 && L2sig_3 > L2sig_2 && L2sig_2 < L2sig_1)
      || (pos > 0 && Middle_0 > Close[1])
   )ret = 1;

   //Sell Close
   if(
      (pos < 0 && U2sig_3 < U2sig_2 && U2sig_2 > U2sig_1)
      || (pos < 0 && Middle_0 < Close[1])
   ) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

}

int start()
{
   bool newBar = IsNewBar();
   double BandExpansion[10];
   for(int i=0;i<6;i++){
      BandExpansion[i] = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,i) - iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,i);
   }
   ExitPosition(MAGIC);
   sig_entry = EntrySignal(MAGIC);
   
   //ロット数計算
   int lotsize = (AccountBalance()*AccountLeverage( ))/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   if (order_lots > 2.0 ) order_lots = 2.0;
   //Print("lotsize=",lotsize," order_lots=",order_lots);
   order_lots = 0.01;
      
   //Buy Order
   if(newBar==true && sig_entry > 0)
   {
      MyOrderSend(OP_BUY,order_lots,Ask,Slippage,MathMin(Low[1],Bid-MarketInfo(Symbol(), MODE_STOPLEVEL)*Point),0,COMMENT,MAGIC);
   }
   
   //Sell Order
   if(newBar==true && sig_entry < 0)
   {
      MyOrderSend(OP_SELL,order_lots,Bid,Slippage,MathMax(High[1],Ask+MarketInfo(Symbol(), MODE_STOPLEVEL)*Point),0,COMMENT,MAGIC);
   }
   
   //TimeStop_Exit(Slippage,0,3,MAGIC);
   
   //MyTrailingStop(TSPoint,MAGIC);
   
   return(0);
}


