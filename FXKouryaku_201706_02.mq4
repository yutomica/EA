/*

# FXKouryaku_201706_SMAMACD2
移動平均線（SMA）＋MACD2
作成日：2018/4/21
更新日：2019/9/14

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

【改善点】
・MACDの変動が小さいときにダマシが多い

*/

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>
//#include <Original/Application.mqh>
#include <Original/Basic.mqh>
#include <Original/DateAndTime.mqh>
#include <Original/LotSizing.mqh>
#include <Original/MyLib.mqh>

#define MAGIC 20180421
#define COMMENT "FXKouryaku_201706_02"


extern double Safety_ratio = 3.0;
extern int Slippage = 3;

extern int FastMAPeriod = 55;
extern int SlowMAPeriod = 90;
extern double SLRatio = 0.05;


/*
エントリー関数
*/
int EntrySignal(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int ret = 0;
   
   double SlowMA[10];
   for(int j=1;j<=10;j++){
      SlowMA[j] = iMA(NULL,0,SlowMAPeriod,0,MODE_SMA,PRICE_CLOSE,j);
   }
   double FastMA[10];
   for(int k=1;k<=10;k++){
      FastMA[k] = iMA(NULL,0,FastMAPeriod,0,MODE_SMA,PRICE_CLOSE,k);
   }
   double MACD[10];
   for(int l=1;l<=10;l++){
      MACD[l] = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,l);
   }
   double MACDSIG[10];
   for(int m=1;m<=10;m++){
      MACDSIG[m] = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,m);
   }
   
   /*Buy*/
   if(pos <= 0 
      //&& SlowMA[1] > SlowMA[2] //&& SlowMA[2] > SlowMA[3] //&& SlowMA[3] > SlowMA[4]
      //&& FastMA[1] > FastMA[2] //&& FastMA[2] > FastMA[3] //&& FastMA[3] > FastMA[4]
      && FastMA[1] > SlowMA[1] && FastMA[2] > SlowMA[2] //&& FastMA[3] > SlowMA[3] && FastMA[4] > SlowMA[4]
      && Close[1] > FastMA[1]
      && MACD[2] < MACDSIG[2] && MACD[1] > MACDSIG[1]
   ) ret = 1;
   
   /*Sell*/
   if(pos >= 0 
      //&& SlowMA[1] < SlowMA[2] //&& SlowMA[2] < SlowMA[3] //&& SlowMA[3] < SlowMA[4]
      //&& FastMA[1] < FastMA[2] //&& FastMA[2] < FastMA[3] //&& FastMA[3] < FastMA[4]
      && FastMA[1] < SlowMA[1] && FastMA[2] < SlowMA[2] //&& FastMA[3] < SlowMA[3] && FastMA[4] < SlowMA[4]
      && Close[1] < FastMA[1]
      && MACD[2] > MACDSIG[2] && MACD[1] < MACDSIG[1]
   ) ret = -1;
   
   return(ret);
   
}

/*
エキジット関数
*/
void ExitPosition(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int ret = 0;
   double MACD[10];
   for(int l=1;l<=10;l++){
      MACD[l] = iMACD(NULL,0,12,26,9,PRICE_CLOSE,0,l);
   }
   double MACDSIG[10];
   for(int m=1;m<=10;m++){
      MACDSIG[m] = iMACD(NULL,0,12,26,9,PRICE_CLOSE,1,m);
   }

   //Buy Close
   if(pos > 0 && MACD[2] > MACDSIG[2] && MACD[1] < MACDSIG[1])ret = 1;

   //Sell Close
   if(pos < 0 && MACD[2] < MACDSIG[2] && MACD[1] > MACDSIG[1]) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

}

int start()
{
   bool newBar = IsNewBar();
   int sig_entry = EntrySignal(MAGIC);
   ExitPosition(MAGIC);
   
   int lotsize = (AccountBalance()*AccountLeverage( ))/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   double order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   if (order_lots > 2.0 ) order_lots = 2.0;
   order_lots = 0.01;
   
   double SL = 0;

   //Buy Order
   if(newBar==true && sig_entry > 0)
   {
      SL = SLRatio*AccountBalance()/MarketInfo(Symbol(),MODE_LOTSIZE)/order_lots;
      MyOrderSend(OP_BUY,order_lots,Ask,Slippage,Ask-SL,0,COMMENT,MAGIC);
   }
   
   //Sell Order
   if(newBar==true && sig_entry < 0)
   {
      SL = SLRatio*AccountBalance()/MarketInfo(Symbol(),MODE_LOTSIZE)/order_lots;
      MyOrderSend(OP_SELL,order_lots,Bid,Slippage,Bid+SL,0,COMMENT,MAGIC);
   }
   
   return(0);
}
