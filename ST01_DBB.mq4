/*

# ST01_DBB
作成日：2016/8/17
更新日：2017/2/25

・ボリンジャーバンド1σ～2σ間にCloseがある間ポジションを保有し続ける



*/

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>
//#include <Original/Application.mqh>
#include <Original/Basic.mqh>
#include <Original/DateAndTime.mqh>
#include <Original/LotSizing.mqh>
#include <Original/MyLib.mqh>

#define MAGIC 20160817
#define COMMENT "ST01_DBB"

extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int lookbackperiod = 10;
extern int BBPeriod = 40;
extern int entry_count = 1;   
extern int Maxpos = 3;

/*
エントリー関数
*/
int EntrySignal(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   double U1sig;double U2sig;
   double L1sig;double L2sig;
   int Buy_signal = 1;
   int Sell_signal = 1;
   int ret = 0;
   
   for(int i=entry_count;i>=1;i--){
      U1sig = iBands(NULL,0,BBPeriod,1,0,PRICE_CLOSE,MODE_UPPER,i);
      U2sig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,i);
      L1sig = iBands(NULL,0,BBPeriod,1,0,PRICE_CLOSE,MODE_LOWER,i);
      L2sig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,i);
      
      if (U1sig < Close[i]){
         Buy_signal = Buy_signal*1;
         Sell_signal = 0;
      }
      else if(L1sig > Close[i]){
         Sell_signal = Sell_signal*1;
         Buy_signal = 0;
      }
      else{
         Buy_signal = 0;
         Sell_signal = 0;
      }
   }
   
   if(pos <= 0 && Buy_signal == 1) ret = 1;
   if(pos >= 0 && Sell_signal == 1) ret = -1;
   
   return(ret);
}

/*
エキジット関数
*/
void ExitPosition(int magic)
{
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   double U1sig;double U2sig;double L1sig;double L2sig;double Midsig;
   int ret = 0;

   U1sig = iBands(NULL,0,BBPeriod,1,0,PRICE_CLOSE,MODE_UPPER,1);
   U2sig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,1);
   L1sig = iBands(NULL,0,BBPeriod,1,0,PRICE_CLOSE,MODE_LOWER,1);
   L2sig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,1);
   Midsig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_MAIN,1);

   //Buy Close
   if(pos > 0 && Close[1] < U1sig)ret = 1;

   //Sell Close
   if(pos < 0 && Close[1] > L1sig) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

}

/*
オーダーキャンセル
*/
void CancelOrder(int magic){
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   double U1sig;double U2sig;double L1sig;double L2sig;double Midsig;
   int ret = 0;

   U1sig = iBands(NULL,0,BBPeriod,1,0,PRICE_CLOSE,MODE_UPPER,1);
   U2sig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,1);
   L1sig = iBands(NULL,0,BBPeriod,1,0,PRICE_CLOSE,MODE_LOWER,1);
   L2sig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,1);
   Midsig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_MAIN,1);

   //Buy Close
   if(pos > 0 && Close[1] < U1sig)ret = 1;

   //Sell Close
   if(pos < 0 && Close[1] > L1sig) ret = -1;

   if(ret!=0) MyOrderClose(Slippage,magic);

}


/*
フィルタ関数
*/
/*
extern int ADXPeriod = 40;
extern double ADXRatio = 30.0;
int FilterSignal(int signal)
{
   double ADXFilter = iADX(NULL,0,ADXPeriod,PRICE_CLOSE,0,0);
   int ret = 0;
   
   if(signal>0 && ADXFilter > ADXRatio) ret = signal;
   if(signal<0 && ADXFilter > ADXRatio) ret = signal;
   
   return(ret);

}
*/

