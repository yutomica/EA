/*

# ST17_DonchianBO_ATR
作成日：2019/10/6
更新日：20XX/X/X

[概要]
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

#define MAGIC 20191006
#define COMMENT "ST17_DonchianBO_ATR"

//+------------------------------------------------------------------+
//| EAパラメータ設定情報                                             |
//+------------------------------------------------------------------+
extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int En_bars = 20;
extern int Ex_bars = 10;
extern int FastMAPeriod = 25;
extern int SlowMAPeriod = 350;
extern int ATRPeriod = 20;
extern double ATRMult = 2.0;
extern int MAXPOS = 5;
extern int SLPips = 80;
extern int TSPips = 30;


//+------------------------------------------------------------------+
//| グローバル変数                                                   |
//+------------------------------------------------------------------+
// 共通
double gPipsPoint     = 0.0;
int    gSlippage      = 0;
color  gArrowColor[6] = {Blue, Red, Blue, Red, Blue, Red}; //BUY: Blue, SELL: Red
int    sig_entry;
double order_lots;
double SL;
int    fileHandle;
double pos_atr;
int    n_pos = 0;
int    pos_tickets[10];
double pos_atrs[10];

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
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int ret = 0;

   //BUY：
   if(pos == 0
      && High[iHighest(NULL, 0, MODE_HIGH, En_bars, 2)] < Close[1]
   ) ret = 1;
   //Sell：
   if(pos == 0
      && Low[iLowest(NULL, 0, MODE_LOW, En_bars, 2)] > Close[1]
   ) ret = -1;
   
   return(ret);
   
}

/*
フィルタ関数
*/
int FilterSignal(int signal)
{
   int ret = 0;
   double FastEMA = iMA(Symbol(),NULL,FastMAPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   double SlowEMA = iMA(Symbol(),NULL,SlowMAPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   
   if(signal>0 && FastEMA > SlowEMA ) ret = signal;
   if(signal<0 && FastEMA < SlowEMA ) ret = signal;
   
   return(ret);

}


/*
エキジット関数
*/
void ExitPosition(int magic)
{
   int ret = 0;
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   
   //Buy Close
   if(pos > 0 && Low[iLowest(NULL, 0, MODE_LOW, Ex_bars, 2)] > Close[1]) ret = 1;

   //Sell Close
   if(pos < 0 && High[iHighest(NULL, 0, MODE_HIGH, Ex_bars, 2)] < Close[1]) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

}


/*
追撃
*/
void AddPosition(int magic,double p_atr)
{
   
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   bool newBar = IsNewBar();
   Tracker(fileHandle,MAGIC);
   
   //ExitPosition(MAGIC);
   sig_entry = EntrySignal(MAGIC);
   sig_entry = FilterSignal(sig_entry);
   
   order_lots = 0.01;
   
   if(newBar==True && sig_entry>0){
      pos_atr = iATR(Symbol(),NULL,ATRPeriod,1)*ATRMult;
      SL = Ask - pos_atr;
      MyOrderSend(OP_BUY,order_lots,Ask,Slippage,SL,0,COMMENT,MAGIC);
      n_pos += 1;
   }
   
   if(newBar==True && sig_entry<0){
      pos_atr = iATR(Symbol(),NULL,ATRPeriod,1)*ATRMult;
      SL = Bid + pos_atr;   
      MyOrderSend(OP_SELL,order_lots,Bid,Slippage,SL,0,COMMENT,MAGIC);
      n_pos += 1;
   }
   
   if(MyCurrentOrders(MY_OPENPOS, magic)<>0){AddPosition(MAGIC,pos_atr);}
   
   //MyTrailingStop(TSPips,MAGIC);
   TimeStop_Exit_Force(Slippage,NULL,100,MAGIC);
   //TimeStop_Exit(Slippage,NULL,1,MAGIC);
  
}