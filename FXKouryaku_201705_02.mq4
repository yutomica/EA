/*

# FXKouryaku_201705_02
3本の移動平均線/日足で大局を見極め、1時間足で参入
作成日：2018/3/17
更新日：2019/9/14

【チャート】：
・日足＋1時間足
・日足以上の期間で、長期的なトレンドが発生している通貨ペア

【テクニカル】：
・移動平均線（5SMA、25SMA、75SMA）

【ロジック】
・日足で強力なトレンドが発生していることを確認
　-日足が5SMAと連続して交わらずに推移
・1時間足の25SMAor75SMAに「タッチ」したら、トレンド方向に新規エントリー
・TP:
　-75SMAでEn→25SMA付近で利確
　-25SMAでEn→直近高値/安値で利確
・SL:直近の高値/安値

【改善点】
・「タッチ」の判定ロジックをどうするか？

*/

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>
//#include <Original/Application.mqh>
#include <Original/Basic.mqh>
#include <Original/DateAndTime.mqh>
#include <Original/LotSizing.mqh>
#include <Original/MyLib.mqh>

#define MAGIC 20180317
#define COMMENT "FXKouryaku_201705_3MA"

#define OBS_PERIOD PERIOD_D1
#define EXE_PERIOD PERIOD_H1

extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int FastMAPeriod = 5;
extern int MiddleMAPeriod = 25;
extern int SlowMAPeriod = 75;
extern int LookbackPeriod = 20;

double TP,SL;
int Index;

/*
エントリー関数
*/
int EntrySignal(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int ret = 0;
 
   double MA_Daily[10];
   for(int j=1;j<=10;j++){
      MA_Daily[j] = iMA(NULL,OBS_PERIOD,FastMAPeriod,0,MODE_SMA,PRICE_CLOSE,j);
   }
   double MA_Middle[10];
   for(int k=1;k<=10;k++){
      MA_Middle[k] = iMA(NULL,EXE_PERIOD,MiddleMAPeriod,0,MODE_SMA,PRICE_CLOSE,k);
   }
   double MA_Slow[10];
   for(int m=1;m<=10;m++){
      MA_Slow[m] = iMA(NULL,EXE_PERIOD,SlowMAPeriod,0,MODE_SMA,PRICE_CLOSE,m);
   }
   
   //BUY：25SMAタッチ
   if(pos == 0
      //&& MA_Daily[1] > MA_Daily[2] && MA_Daily[2] > MA_Daily[3] && MA_Daily[3] > MA_Daily[4] && MA_Daily[4] > MA_Daily[5]
      && iClose(NULL,OBS_PERIOD,1) > MA_Daily[1]
      && iClose(NULL,OBS_PERIOD,2) > MA_Daily[2]
      && iClose(NULL,OBS_PERIOD,3) > MA_Daily[3]
      && iClose(NULL,OBS_PERIOD,4) > MA_Daily[4]
      && iClose(NULL,OBS_PERIOD,5) > MA_Daily[5]
      && MA_Middle[3] < MA_Middle[2] && MA_Middle[2] < MA_Middle[1]
      && iLow(NULL,EXE_PERIOD,3) < MA_Middle[3]
      && iLow(NULL,EXE_PERIOD,2) < MA_Middle[2]
      && iClose(NULL,EXE_PERIOD,1) > MA_Middle[1]
   ) ret = 1;
   //BUY：75SMAタッチ
   if(pos == 0
      //&& MA_Daily[1] > MA_Daily[2] && MA_Daily[2] > MA_Daily[3] && MA_Daily[3] > MA_Daily[4] && MA_Daily[4] > MA_Daily[5]
      && iClose(NULL,OBS_PERIOD,1) > MA_Daily[1]
      && iClose(NULL,OBS_PERIOD,2) > MA_Daily[2]
      && iClose(NULL,OBS_PERIOD,3) > MA_Daily[3]
      && iClose(NULL,OBS_PERIOD,4) > MA_Daily[4]
      && iClose(NULL,OBS_PERIOD,5) > MA_Daily[5]
      && iLow(NULL,EXE_PERIOD,3) < MA_Slow[3]
      && iLow(NULL,EXE_PERIOD,2) < MA_Slow[2]
      && iClose(NULL,EXE_PERIOD,1) > MA_Slow[1]
   ) ret = 2;
   
   //Sell：25SMAタッチ
   if(pos == 0
      //&& MA_Daily[1] < MA_Daily[2] && MA_Daily[2] < MA_Daily[3] && MA_Daily[3] < MA_Daily[4] && MA_Daily[4] < MA_Daily[5]
      && iClose(NULL,OBS_PERIOD,1) < MA_Daily[1]
      && iClose(NULL,OBS_PERIOD,2) < MA_Daily[2]
      && iClose(NULL,OBS_PERIOD,3) < MA_Daily[3]
      && iClose(NULL,OBS_PERIOD,4) < MA_Daily[4]
      && iClose(NULL,OBS_PERIOD,5) < MA_Daily[5]
      && MA_Middle[3] > MA_Middle[2] && MA_Middle[2] > MA_Middle[1]
      && iHigh(NULL,EXE_PERIOD,3) > MA_Middle[3]
      && iHigh(NULL,EXE_PERIOD,2) > MA_Middle[2]
      && iClose(NULL,EXE_PERIOD,1) < MA_Middle[1]
   ) ret = -1;
   //Sell：75SMAタッチ
   if(pos == 0
      //&& MA_Daily[1] < MA_Daily[2] && MA_Daily[2] < MA_Daily[3] && MA_Daily[3] < MA_Daily[4] && MA_Daily[4] < MA_Daily[5]
      && iClose(NULL,OBS_PERIOD,1) < MA_Daily[1]
      && iClose(NULL,OBS_PERIOD,2) < MA_Daily[2]
      && iClose(NULL,OBS_PERIOD,3) < MA_Daily[3]
      && iClose(NULL,OBS_PERIOD,4) < MA_Daily[4]
      && iClose(NULL,OBS_PERIOD,5) < MA_Daily[5]
      && iHigh(NULL,EXE_PERIOD,3) > MA_Slow[3]
      && iHigh(NULL,EXE_PERIOD,2) > MA_Slow[2]
      && iClose(NULL,EXE_PERIOD,1) < MA_Slow[1]
   ) ret = -2;
   
   return(ret);
   
}


