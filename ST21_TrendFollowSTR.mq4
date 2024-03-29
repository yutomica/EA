/*

# ST21_TrendFollowSTR
作成日：2019/3/3
更新日：2019/5/6

・日足ベーストレンドフォロー型戦略

・日足でトレンド判定を実施
・1H足でEn/Ex

・Alligatorでトレンド判定
　-トレンドがある場合に、直近最高値/最安値に逆指値注文を設定
　-トレンドがなくなった場合は、逆指値注文をキャンセル、ポジションをクローズ
・フィルタ：BB2σの外には逆指値注文は置かない

*/

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>
#include <Original/Mylib.mqh>
#include <Original/Basic.mqh>
#include <Original/DateAndTime.mqh>
#include <Original/LotSizing.mqh>
#include <Original/TrailingStop.mqh>
#include <Original/TimeStop.mqh>
#include <Original/Tracker.mqh>
//#include <Original/OrderHandle.mqh>
//#include <Original/OrderReliable.mqh>
//#include <Original/Mail.mqh>


#define MAGIC 20190303
#define COMMENT "ST21_TrendFollowSTR"

#define OBS_PERIOD PERIOD_D1

//+------------------------------------------------------------------+
//| EAパラメータ設定情報                                             |
//+------------------------------------------------------------------+
extern int    Slippage = 5;
extern double FixLotSize   = 0.03;
extern int    Maxpos       = 5;
extern int    ADX_Period      = 14;
extern int    FastMA_Period   = 7;
extern int    SlowMA_Period   = 65;
extern int    lookbackperiod  = 15;
extern int    BB_Period       = 20;
extern double filter_BB_upper;
extern double filter_BB_lower;
extern double Safety_ratio    = 0.03;
extern double EnBar        = 0.1;
extern double TSpips       = 50.;
extern int    TimeStop_bars = 10;


//+------------------------------------------------------------------+
//| グローバル変数                                                   |
//+------------------------------------------------------------------+
// 共通
double gPipsPoint     = 0.0;
int    gSlippage      = 0;
color  gArrowColor[6] = {Blue, Red, Blue, Red, Blue, Red}; //BUY: Blue, SELL: Red
double order_price,tp_price,sl_price,stp;
double order_lots;
double RAVI[3];
double TrADX[3];
double BB_Main;
double BB_Main_ExePeriod;

int fileHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  gPipsPoint = currencyUnitPerPips(Symbol());
  gSlippage = getSlippage(Symbol(), Slippage);
  
  /*Edge Validation*/
  string outfile = "_tmp.csv";
  fileHandle = FileOpen(outfile,FILE_CSV|FILE_WRITE,",");
  
  if(Digits == 3 || Digits == 5){
   TSpips *= 10;
  }
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  FileClose(fileHandle);  
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

   bool newBar = IsNewBar();
   Tracker(fileHandle,MAGIC);

   // トレンド判定
   int OnTrend = 0;
   for(int i=1;i<=3;i++){
      RAVI[i] = iCustom(NULL,OBS_PERIOD,"Trendjudge_RAVI",FastMA_Period,SlowMA_Period,0,i);
   }
   for(int j=1;j<=3;j++){
      TrADX[j] = iCustom(NULL,OBS_PERIOD,"Trendjudge_ADX",ADX_Period,0,j);
   }
   BB_Main = iBands(NULL,OBS_PERIOD,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   if(
      RAVI[3] < RAVI[2] && RAVI[2] < RAVI[1]
      && TrADX[1] == 1
      && Close[1] > BB_Main
   ){OnTrend = 1;}
   if(
      RAVI[3] < RAVI[2] && RAVI[2] < RAVI[1]
      && TrADX[1] == 1
      && Close[1] < BB_Main
   ){OnTrend = -1;}
   
  
   //トレンドありの場合は逆指値注文を設定
   //int lotsize = (AccountBalance()*AccountLeverage())/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   //order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   //if (order_lots > 2.0 ) order_lots = 2.0;
   order_lots = FixLotSize;   
   if(newBar==True && OnTrend>0 && MyCurrentOrders(OP_BUYSTOP,MAGIC)==0 /*&& OrdersTotal() < Maxpos*/){
      order_price = iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,lookbackperiod,1));
      tp_price = 0;//order_price + iATR(NULL,EXE_PERIOD,ATRPeriod,1);//order_price + TP_range*Point;
      sl_price = 0;//order_price - iATR(NULL,EXE_PERIOD,ATRPeriod,1);//order_price - SL_range*Point;
      stp = MarketInfo(NULL,MODE_STOPLEVEL);
      filter_BB_upper = iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_UPPER,1);

      if(order_price - Ask > stp*Point && order_price < filter_BB_upper){
         Print("POS : ",OrdersTotal());
         MyOrderSend(OP_BUYSTOP,order_lots,order_price,Slippage,sl_price,tp_price,COMMENT,MAGIC);
      }
   }     
   if(newBar==True && OnTrend<0 && MyCurrentOrders(OP_SELLSTOP,MAGIC)==0 /*&& OrdersTotal() < Maxpos*/){
      order_price = iLow(NULL,0,iLowest(NULL,0,MODE_LOW,lookbackperiod,1));
      tp_price = 0;//order_price - iATR(NULL,EXE_PERIOD,ATRPeriod,1);//order_price - TP_range*Point;
      sl_price = 0;//order_price + iATR(NULL,EXE_PERIOD,ATRPeriod,1);//order_price + SL_range*Point;
      stp = MarketInfo(NULL,MODE_STOPLEVEL);
      filter_BB_lower = iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_LOWER,1);
      
      if(Bid - order_price > stp*Point && order_price > filter_BB_lower){
         Print(MyCurrentOrders(OP_SELL,MAGIC)*-1/order_lots);
         MyOrderSend(OP_SELLSTOP,order_lots,order_price,Slippage,sl_price,tp_price,COMMENT,MAGIC);
      }
   }
   
   //Exit
   /*
   BB_Main_ExePeriod = iBands(NULL,0,BB_Period,2,0,PRICE_CLOSE,MODE_MAIN,1);
   if(MyCurrentOrders(OP_BUY,MAGIC)>0 && Close[1]<BB_Main_ExePeriod){
      MyOrderClose(Slippage,MAGIC);
   }
   if(MyCurrentOrders(OP_SELL,MAGIC)<0 && Close[1]>BB_Main_ExePeriod){
      MyOrderClose(Slippage,MAGIC);
   }
   */  
   
   //トレンドがなくなった場合は待機注文をキャンセルし、ポジションをクローズ
   
   if(OnTrend==0){
      MyOrderDelete(MAGIC);
      //MyOrderClose(Slippage,MAGIC);
   }
   
   
   //MyTrailingStop(TSpips,MAGIC);
   //TimeStop_Exit(Slippage,0,TimeStop_bars,MAGIC);
   TimeStop_Exit_Force(Slippage,NULL,100,MAGIC);
}



