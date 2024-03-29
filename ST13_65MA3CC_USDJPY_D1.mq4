/*

# ST13_65MA3CC
作成日：2019/9/20
更新日：2019/9/22
稼働開始日：2019/9/22

【チャート】：
・USDJPY 日足

【テクニカル】：
・移動平均線（65SMA）

【ロジック】：
・三日連続して終値が65日SMA（13週=四半期）の上/下で引ける→Buy/Sell
・TP:TrailingStop(10Pips)
・SL:Enから80Pips

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

#define MAGIC 20190920
#define COMMENT "ST13_65MA3CC"

//+------------------------------------------------------------------+
//| EAパラメータ設定情報                                             |
//+------------------------------------------------------------------+
extern int Slippage = 3;
extern int MAPeriod = 65;
extern int TSPips = 10;
extern int SLPips = 80;


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
double Safety_ratio = 0.03;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  if(Digits == 3 || Digits == 5){
   TSPips *= 10;
   SLPips *= 10;
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
int EntrySignal(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int ret = 0;
   double MA[6];
   for(int i=1;i<=5;i++){
      MA[i] = iMA(Symbol(),NULL,MAPeriod,0,MODE_SMA,PRICE_CLOSE,i);
   }
   
   //BUY：
   if(/*pos == 0
      && */Close[3] > MA[3] && Close[2] > MA[2] && Close[1] > MA[1]
      && Close[4] < MA[4]
   ) ret = 1;
   
   //Sell：
   if(/*pos == 0
      && */Close[3] < MA[3] && Close[2] < MA[2] && Close[1] < MA[1]
      && Close[4] > MA[4]
   ) ret = -1;
   
   return(ret);
   
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
   bool newBar = IsNewBar();
   Tracker(fileHandle,MAGIC);
   sig_entry = EntrySignal(MAGIC);
   
   order_lots = AccountBalance()*Safety_ratio/(MarketInfo(Symbol(),MODE_LOTSIZE)*SLPips*Point);
   order_lots = int(order_lots*100)/100.;
   //Print(order_lots);
   if(order_lots > MarketInfo(Symbol(), MODE_MAXLOT)){order_lots = MarketInfo(Symbol(), MODE_MAXLOT);}
   order_lots = 0.01;
   
   if(newBar==True && sig_entry>0){
      SL = Ask - SLPips*Point;
      TP = 0;
      if(MyOrderSend(OP_BUY,order_lots,Ask,Slippage,SL,TP,COMMENT,MAGIC)){
         //MySendMail("ST13_65MA3CC",0);
      }
   }
   
   if(newBar==True && sig_entry<0){
      SL = Bid + SLPips*Point;
      TP = 0;
      if(MyOrderSend(OP_SELL,order_lots,Bid,Slippage,SL,TP,COMMENT,MAGIC)){
         //MySendMail("ST13_65MA3CC",1);
      }
   }
   
   //trailingStopGeneral(MAGIC,TSPips,TSPips);
   MyTrailingStop(TSPips,MAGIC);
   //TimeStop_Exit_Force(Slippage,NULL,100,MAGIC);
   TimeStop_Exit(Slippage,NULL,1,MAGIC);
   
}