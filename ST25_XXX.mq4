/*

# ST25_XX
作成日：2020/5/33
更新日：2020//
稼働開始日：

【チャート】：
・5分足

【テクニカル】：
・1時間足チャートの10MA
・15分足チャートの10MA 

【ロジック】：
・[En]1時間足チャートで方向確認、15分足チャートにタッチした瞬間に順方向でエントリー
・[Ex]1時間足チャートを実態ベースで逆方向に抜ける or TimeStopExit（4bars）
・[TP]直近高値
・[SL]-
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

#define MAGIC 200503
#define COMMENT "ST25_XXX"

//+------------------------------------------------------------------+
//| EAパラメータ設定情報                                             |
//+------------------------------------------------------------------+
extern double Safety_ratio = 0.03;
extern int Slippage = 3;
extern int TP_bars = 10;
extern int MAPeriod_1h = 10;
extern int MAPeriod_15m = 10;
extern int TSExit = 4;


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
double MA_1h[5];
double MA_15m[5];

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

   for(int i=0;i<5;i++){
      MA_1h[i] = iCustom(NULL,0,"MTF_MA",MAPeriod_1h,PERIOD_H1,MODE_SMA,0,PRICE_CLOSE,i*12);
      MA_15m[i] = iCustom(NULL,0,"MTF_MA",MAPeriod_15m,PERIOD_M15,MODE_SMA,0,PRICE_CLOSE,i);
   }

   //BUY：
   if(MA_1h[0] > MA_1h[1] && MA_1h[1] > MA_1h[2] && MA_1h[2] > MA_1h[3]
      && Close[1] > MA_15m[1] && Low[0] < MA_15m[0]
   ) ret = 1;
   //Sell：
   if(MA_1h[0] < MA_1h[1] && MA_1h[1] < MA_1h[2] && MA_1h[2] < MA_1h[3]
      && Close[1] < MA_15m[1] && High[0] > MA_15m[0]
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


   for(int i=0;i<5;i++){
      MA_1h[i] = iCustom(NULL,0,"MTF_MA",MAPeriod_1h,PERIOD_H1,MODE_SMA,0,PRICE_CLOSE,i);
   }
   
   //Buy Close
   if(pos > 0 && Close[1] < MA_1h[1]) ret = 1;

   //Sell Close
   if(pos < 0 && Close[1] > MA_1h[1]) ret = -1;

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
  
   //order_lots = AccountBalance()*Safety_ratio/(MarketInfo(Symbol(),MODE_LOTSIZE)*SLPips*Point);
   //order_lots = int(order_lots*100)/200.;
   //if(order_lots > MarketInfo(Symbol(), MODE_MAXLOT)){order_lots = MarketInfo(Symbol(), MODE_MAXLOT);}
   order_lots = 0.01;
  
   if(newBar==True && sig_entry>0){
      SL = 0;
      TP = High[iHighest(NULL, 0, MODE_HIGH, TP_bars, 0)];
      MyOrderSend(OP_BUY,order_lots,Ask,Slippage,SL,TP,COMMENT,MAGIC);
   }
   
   if(newBar==True && sig_entry<0){
      SL = 0;
      TP = Low[iLowest(NULL, 0, MODE_LOW, TP_bars, 0)];
      MyOrderSend(OP_SELL,order_lots,Bid,Slippage,SL,TP,COMMENT,MAGIC);
   }

   TimeStop_Exit(Slippage,NULL,TSExit,MAGIC);
     
}