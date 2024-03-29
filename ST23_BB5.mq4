/*

# ST23_BB%
ボリンジャーファイブ＋リバースエントリー(FXKouryaku_2017_01の派生)
作成日：2019/9/22
更新日：2019//

【チャート】：
・4時間足
・（ねらい目）スプレッドが2～3pipsでボラティリティの高い通貨ペア

【テクニカル】：
・ボリンジャーバンド(期間5、偏差2)

【ロジック】：
・ボリンジャーバンド(期間5、偏差2)が収束し、上下のバンドが平行になるのを待つ。
・平行になったら、バンドの20pips上/下に買/売の逆指値注文を入れる
・どちらかの注文が約定したら、もう一方はキャンセル。
・TP:エントリーから20-30pips。
・SL:反対側の逆指値を損切りポイントにする。

【改善点】
・SLの位置：反対側の逆指値ではなく、BB_MAINに設定
・ボリンジャーバンドの収束判定方法

*/

#include <stderror.mqh>
#include <stdlib.mqh>
#include <WinUser32.mqh>
//#include <Original/Application.mqh>
#include <Original/Basic.mqh>
#include <Original/DateAndTime.mqh>
#include <Original/LotSizing.mqh>
#include <Original/MyLib.mqh>
#include <Original/TimeStop.mqh>
#include <Original/Tracker.mqh>

#define MAGIC 20190922
#define COMMENT "ST23_BB5"


extern double Safety_ratio = 3.0;
extern int Slippage = 3;
extern int BBPeriod = 5;
extern int ATRPeriod = 3;
extern int TPPips = 20;
extern int lookbackbars = 5;

double U2sig[10];
double L2sig[10];
double stop_width;
double atr;
double buy_entry_price;
double sell_entry_price;
double SL,TP;
int fileHandle;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  if(Digits == 3 || Digits == 5){
   TPPips *= 10;
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
   double ppos = MyCurrentOrders(MY_PENDPOS, magic);
   int ret = 0;
   
   for(int j=1;j<=10;j++){
      U2sig[j] = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,j);
   }
   
   for(int k=1;k<=10;k++){
      L2sig[k] = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,k);
   }
   
   //ボリンジャーバンドの収束を判定
   if(pos == 0 && ppos == 0
      && U2sig[6] - L2sig[6] > U2sig[5] - L2sig[5] 
      && U2sig[5] - L2sig[5] > U2sig[4] - L2sig[4] 
      && U2sig[4] - L2sig[4] > U2sig[3] - L2sig[3] 
      && U2sig[3] - L2sig[3] > U2sig[2] - L2sig[2]
      && U2sig[2] - L2sig[2] > U2sig[1] - L2sig[1]
   ) ret = 1;
   
   return(ret);
   
}


int start()
{
   bool newBar = IsNewBar();
   int sig_entry = EntrySignal(MAGIC);
   Tracker(fileHandle,MAGIC);
   
   int lotsize = (AccountBalance()*AccountLeverage( ))/(Bid*MarketInfo(Symbol(), MODE_LOTSIZE)*Safety_ratio)/MarketInfo(Symbol(), MODE_MINLOT);
   double order_lots = lotsize*MarketInfo(Symbol(), MODE_MINLOT);
   if (order_lots > 2.0 ) order_lots = 2.0;
   order_lots = 0.01;

   if(newBar==true && sig_entry > 0){
      stop_width = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
      U2sig[1] = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_UPPER,1);      
      L2sig[1] = iBands(NULL,0,BBPeriod,2,0,PRICE_CLOSE,MODE_LOWER,1);
      atr = iATR(Symbol(),NULL,ATRPeriod,1);
      buy_entry_price = U2sig[1]+atr*0.5+stop_width;
      sell_entry_price = L2sig[1]-atr*0.5-stop_width;
      //Print("close=",Close[1]," buy_en_price=",buy_entry_price," sell_en_price=",sell_entry_price);
      //MyOrderSend(OP_BUYSTOP, order_lots, buy_entry_price, Slippage, sell_entry_price, buy_entry_price+TPPips*Point, COMMENT, MAGIC);
      //MyOrderSend(OP_SELLSTOP, order_lots, sell_entry_price, Slippage, buy_entry_price, sell_entry_price-TPPips*Point, COMMENT, MAGIC);
      MyOrderSend(OP_BUYSTOP, order_lots, buy_entry_price, Slippage, 0, 0, COMMENT, MAGIC);
      MyOrderSend(OP_SELLSTOP, order_lots, sell_entry_price, Slippage, 0, 0, COMMENT, MAGIC);
   }
   
   if(MyCurrentOrders(MY_PENDPOS, MAGIC)==order_lots){MyOrderDelete(MAGIC);}

   
   //TrailingStop
   //MyTrailingStop(TSPoint,MAGIC);
   TimeStop_Exit_Force(Slippage,NULL,100,MAGIC);
   
   return(0);
}
