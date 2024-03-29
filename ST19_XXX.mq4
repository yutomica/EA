/*

# ST19_XX
作成日：2020/3/12
更新日：2020//
稼働開始日：

【チャート】：
・EURJPY 

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
//#include <Original/OrderHandle.mqh>
//#include <Original/OrderReliable.mqh>

#define MAGIC 200312
#define COMMENT "ST19_XXX"

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
extern int TPPips = 5;
extern int MaxPos = 8;
extern int RSIPeriod = 14;
extern int BOPeriod = 20;


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
   Print( "現在チャートの通貨ペア名               :"  , Symbol() );
   Print( "現在チャートの時間軸                   :"  , Period() );
   Print( "現在チャートの通貨ペアの価格精度       :"  , Digits() );
   printf("現在チャートの通貨ペアの価格の小数点値 :%f", Point()  );
   Print( "現在チャートの通貨ペアの価格(終値)     :"  , DoubleToStr(Close[0],Digits()) );
   
  if(Digits == 3 || Digits == 5){
   SLPips *= 10;
   TPPips *= 10;
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

   int BO = iCustom(Symbol(),NULL,"BreakOut_MTF",PERIOD_H4,0,1);

   //BUY：
   if(BO == 1
      && iHigh(NULL,0,iHighest(NULL,0, MODE_HIGH, BOPeriod,2)) < iClose(NULL,0,1)
   ) ret = 1;
   //Sell：
   if(BO == -1
      && iLow(NULL,0,iLowest(NULL,0,MODE_LOW,BOPeriod,2)) > iClose(NULL,0,1)
   ) ret = -1;
   
   return(ret);
   
}

/*
フィルタ関数
*/
int FilterSignal(int signal)
{
   int ret = 0;
   int BO = iCustom(Symbol(),NULL,"BreakOut_MTF",PERIOD_H4,0,1);
   
   if(signal>0 && BO==1 ) ret = signal;
   if(signal<0 && BO==-1 ) ret = signal;
   
   return(ret);

}


/*
エキジット関数
*/
void ExitPosition(int magic)
{
   int ret = 0;
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int BO = iCustom(Symbol(),NULL,"BreakOut_MTF",PERIOD_H4,0,1);
   
   //Buy Close
   if(pos > 0 && BO!=1) ret = 1;

   //Sell Close
   if(pos < 0 && BO!=-1) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

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
   //sig_entry = FilterSignal(sig_entry);
  
   order_lots = AccountBalance()*Safety_ratio/(MarketInfo(Symbol(),MODE_LOTSIZE)*SLPips*Point);
   order_lots = int(order_lots*100)/200.;
   //Print(order_lots);
   if(order_lots > MarketInfo(Symbol(), MODE_MAXLOT)){order_lots = MarketInfo(Symbol(), MODE_MAXLOT);}
   order_lots = 0.01;
  
   if(newBar==True && sig_entry>0){
      SL = Ask - SLPips*Point;
      TP = Ask + TPPips*Point;
      ticket_of_fistpos = SendOrder(OP_BUY,order_lots,Ask,Slippage,SL,TP,COMMENT,MAGIC);
   }
   
   if(newBar==True && sig_entry<0){
      SL = Bid + SLPips*Point;
      TP = Bid - TPPips*Point;
      ticket_of_fistpos = SendOrder(OP_SELL,order_lots,Bid,Slippage,SL,TP,COMMENT,MAGIC);
   }

   //TimeStop_Exit(Slippage,NULL,14,MAGIC);
     
}