/*

# FXKouryaku_201706_03
エンベロープ＋RSI/エンベローブを利用したカウンタートレード
作成日：2018/4/10
更新日：2019/9/14

【チャート】：
・1分足
・（ねらい目）ドル円、ユーロ円、ポンド円、USDCAD、USDAUD、USDEUR

【テクニカル】：
・エンベロープ（10EMA、偏差0.06）
・移動平均線（20EMA）
・RSI（10期間）

【ロジック】
・ローソク足の終値がエンベロープを下抜けるのを待つ
・RSIが30％以下なら買い
・TP：ローソク足の終値が20EMAを上に抜ける
・SL：エントリー価格から20Pips下降
・5分足でやる場合は、エンベロープ偏差を0.1に

【改善点】
・パラメータ調整が必要、カウンタートレードになっていない。

*/

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>
//#include <Original/Application.mqh>
#include <Original/Basic.mqh>
#include <Original/DateAndTime.mqh>
#include <Original/LotSizing.mqh>
#include <Original/MyLib.mqh>

#define MAGIC 20180410
#define COMMENT "FXKouryaku_201706_EnvRSI"


extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int EnvMAPeriod = 10;
extern double EnvDiv = 0.1;
extern int EMAPeriod = 20;
extern int RSIPeriod = 10;
extern int SLPips = 20;
extern double RSI_Level_U = 70.;
extern double RSI_Level_L = 30.;

double UEnv[3];
double LEnv[3];
double RSI[3];
double EMA[3];

void init(){
   if(Digits == 3 || Digits == 5){SLPips*=10;}
}

/*
エントリー関数
*/

int EntrySignal(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int ret = 0;
 
   
   for(int j=1;j<=3;j++){
      UEnv[j] = iEnvelopes(NULL,0,EnvMAPeriod,MODE_EMA,0,PRICE_CLOSE,EnvDiv,MODE_UPPER,j);
   }
   
   for(int k=1;k<=3;k++){
      LEnv[k] = iEnvelopes(NULL,0,EnvMAPeriod,MODE_EMA,0,PRICE_CLOSE,EnvDiv,MODE_LOWER,j);
   }
   
   for(int m=1;m<=3;m++){
      RSI[m] = iRSI(NULL,0,RSIPeriod,PRICE_CLOSE,m);
   }
   
   //Buy
   if(pos == 0
      //&& RSI[2] < 30
      && RSI[1] < RSI_Level_L
      && Close[1] < LEnv[1]
   ) ret = 1;
   //Sell
   if(pos == 0
      //&& RSI[2] > 70
      && RSI[1] > RSI_Level_U
      && Close[1] > UEnv[1]
   ) ret = -1;
   
   //if(ret<0){Print("close=",Close[1]," UEnv=",UEnv[1]);}
   return(ret);
   
}


/*
エキジット関数
*/
void ExitPosition(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   int ret = 0;
   
   for(int j=0;j<3;j++){
      EMA[j] = iMA(NULL,0,EMAPeriod,0,MODE_EMA,PRICE_CLOSE,j);
   }

   //Buy Close
   if(pos > 0 
      && Close[1] > EMA[1]
   )ret = 1;

   //Sell Close
   if(pos < 0 
      && Close[1] < EMA[1]
   ) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

}


int start()
{
   bool newBar = IsNewBar();
   ExitPosition(MAGIC);
   int sig_entry = EntrySignal(MAGIC);
   
   
   int lotsize = (AccountBalance()*AccountLeverage( ))/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   double order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   if (order_lots > 2.0 ) order_lots = 2.0;
   order_lots = 0.1;
   
   //Buy Order
   if(newBar==true && sig_entry > 0)
   {
      if(MyOrderSend(OP_BUY,order_lots,Ask,Slippage,Ask-SLPips*Point,0,COMMENT,MAGIC))
      {
         //MySendMail(COMMENT+":Buy Order Executed",1);
      }
   }
   //Sell Order
   if(newBar==true && sig_entry < 0)
   {
      if(MyOrderSend(OP_SELL,order_lots,Bid,Slippage,Bid+SLPips*Point,0,COMMENT,MAGIC))
      {
         //MySendMail(COMMENT+":Sell Order Executed",2);
      }
   }
   
   return(0);
}
