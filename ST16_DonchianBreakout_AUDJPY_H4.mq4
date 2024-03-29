/*

# ST16_DonchianBreakout
作成日：2019/9/17
更新日：2019/9/28

【チャート】：
・AUDJPY、4時間足

【テクニカル】：
・20日HLバンド

【ロジック】：
・20日ブレイクアウトを仕掛けに、10日ブレイクアウトを手仕舞いに使用
・350日／25日EMAをトレンドフィルタとして用いる
・25EMAが350EMAを上回っていれば買い持ちのみ、下回っていれば売り持ちのみ
・2-ATRストップを採用

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

#define MAGIC 20190928
#define COMMENT "ST16_DonchianBreakout"

//+------------------------------------------------------------------+
//| EAパラメータ設定情報                                             |
//+------------------------------------------------------------------+
extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int En_bars = 20;
extern int Ex_bars = 10;
extern int MAPeriod = 25;
extern int SLPips = 100;
extern int TSPips = 30;
extern int Maxpos = 2;


//+------------------------------------------------------------------+
//| グローバル変数                                                   |
//+------------------------------------------------------------------+
// 共通
double gPipsPoint     = 0.0;
int    gSlippage      = 0;
color  gArrowColor[6] = {Blue, Red, Blue, Red, Blue, Red}; //BUY: Blue, SELL: Red
int    sig_entry;
double order_lots;
double TP,SL;
int    fileHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  if(Digits == 3 || Digits == 5){
   SLPips *= 10;
   TSPips *= 10;
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
   int pos = MyCurrentPos(MY_OPENPOS, magic);
   int ret = 0;

   //BUY：
   if(/*MathAbs(pos) <= Maxpos
      && */High[iHighest(NULL, 0, MODE_HIGH, En_bars, 2)] < Close[1]
   ) ret = 1;
   //Sell：
   if(/*MathAbs(pos) <= Maxpos
      && */Low[iLowest(NULL, 0, MODE_LOW, En_bars, 2)] > Close[1]
   ) ret = -1;
   
   return(ret);
   
}

/*
フィルタ関数
*/
int FilterSignal(int signal)
{
   int ret = 0;
   int curHour = Hour();
   double haClose_1 = iCustom(NULL,PERIOD_D1,"Heiken Ashi",3,1);
   double haOpen_1 = iCustom(NULL,PERIOD_D1,"Heiken Ashi",2,1);
   double haClose_2 = iCustom(NULL,PERIOD_D1,"Heiken Ashi",3,2);
   double haOpen_2 = iCustom(NULL,PERIOD_D1,"Heiken Ashi",2,2);   
   // Buy
   if(signal>0  && haOpen_1 < haClose_1 && haOpen_2 < haClose_2) ret = signal;
   // Sell
   if(signal<0  && haOpen_1 > haClose_1 && haOpen_2 > haClose_2) ret = signal;

   
   return(ret);

}


/*
エキジット関数
*/
void ExitPosition(int magic)
{
   int ret = 0;
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   double MA = iMA(NULL,0,MAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   
   //Buy Close
   if(pos > 0 && iClose(NULL,0,1) < MA) ret = 1;

   //Sell Close
   if(pos < 0 && iClose(NULL,0,1) > MA) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

}

/*
前日平均足始値ベースのトレーリングストップ
*/
void TrailingStop_HKA(int magic)
{
   double haOpen_1 = iCustom(NULL,PERIOD_D1,"Heiken Ashi",2,1);
   if(MyCurrentOrders(OP_BUY, magic) != 0) ModifyOrder(haOpen_1, 0, magic);
   if(MyCurrentOrders(OP_SELL, magic) != 0) ModifyOrder(haOpen_1, 0, magic);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  bool newBar = IsNewBar();
  Tracker(fileHandle,MAGIC);
  
  ExitPosition(MAGIC);
  sig_entry = EntrySignal(MAGIC);
  sig_entry = FilterSignal(sig_entry);
  
  order_lots = 0.01;
  
  if(newBar==True && sig_entry>0){
   SL = 0;//Ask - SLPips*Point;
   TP = 0;//Ask + TSPips*Point;
   MyOrderSend(OP_BUY,order_lots,Ask,Slippage,SL,TP,COMMENT,MAGIC);
  }
  
  if(newBar==True && sig_entry<0){
   SL = 0;//Bid + SLPips*Point;
   TP = 0;//Bid - TSPips*Point;   
   MyOrderSend(OP_SELL,order_lots,Bid,Slippage,SL,TP,COMMENT,MAGIC);
  }
  
  //MyTrailingStop(TSPips,MAGIC);
  //TrailingStop_HKA(MAGIC);
  TimeStop_Exit_Force(Slippage,NULL,100,MAGIC);
  //TimeStop_Exit(Slippage,0,3,MAGIC);
  
}