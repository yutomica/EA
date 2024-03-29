/*

# ST16_DonchianBreakout
作成日：2019/9/22
更新日：2020/3/8
稼働開始日：2019/9/22

【チャート】：
・EURJPY 4時間足

【テクニカル】：
・20期間Hバンド

【ロジック】：
・[En]ポジション未保有、かつ20期間Hバンドを終値が上/下回った場合に、寄り付きでエントリー
・[Ex]TimeStopExit（14bars）
・[TP]TrailingStop(5Pips)
・[SL]Enから50Pips
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
#include <Original/Pyramitting.mqh>
//#include <Original/OrderHandle.mqh>
//#include <Original/OrderReliable.mqh>

#define MAGIC 19092201
#define COMMENT "ACT_ST16_DonchianBreakout_EURJPY_H4"

//+------------------------------------------------------------------+
//| EAパラメータ設定情報                                             |
//+------------------------------------------------------------------+
extern double Safety_ratio = 0.03;
extern int Slippage = 3;
extern int En_bars = 20;
extern int Ex_bars = 10;
extern int FastMAPeriod = 25;
extern int SlowMAPeriod = 350;
extern int SLPips = 50;
extern int TSPips = 10;
extern int MaxPos = 8;
extern double lot_of_firstpos = 0.1;
extern double deg_ratio = 0.8;
//+------------------------------------------------------------------+
//| グローバル変数                                                   |
//+------------------------------------------------------------------+
// 共通
double gPipsPoint     = 0.0;
int    gSlippage      = 0;
color  gArrowColor[6] = {Blue, Red, Blue, Red, Blue, Red}; //BUY: Blue, SELL: Red
int    sig_entry;
double order_lots;
double SL,TP;
int    fileHandle;
int    ticket_of_fistpos;

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
  //string outfile = "_tmp.csv";
  //fileHandle = FileOpen(outfile,FILE_CSV|FILE_WRITE,",");
  
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  //FileClose(fileHandle);
}



/*
エントリー関数
*/
int EntrySignal(int oMagic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, oMagic);
   int ret = 0;

   //BUY：
   if(/*pos == 0
      && */High[iHighest(NULL, 0, MODE_HIGH, En_bars, 2)] < Close[1]
   ) ret = 1;
   //Sell：
   if(/*pos == 0
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
   double FastEMA = iMA(Symbol(),NULL,FastMAPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   
   //Buy Close
   if(pos > 0 && FastEMA > Close[1]) ret = 1;

   //Sell Close
   if(pos < 0 && FastEMA < Close[1]) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   bool newBar = IsNewBar();
   //Tracker(fileHandle,MAGIC);
   int pos = MyCurrentPos(MY_OPENPOS, MAGIC);
   
   ExitPosition(MAGIC);
   sig_entry = EntrySignal(MAGIC);
   sig_entry = FilterSignal(sig_entry);
   /*
   order_lots = AccountBalance()*Safety_ratio/(MarketInfo(Symbol(),MODE_LOTSIZE)*SLPips*Point);
   order_lots = int(order_lots*100)/200.;
   if(order_lots > MarketInfo(Symbol(), MODE_MAXLOT)){order_lots = MarketInfo(Symbol(), MODE_MAXLOT);}
   order_lots = 0.01;
   */
   if(MathAbs(pos)>0){order_lots = NormalizeDouble(lot_of_firstpos*MathPow(deg_ratio,MathAbs(pos)-1),2);}
   else{order_lots=lot_of_firstpos;}
   if(order_lots <= 0.01) sig_entry=0;
   order_lots = 0.01;
   
   if(newBar==True && sig_entry>0){
      SL = 0;//Ask - SLPips*Point;
      ticket_of_fistpos = SendOrder(OP_BUY,order_lots,Ask,Slippage,SL,0,COMMENT,MAGIC);
   }
   
   if(newBar==True && sig_entry<0){
      SL = 0;//Bid + SLPips*Point;
      ticket_of_fistpos = SendOrder(OP_SELL,order_lots,Bid,Slippage,SL,0,COMMENT,MAGIC);
   }
   
   //Pyramitting(TSPips,order_lots,ticket_of_fistpos,MAGIC,3);
   //if(newBar==True)Print(MyCurrentPos(MY_OPENPOS,MAGIC));
   //MyTrailingStop(TSPips,magic2);
   //TimeStop_Exit_Force(Slippage,NULL,100,MAGIC);
   //TimeStop_Exit(Slippage,NULL,14,MAGIC);
   MyTrailingStopHL(Ex_bars,MAGIC);
}