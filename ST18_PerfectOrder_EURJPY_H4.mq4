/*

# [ストラテジ名]
作成日：20XX/X/X
更新日：20XX/X/X


【チャート】：
・日足
・トレンドが明確な通貨ペアならどれでもOK

【テクニカル】：
・移動平均線（55SMA、90SMA）
・MACD２(短期12、長期26、シグナル9)

【ロジック】：
・2本の移動平均線とローソク足でトレンドを確認（MAの傾き、ローソク足のMAに対する位置）
・トレンドが確認出来たらその方向へのエントリーに備える
・MACDラインとシグナルラインのゴールデンクロス/デッドクロスで買/売エントリー
・TP:デッドクロスで利確
・SL：5％ルールを適用


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

#define MAGIC 20200223
#define COMMENT "ST18_PerfectOrder_EURJPY_H4"

//+------------------------------------------------------------------+
//| EAパラメータ設定情報                                             |
//+------------------------------------------------------------------+
extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int fastMAPeriod = 5;
extern int middleMAPeriod = 25;
extern int slowMAPeriod = 75;
//extern int TSPips =10;
extern int TSRange = 10;


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
   //TSPips *= 10;
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
   int ret = 0;
   double fastMA[5];
   for(int i=1;i<=5;i++){fastMA[i] = iMA(NULL,0,fastMAPeriod,0,MODE_SMA,PRICE_CLOSE,i);}
   double middleMA[5];
   for(int j=1;j<=5;j++){middleMA[j] = iMA(NULL,0,middleMAPeriod,0,MODE_SMA,PRICE_CLOSE,j);}
   double slowMA[5];
   for(int k=1;k<=5;k++){slowMA[k] = iMA(NULL,0,slowMAPeriod,0,MODE_SMA,PRICE_CLOSE,k);}  
    
   //BUY：
   if(/*pos == 0
      &&*/ fastMA[1] > middleMA[1] && middleMA[1] > slowMA[1]
      && fastMA[2] > middleMA[2] && middleMA[2] > slowMA[2]
      && fastMA[3] > middleMA[3] && middleMA[3] > slowMA[3]
      && fastMA[1] > fastMA[2] && middleMA[1] > middleMA[2] && slowMA[1] > slowMA[2]
      && fastMA[2] > fastMA[3] && middleMA[2] > middleMA[3] && slowMA[2] > slowMA[3]
   ) ret = 1;
   
   //Sell：
   if(/*pos == 0
      &&*/ fastMA[1] < middleMA[1] && middleMA[1] < slowMA[1]
      && fastMA[2] < middleMA[2] && middleMA[2] < slowMA[2]
      && fastMA[3] < middleMA[3] && middleMA[3] < slowMA[3]
      && fastMA[1] < fastMA[2] && middleMA[1] < middleMA[2] && slowMA[1] < slowMA[2]
      && fastMA[2] < fastMA[3] && middleMA[2] < middleMA[3] && slowMA[2] < slowMA[3]
   ) ret = -1;
   
   return(ret);
   
}



/*
エキジット関数
*/
void ExitPosition(int magic)
{
   int ret = 0;
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   
   double haClose_2 = iCustom(NULL,PERIOD_D1,"Heiken Ashi",3,2);
   double haOpen_2 = iCustom(NULL,PERIOD_D1,"Heiken Ashi",2,2);
   double haClose_1 = iCustom(NULL,PERIOD_D1,"Heiken Ashi",3,1);
   double haOpen_1 = iCustom(NULL,PERIOD_D1,"Heiken Ashi",2,1);
   
   //Buy Close
   if(pos > 0 && haClose_2 < haOpen_2 && haClose_1 < haOpen_1) ret = 1;

   //Sell Close
   if(pos < 0 && haClose_2 > haOpen_2 && haClose_1 > haOpen_1) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

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
   
   // Buy
   if(signal>0  && haOpen_1 < haClose_1 /*&& curHour>13 && curHour<21*/) ret = signal;
   // Sell
   if(signal<0  && haOpen_1 > haClose_1 /*&& curHour>13 && curHour<21*/) ret = signal;

   
   return(ret);

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
   bool newBar = IsNewBar();
   //Tracker(fileHandle,MAGIC);
   
   ExitPosition(MAGIC);
   sig_entry = EntrySignal(MAGIC);
   sig_entry = FilterSignal(sig_entry);
   
   order_lots = 0.01;
   
   if(newBar==True && sig_entry>0){
      SL = 0;
      TP = 0;
      MyOrderSend(OP_BUY,order_lots,Ask,Slippage,SL,TP,COMMENT,MAGIC);
   }
   
   if(newBar==True && sig_entry<0){
      SL = 0;
      TP = 0;
      MyOrderSend(OP_SELL,order_lots,Bid,Slippage,SL,TP,COMMENT,MAGIC);
   }
   
   //TimeStop_Exit_Force(Slippage,NULL,100,MAGIC);
   MyTrailingStopHL(TSRange,MAGIC);
   
}