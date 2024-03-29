/*

# FXKouryaku_201705_03
2種類の移動平均線/数時間で何回もエントリー可能な短期トレード
作成日：2018/3/17
更新日：2019/9/15

【チャート】：
・5分～30分程度の短期足
・40SMAに角度がついている、トレンドが発生している通貨ペア
・短期売買向けなので、USDJPY、EURUSDといったスプレッドが小さい通貨ペアが望ましい

【テクニカル】：
・加重移動平均線5WMA、単純移動平均線40SMA 

【ロジック】
・40SMAが上向きになるのを待つ。横這いならトレード見送り
・5WMAが40SMAを下から上に抜けたら、ローソク足の確定を待ってエントリ―（売りはその逆）
・TP:エントリーした足を含むローソク足3本までの高値（安値）
・SL:エントリーしたローソク足の安値（高値）

【改善点】
・StopLevelに引っかかる注文が多い
・SMAの傾きの判定方法

*/

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>
//#include <Original/Application.mqh>
#include <Original/Basic.mqh>
#include <Original/DateAndTime.mqh>
#include <Original/LotSizing.mqh>
#include <Original/MyLib.mqh>
#include <Original/Tracker.mqh>
#include <Original/TimeStop.mqh>

#define MAGIC 20180317
#define COMMENT "FXKouryaku_201705_03"


extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int WMAPeriod = 5;
extern int SMAPeriod = 40;

int fileHandle;


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
   int ret = 0;
 
   double SMA[10];
   for(int j=1;j<=10;j++){
      SMA[j] = iMA(NULL,0,SMAPeriod,0,MODE_SMA,PRICE_CLOSE,j);
   }
   double WMA[10];
   for(int k=1;k<=10;k++){
      WMA[k] = iMA(NULL,0,WMAPeriod,0,MODE_LWMA,PRICE_CLOSE,k);
   }
   
   //Buy
   if(pos == 0       
      && SMA[1] > SMA[2] && SMA[2] > SMA[3] //&& SMA[3] > SMA[4] && SMA[4] > SMA[5]
      && WMA[2] < SMA[2] && WMA[1] > SMA[1]
      //&& Close[0] > Low[1]
   ) ret = 1;
   //Sell
   if(pos == 0       
      && SMA[1] < SMA[2] && SMA[2] < SMA[3] //&& SMA[3] < SMA[4] && SMA[4] < SMA[5]
      && WMA[2] > SMA[2] && WMA[1] < SMA[1] 
      //&& Close[0] < High[1]
   ) ret = -1;
   
   return(ret);
   
}


/*
エキジット関数
*/
void ExitPosition(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   datetime Ent_Time;
   int shift;
   double TP = 0.0;
   
   if(pos!=0){
      Ent_Time = OrderOpenTime();
      shift = iBarShift(NULL,0,Ent_Time); 
   }
   else{
      shift = 0;
   }
   
   if(pos > 0 && shift == 3){
      TP = MathMax(High[1],High[2]);
      TP = MathMax(TP,High[3]);
      Print("StopLevel:",MarketInfo(Symbol(), MODE_STOPLEVEL)*Point," Bid:",Bid," TP:",TP," bid-TP:",Bid-TP);
      if(MathAbs(Bid-TP)<MarketInfo(Symbol(), MODE_STOPLEVEL)*Point){TP=Bid+MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;}
      
      MyOrderModify(0,TP,magic);
   }
   if(pos < 0 && shift == 3){
      TP = MathMin(Low[1],Low[2]);
      TP = MathMin(TP,Low[3]);
      if(MathAbs(TP-Ask)<MarketInfo(Symbol(), MODE_STOPLEVEL)*Point){TP=Ask-MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;}
      MyOrderModify(0,TP,magic);
   }   
}

int start()
{
   bool newBar = IsNewBar();
   double SL;
   int sig_entry = EntrySignal(MAGIC);
   //ExitPosition(MAGIC);
   EdgeValidation(fileHandle,MAGIC);
   
   int lotsize = (AccountBalance()*AccountLeverage( ))/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   double order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   if (order_lots > 2.0 ) order_lots = 2.0;
   order_lots = 0.01;
   
   //Buy Order
   if(newBar==true && sig_entry > 0)
   {
      //SL = Low[1];
      SL = 0;
      if(MathAbs(Bid-SL)<MarketInfo(Symbol(), MODE_STOPLEVEL)*Point){SL=Bid-MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;}
      if(MyOrderSend(OP_BUY,order_lots,Ask,Slippage,SL,0,COMMENT,MAGIC))
      {
         //MySendMail(COMMENT+":Buy Order Executed",1);
      }
   }
   
   //Sell Order
   if(newBar==true && sig_entry < 0)
   {
      //SL = High[1];
      SL = 0;
      if(MathAbs(Ask-SL)<MarketInfo(Symbol(), MODE_STOPLEVEL)*Point){SL=Ask+MarketInfo(Symbol(), MODE_STOPLEVEL)*Point;}
      if(MyOrderSend(OP_SELL,order_lots,Bid,Slippage,SL,0,COMMENT,MAGIC))
      {
         //MySendMail(COMMENT+":Sell Order Executed",2);
      }
   }
   
   TimeStop_Exit_Force(Slippage,NULL,100,MAGIC);
   
   return(0);
}