/*
フィルタ関数
*/
int FilterSignal(int signal)
{
   int ret = 0;
   string IndicatorName ="Heiken Ashi";
   double open_Day1 = iCustom(NULL,1440,IndicatorName,2,1);
   double Close_Day1 = iCustom(NULL,1440,IndicatorName,3,1);
   double Difference_Day1 = Close_Day1 - open_Day1;
   double open_Day2 = iCustom(NULL,1440,IndicatorName,2,2);
   double Close_Day2 = iCustom(NULL,1440,IndicatorName,3,2);
   double Difference_Day2 = Close_Day2 - open_Day2;
   
   if(signal>0 && Difference_Day2>0 && Difference_Day1>0 ) ret = signal;
   if(signal<0 && Difference_Day2<0 && Difference_Day1<0 ) ret = signal;
   
   return(ret);

}


int start()
{
   double order_price;double sl_price;
   double U1sig;double U2sig;
   double L1sig;double L2sig;
   double pos = MyCurrentOrders(MY_OPENPOS,MAGIC);
   int Buy_signal = 1;
   int Sell_signal = 1;
   int signal = 0;
   
   bool newBar = IsNewBar();
      
   //ExitPosition(MAGIC);
   //int sig_entry = EntrySignal(MAGIC);
   
   /*シグナル判定*/   
   for(int i=entry_count;i>=1;i--){
      U1sig = iBands(NULL,0,BBPeriod,1,0,PRICE_CLOSE,MODE_UPPER,i);
      U2sig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,i);
      L1sig = iBands(NULL,0,BBPeriod,1,0,PRICE_CLOSE,MODE_LOWER,i);
      L2sig = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,i);
      
      if (U1sig < Close[i]){
         Buy_signal = Buy_signal*1;
         Sell_signal = 0;
      }
      else if(L1sig > Close[i]){
         Sell_signal = Sell_signal*1;
         Buy_signal = 0;
      }
      else{
         Buy_signal = 0;
         Sell_signal = 0;
      }
   }
   if(pos <= 0 && Buy_signal == 1) signal = 1;
   if(pos >= 0 && Sell_signal == 1) signal = -1;
   
   //sig_entry = FilterSignal(sig_entry);
   
   //ロット数計算
   int lotsize = (AccountBalance()*AccountLeverage())/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   double order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   if (order_lots > 2.0 ) order_lots = 2.0;
   //Print("lotsize=",lotsize," order_lots=",order_lots);
   order_lots = 0.01;
   
   
   //BuyStop Order
   if(/*newBar==True &&*/ Buy_signal > 0 && MyCurrentOrders(OP_BUYSTOP,MAGIC)==0 && OrdersTotal() <= Maxpos)
   {
      order_price = iHigh(NULL,0,iHighest(NULL,0,MODE_HIGH,lookbackperiod,1));
      sl_price = iLow(NULL,0,iHighest(NULL,0,MODE_HIGH,lookbackperiod,1));
      //MyOrderSend(OP_BUYSTOP,order_lots,order_price,Slippage,sl_price-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,0,COMMENT,MAGIC);
      MyOrderSend(OP_BUYSTOP,order_lots,order_price,Slippage,0,0,COMMENT,MAGIC);
   }
   
   //SellStop Order
   if(/*newBar==True &&*/ Sell_signal > 0 && MyCurrentOrders(OP_SELLSTOP,MAGIC)==0 && OrdersTotal() <= Maxpos)
   {
      order_price = iLow(NULL,0,iLowest(NULL,0,MODE_LOW,lookbackperiod,1));
      sl_price = iHigh(NULL,0,iLowest(NULL,0,MODE_LOW,lookbackperiod,1));
      //MyOrderSend(OP_SELLSTOP,order_lots,order_price,Slippage,sl_price+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,0,COMMENT,MAGIC);
      MyOrderSend(OP_SELLSTOP,order_lots,order_price,Slippage,0,0,COMMENT,MAGIC);
  
   }
   
   //Order Cancel
   if(Buy_signal==0 && Sell_signal==0)
   {
      MyOrderDelete(MAGIC);
      MyOrderClose(Slippage,MAGIC);
   }
   
   return(0);
}