int start()
{
   bool newBar = IsNewBar();

   double prices[10];
   int sig_entry = EntrySignal(MAGIC);
   
   int lotsize = (AccountBalance()*AccountLeverage( ))/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   double order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   if (order_lots > 2.0 ) order_lots = 2.0;
   order_lots = 0.01;
   
   //Buy Order
   if(newBar==true && sig_entry==1)
   {   
      Index = iLowest(NULL,EXE_PERIOD,MODE_LOW,LookbackPeriod,1);
      SL = iLow(NULL,EXE_PERIOD,Index);
      Index = iHighest(NULL,EXE_PERIOD,MODE_HIGH,LookbackPeriod,1);
      TP = iHigh(NULL,EXE_PERIOD,Index);
      if(MyOrderSend(OP_BUY,order_lots,Ask,Slippage,SL,TP,COMMENT,MAGIC))
      {
         //MySendMail(COMMENT+":Buy Order Executed",1);
      }
   }
   
   //Sell Order
   if(newBar==true && sig_entry==-1)
   {
      Index = iHighest(NULL,EXE_PERIOD,MODE_HIGH,LookbackPeriod,1);
      SL = iHigh(NULL,EXE_PERIOD,Index);
      Index = iLowest(NULL,EXE_PERIOD,MODE_LOW,LookbackPeriod,1);
      TP = iLow(NULL,EXE_PERIOD,Index);
      if(MyOrderSend(OP_SELL,order_lots,Bid,Slippage,SL,TP,COMMENT,MAGIC))   
      {
         //MySendMail(COMMENT+":Sell Order Executed",2);
      }
   }
   
   
   return(0);
}
