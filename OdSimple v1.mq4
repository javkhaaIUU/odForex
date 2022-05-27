//+------------------------------------------------------------------+
//|                                                    Od_Version2.4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Enkh-Od and Javkhlantugs"
#property link "javkhaa8674@gmail.com"

// inputal variables
input string     sepatator1              = "------General settings-------";
input double     TakeProfit              = 0.5; 
input double     StopLoss                = 0.5;
input double     FirstUpPrice            = 1.5000;
input double     FirstDownPrice          = 1.0000;

input double     LotSize                 = 0.01; // Лотын хэмжээ
input int        TestSpeed               = 5000;  // Тестийн хурд
input int        Slippage                = 3;    // Ханшийн гулсалтын хэмжээ
input int        MagicNumber             = 23310; 

input string     separator5              = "------ Menu settings ------";
input bool       showMenu                = true;
input color      menuColor               = Yellow; 
input color      variablesColor          = Red;
input int        font                    = 10;


input string     separator6              =  "------ ZigZag settings ------";
input int        TimeFrame               =60;
input int        ExtDepth                =12;
input int        ExtDeviation            =5;
input int        ExtBackstep             =3;

// Global variables
double pips,Lots,LastBuyPrice,LastSellPrice,UP,DOWN;
double Peak_High,Peak_Low,iLots;
int LowCandle,HighCandle,ticket,cnt,NumberOfTrades,Speed;
int Buytotal, Selltotal, BuyPendingTotal, SellPendingTotal;
bool BuyOrderPlaced=false;
bool SellOrderPlaced=false;
bool HedgeBuyTrade=false,HedgePendingBool=false;
bool HedgeSellTrade=false;
bool MA_Buy=false;
bool MA_Sell=false, Max_Hedge=false;
double EquityMenu,BalanceMenu,Buymenulots,Sellmenulots,profitMenu,MaxEquityMenu,menulots;
string EAName="Od";
int medzera=8;
double LastBuyTakeProfit,LastSellTakeProfit,LastBuyHedgeTakeProfit,LastSellHedgeTakeProfit,AllProfit;
bool BuyPendingOrderPlaced=false,SellPendingOrderPlaced=false;

bool zigzagStart=false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   pips = RealPipPoint(_Symbol);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{ 
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

   if(IsNewCandle()){
      //Check use functions          
      ZigZagSignal();
      if(showMenu) DrawMenu();
      Buytotal=CountBuyTrades();
	  Selltotal=CountSellTrades();
	  BuyPendingTotal=CountBuyPendingTrades();
	  SellPendingTotal=CountSellPendingTrades();
      double AskPrice=MarketInfo(Symbol(),MODE_ASK);
      double BidPrice=MarketInfo(Symbol(),MODE_BID);

      double static TPBuyHit, TPSellHit;
      double static SLBuyHit, SLSellHit;
      
      double static buyOpenPrice, sellOpenPrice;

     // if(showMenu) {profitMenu=TotalProfit();ReDrawMenu();}
        if(Buytotal+Selltotal>0){
            ZigZagSignal();
        }  
        
        
        for(int i=TestSpeed;i>0;i--)
        
        Comment(i+"\nBuyPendingTotal: "+(string)BuyPendingTotal+"\nSellPendingTotal: "+(string)SellPendingTotal+
                    "\nBuytotal "+(string)Buytotal+"\nSelltotal: "+(string)Selltotal+
                    "\nTPbuyhit"+(string)TPBuyHit+"\nTPsellHit"+(string)TPSellHit
                    
                    
                    );
        
      //--------------------------------------MAIN TRADE-------------------------------------------------------------------------
    
        if(FirstUpPrice<=AskPrice){
            BuyOrderPlaced=true;
        }
        if(FirstDownPrice>=BidPrice){
            SellOrderPlaced=true;
        }

        //  Ali neg order n TP tsohih uyed nuguu pending ustgagdah heseg
        if(BuyOrderPlaced && TPBuyHit<=BidPrice){
         ClosePendingOrders();   
         zigzagStart=true;  

        }  

        if(SellOrderPlaced && TPSellHit>=AskPrice) {
         ClosePendingOrders();
         zigzagStart=true; 
        } 

        if(zigzagStart){
            if(AskPrice<=UP && BuyPendingTotal==0){
                ticket = OrderSend(_Symbol,OP_BUYSTOP,LotSize,UP,3,UP-(UP-DOWN)*StopLoss,UP+(UP-DOWN)*TakeProfit,NULL,MagicNumber,0,clrGreen);
                 if(ticket<0) 
                 Print("Buy OrderSend failed with error #",GetLastError());
                 else {
                    BuyPendingOrderPlaced=true; 
                    TPBuyHit=UP+(UP-DOWN)*TakeProfit;
                    buyOpenPrice=UP;
                 }
            }
            if(BidPrice>=DOWN && DOWN!=0 && SellPendingTotal==0){
                ticket = OrderSend(_Symbol,OP_SELLSTOP,LotSize,DOWN,3,DOWN+(UP-DOWN)*StopLoss,DOWN-(UP-DOWN)*TakeProfit,NULL,MagicNumber,0,clrRed);
                if(ticket<0) 
                Print("Sell OrderSend failed with error #",GetLastError());
                else {
                    SellPendingOrderPlaced=true;
                    TPSellHit=DOWN-(UP-DOWN)*TakeProfit;
                    sellOpenPrice=DOWN;
                }   
            }
        }

        if(!zigzagStart){
            //  Ali neg order n SL tsohih uyed dahij pending tawih heseg
            if(Buytotal==0 && BuyPendingTotal==0 && SellPendingTotal==1){
                ticket = OrderSend(_Symbol,OP_BUYSTOP,LotSize,FirstUpPrice,3,FirstUpPrice-(FirstUpPrice-FirstDownPrice)*StopLoss,FirstUpPrice+(FirstUpPrice-FirstDownPrice)*TakeProfit,NULL,MagicNumber,0,clrGreen);
                if(ticket<0) 
                Print("Buy OrderSend failed with error #",GetLastError());
                else {
                    BuyPendingOrderPlaced=true; 
                    TPBuyHit=FirstUpPrice+(FirstUpPrice-FirstDownPrice)*TakeProfit;
                }    
            }
            if(Selltotal==0 && SellPendingTotal==0 && BuyPendingTotal==1){
                ticket = OrderSend(_Symbol,OP_SELLSTOP,LotSize,FirstDownPrice,3,FirstDownPrice+(FirstUpPrice-FirstDownPrice)*StopLoss,FirstDownPrice-(FirstUpPrice-FirstDownPrice)*TakeProfit,NULL,MagicNumber,0,clrRed);
                if(ticket<0) 
                Print("Sell OrderSend failed with error #",GetLastError());
                else {
                    SellPendingOrderPlaced=true;
                    TPSellHit=FirstDownPrice-(FirstUpPrice-FirstDownPrice)*TakeProfit;
                }         
            }
            
            //  Garaar oruulsan pending zahialguud  
            if(!BuyOrderPlaced && !SellOrderPlaced){
            if(BuyPendingTotal==0 && SellPendingTotal==0 && Buytotal==0 && Selltotal==0){   
                ticket = OrderSend(_Symbol,OP_BUYSTOP,LotSize,FirstUpPrice,3,FirstUpPrice-(FirstUpPrice-FirstDownPrice)*StopLoss,FirstUpPrice+(FirstUpPrice-FirstDownPrice)*TakeProfit,NULL,MagicNumber,0,clrGreen);
                if(ticket<0) 
                Print("Buy OrderSend failed with error #",GetLastError());
                else {
                    BuyPendingOrderPlaced=true; 
                    TPBuyHit=FirstUpPrice+(FirstUpPrice-FirstDownPrice)*TakeProfit;
                }
                ticket = OrderSend(_Symbol,OP_SELLSTOP,LotSize,FirstDownPrice,3,FirstDownPrice+(FirstUpPrice-FirstDownPrice)*StopLoss,FirstDownPrice-(FirstUpPrice-FirstDownPrice)*TakeProfit,NULL,MagicNumber,0,clrRed);
                if(ticket<0) 
                Print("Sell OrderSend failed with error #",GetLastError());
                else {
                    SellPendingOrderPlaced=true;
                    TPSellHit=FirstDownPrice-(FirstUpPrice-FirstDownPrice)*TakeProfit;
                }    
            }
            }
        }    
    }
}

//-----------------------------------------------USER DEFINED FUNCTION START------------------------------------------------------------------------		
		
// Pip Point Function
double RealPipPoint(string Currency){
		int CalcDigits = MarketInfo(Currency,MODE_DIGITS);
		if(CalcDigits == 2 || CalcDigits == 3) double CalcPoint = 0.01;
		else if(CalcDigits == 4 || CalcDigits == 5) CalcPoint = 0.0001;
		return(CalcPoint);
}
        
//-----------------------------------------------USER DEFINED FUNCTION START------------------------------------------------------------------------ 
bool IsNewCandle(){
      static int BarsOnChart=0;
      if(Bars == BarsOnChart)
      return(false);
      BarsOnChart = Bars;
      return(true);
}
//-----------------------------------------------USER DEFINED FUNCTION START------------------------------------------------------------------------ 
int CountBuyTrades()
    {
            int buycount=0;
            int trade;
            for(trade=OrdersTotal()-1;trade>=0;trade--)
              {
               if(OrderSelect(trade,SELECT_BY_POS,MODE_TRADES))
                  {
                     if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=MagicNumber)
                        continue;
                     if(OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber)
                        if(OrderType()==OP_BUY)
                            buycount++;
                  }
              }
            return(buycount);
    }
//----------------------------------------------------------------------------------------------------------------------
int CountSellTrades()
    {
            int sellcount=0;
            int trade;
            for(trade=OrdersTotal()-1;trade>=0;trade--)
              {
               if(OrderSelect(trade,SELECT_BY_POS,MODE_TRADES))
                  {
                     if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=MagicNumber)
                        continue;
                     if(OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber)
                         if(OrderType()==OP_SELL)
                            sellcount++;
                  }
              }
            return(sellcount);
    }
//----------------------------------------------------------------------------------------------------------------------

double fGetLots(int TradeCount, int HedgeCount)
   { 
     double tLots;
     if(HedgeCount<1)
         {
            if(TradeCount==1) tLots=0.03; 
            if(TradeCount==2) tLots=0.05; 
            if(TradeCount==3) tLots=0.08;
         }
     if(HedgeCount>0)
         {
            if(TradeCount==1)
                switch(HedgeCount)
                   {
                     case 1: tLots=0.06; break;
                     case 2: tLots=0.10; break;
                     case 3: tLots=0.17; break;
                     case 4: tLots=0.30; break;
                     case 5: tLots=0.16; break;
                     case 6: tLots=0.19; break;
                     case 7: tLots=0.24; break;
                     case 8: tLots=0.32; break;
                     case 9: tLots=0.35; break;
                     case 10:tLots=0.4 ; break;
                     case 11:tLots=0.48; break;
                     case 12:tLots=0.52; break;
                     case 13:tLots=0.57; break;
                     case 14:tLots=0.65; break;
                     case 15:tLots=0.68; break;
                     case 16:tLots=0.73; break;
                     case 17:tLots=0.81; break;
                     case 18:tLots=0.84; break;
                     case 19:tLots=0.89; break;
              
                     default: Print("Wrong Lot");
                  }
          
           if(TradeCount==2)
               switch(HedgeCount)
                   {
 
                     case 1: tLots=0.08; break;
                     case 2: tLots=0.11; break;
                     case 3: tLots=0.13; break;
                     case 4: tLots=0.16; break;
                     case 5: tLots=0.19; break;
                     case 6: tLots=0.24; break;
                     case 7: tLots=0.32; break;
                     case 8:tLots=0.35; break;
                     case 9:tLots=0.4 ; break;
                     case 10:tLots=0.48; break;
                     case 11:tLots=0.52; break;
                     case 12:tLots=0.57; break;
                     case 13:tLots=0.65; break;
                     case 14:tLots=0.68; break;
                     case 15:tLots=0.73; break;
                     case 16:tLots=0.81; break;
                     case 17:tLots=0.84; break;
                     case 18:tLots=0.89; break;
                     case 19:tLots=0.97; break;
  
              
                     default: Print("Wrong Lot");
                  }
                     
          if(TradeCount==3) 
               switch(HedgeCount)
                   {
                     case 1: tLots=0.11; break;
                     case 2: tLots=0.13; break;
                     case 3: tLots=0.16; break;
                     case 4: tLots=0.19; break;
                     case 5: tLots=0.24; break;
                     case 6: tLots=0.32; break;
                     case 7:tLots=0.35; break;
                     case 8:tLots=0.4 ; break;
                     case 9:tLots=0.48; break;
                     case 10:tLots=0.52; break;
                     case 11:tLots=0.57; break;
                     case 12:tLots=0.65; break;
                     case 13:tLots=0.68; break;
                     case 14:tLots=0.73; break;
                     case 15:tLots=0.81; break;
                     case 16:tLots=0.84; break;
                     case 17:tLots=0.89; break;
                     case 18:tLots=0.97; break;
                     case 19:tLots=1   ; break;   
              
                     default: Print("Wrong Lot");
                  }
               
     
       }
    return(tLots);  
   }

//----------------------------------------------------------------------------------------------------------------------
double FindLastBuyPrice()
   {
    double oldorderopenprice=0, orderprice;
    int oldticketnumber=0, ticketnumber;
            for(cnt=OrdersTotal()-1;cnt>=0;cnt--)
              {
               if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
               {
                  if(OrderSymbol()!=Symbol())
                     continue;
                  if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)
                  {
                   ticketnumber=OrderTicket();
                   if(ticketnumber>oldticketnumber)
                    {
                     orderprice=OrderOpenPrice();
                     oldorderopenprice=orderprice;
                     oldticketnumber=ticketnumber;
                    }
                  }
                }
              }
      return(orderprice);
   }
  
//------------------------------------------------------------------------------------------------------------------------  
double FindLastSellPrice()
   {
     double oldorderopenprice=0, orderprice;
     int oldticketnumber=0, ticketnumber;
            for(cnt=OrdersTotal()-1;cnt>=0;cnt--)
              {
               if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
               {
                if(OrderSymbol()!=Symbol())
                  continue;
                if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)
                 {
                  ticketnumber=OrderTicket();
                  if(ticketnumber>oldticketnumber)
                    {
                     orderprice=OrderOpenPrice();
                     oldorderopenprice=orderprice;
                     oldticketnumber=ticketnumber;
                    }
                 }
               } 
              }
      return(orderprice);
    } 
  

//-----------------------------------------------------------------------------------------------------------------------------

void DrawMenu()
   {
      ObjectCreate("name",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("OpenB",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("OpenBl",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("OpenS",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("OpenSl",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("BuyLotsl",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("BuyLots",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("SellLotsl",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("SellLots",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("Profitl",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("Profit",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("Equityl",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("Equity",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("MaxEquityl",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("MaxEquity",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("Balancel",OBJ_LABEL,0,0,0,0,0);
      ObjectCreate("Balance",OBJ_LABEL,0,0,0,0,0);

      medzera = 8;
      EquityMenu=AccountEquity();
      BalanceMenu=AccountBalance();

     ObjectSetText(	"name", "OD_Version 2", font+1, "Arial",menuColor);
     ObjectSet("name",OBJPROP_XDISTANCE,medzera*font);     
     ObjectSet("name",OBJPROP_YDISTANCE,10+font);
     ObjectSet("name",OBJPROP_CORNER,1);
         
     ObjectSetText("OpenBl", "Buy Count: ", font, "Arial",menuColor);
     ObjectSet("OpenBl",OBJPROP_XDISTANCE,medzera*font);     
     ObjectSet("OpenBl",OBJPROP_YDISTANCE,10+2*(font+2));
     ObjectSet("OpenBl",OBJPROP_CORNER,1);
     
     ObjectSetText("OpenB",""+Buytotal, font, "Arial",variablesColor);
     ObjectSet("OpenB",OBJPROP_XDISTANCE,3*font);     
     ObjectSet("OpenB",OBJPROP_YDISTANCE,10+2*(font+2));
     ObjectSet("OpenB",OBJPROP_CORNER,1);
     
     ObjectSetText("OpenSl", "Sell Count: ", font, "Arial",menuColor);
     ObjectSet("OpenSl",OBJPROP_XDISTANCE,medzera*font);     
     ObjectSet("OpenSl",OBJPROP_YDISTANCE,10+3*(font+2));
     ObjectSet("OpenSl",OBJPROP_CORNER,1);
     
     ObjectSetText("OpenS", ""+Selltotal, font, "Arial",variablesColor);
     ObjectSet("OpenS",OBJPROP_XDISTANCE,3*font);     
     ObjectSet("OpenS",OBJPROP_YDISTANCE,10+3*(font+2));
     ObjectSet("OpenS",OBJPROP_CORNER,1);
     
     ObjectSetText("BuyLotsl", "BuyLots: ", font, "Arial",menuColor);
     ObjectSet("BuyLotsl",OBJPROP_XDISTANCE,medzera*font);     
     ObjectSet("BuyLotsl",OBJPROP_YDISTANCE,10+4*(font+2));
     ObjectSet("BuyLotsl",OBJPROP_CORNER,1);
     
     ObjectSetText("BuyLots", DoubleToStr(Buymenulots,2), font, "Arial",variablesColor);
     ObjectSet("BuyLots",OBJPROP_XDISTANCE,3*font);     
     ObjectSet("BuyLots",OBJPROP_YDISTANCE,10+4*(font+2));
     ObjectSet("BuyLots",OBJPROP_CORNER,1);
     
     ObjectSetText("SellLotsl", "SellLots: ", font, "Arial",menuColor);
     ObjectSet("SellLotsl",OBJPROP_XDISTANCE,medzera*font);     
     ObjectSet("SellLotsl",OBJPROP_YDISTANCE,10+5*(font+2));
     ObjectSet("SellLotsl",OBJPROP_CORNER,1);
     
     ObjectSetText("SellLots", DoubleToStr(Sellmenulots,2), font, "Arial",variablesColor);
     ObjectSet("SellLots",OBJPROP_XDISTANCE,3*font);     
     ObjectSet("SellLots",OBJPROP_YDISTANCE,10+5*(font+2));
     ObjectSet("SellLots",OBJPROP_CORNER,1);
     
     ObjectSetText("Profitl", "Profit: ", font, "Arial",menuColor);
     ObjectSet("Profitl",OBJPROP_XDISTANCE,medzera*font);     
     ObjectSet("Profitl",OBJPROP_YDISTANCE,10+6*(font+2));
     ObjectSet("Profitl",OBJPROP_CORNER,1);
     
     ObjectSetText("Profit", DoubleToStr(profitMenu,2), font, "Arial",variablesColor);
     ObjectSet("Profit",OBJPROP_XDISTANCE,3*font);     
     ObjectSet("Profit",OBJPROP_YDISTANCE,10+6*(font+2));
     ObjectSet("Profit",OBJPROP_CORNER,1);
     
     ObjectSetText("Equityl", "Equity: ", font, "Arial",menuColor);
     ObjectSet("Equityl",OBJPROP_XDISTANCE,medzera*font);     
     ObjectSet("Equityl",OBJPROP_YDISTANCE,10+7*(font+2));
     ObjectSet("Equityl",OBJPROP_CORNER,1);
     
     ObjectSetText("Equity", DoubleToStr(EquityMenu,2), font, "Arial",variablesColor);
     ObjectSet("Equity",OBJPROP_XDISTANCE,3*font);     
     ObjectSet("Equity",OBJPROP_YDISTANCE,10+7*(font+2));
     ObjectSet("Equity",OBJPROP_CORNER,1);
      
     ObjectSetText("MaxEquityl", "MaxEquity: ", font, "Arial",menuColor);
     ObjectSet("MaxEquityl",OBJPROP_XDISTANCE,medzera*font);     
     ObjectSet("MaxEquityl",OBJPROP_YDISTANCE,10+8*(font+2));
     ObjectSet("MaxEquityl",OBJPROP_CORNER,1);
     
     ObjectSetText("MaxEquity", DoubleToStr(MaxEquityMenu,2), font, "Arial",variablesColor);
     ObjectSet("MaxEquity",OBJPROP_XDISTANCE,3*font);     
     ObjectSet("MaxEquity",OBJPROP_YDISTANCE,10+8*(font+2));
     ObjectSet("MaxEquity",OBJPROP_CORNER,1); 
             
     ObjectSetText("Balancel", "Balance: ", font, "Arial",menuColor);
     ObjectSet("Balancel",OBJPROP_XDISTANCE,medzera*font);     
     ObjectSet("Balancel",OBJPROP_YDISTANCE,10+9*(font+2));
     ObjectSet("Balancel",OBJPROP_CORNER,1);
     
     ObjectSetText("Balance", DoubleToStr(BalanceMenu,2), font, "Arial",variablesColor);
     ObjectSet("Balance",OBJPROP_XDISTANCE,3*font);     
     ObjectSet("Balance",OBJPROP_YDISTANCE,10+9*(font+2));
     ObjectSet("Balance",OBJPROP_CORNER,1);
     
     
     
   }
//---------------------------------------------REDRAW MENU-------------------------------------------------------------------

void ReDrawMenu()
   {
    
       
    Buymenulots = AllBuyLots() ;
    Sellmenulots =AllSellLots();
    profitMenu=TotalProfit();
      
    
      if(MaxEquityMenu>=profitMenu)
         MaxEquityMenu=profitMenu; 
      
      
      
    EquityMenu=AccountEquity();
    BalanceMenu=AccountBalance();
     //    int BuySignal=MA_Buy;
     //    int SellSignal=MA_Sell;
      IntegerToString(Buytotal);
      IntegerToString(Selltotal);
      
      
      
     ObjectSetText("OpenB", ""+Buytotal, font, "Arial",variablesColor); 
     ObjectSetText("OpenS", ""+Selltotal, font, "Arial",variablesColor); 
     ObjectSetText("BuyLots", DoubleToStr(Buymenulots,2), font, "Arial",variablesColor);
     ObjectSetText("SellLots", DoubleToStr(Sellmenulots,2), font, "Arial",variablesColor);    
     ObjectSetText("Profit", DoubleToStr(profitMenu,2), font, "Arial",variablesColor);
     ObjectSetText("Equity", DoubleToStr(EquityMenu,2), font, "Arial",variablesColor);
     ObjectSetText("MaxEquity", DoubleToStr(MaxEquityMenu,2), font, "Arial",variablesColor);
     ObjectSetText("Balance", DoubleToStr(BalanceMenu,2), font, "Arial",variablesColor);
   }

//--------------------------------------------------------------------------------------------------------------------
double TotalProfit(){
   int TotalBuyProfit = 0;
   for(cnt= OrdersTotal()-1; cnt >= 0; cnt--)
   if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
      if(OrderSymbol()==Symbol())
         if(OrderType()==OP_BUY || OrderType() ==OP_SELL)
            TotalBuyProfit += OrderProfit()+OrderSwap()+OrderCommission();
   return (TotalBuyProfit);
}
//-------------------------------------------------------------------------------------------------------------------------------
void ClosePendingOrders(){
   Buytotal=CountBuyTrades();
   Selltotal=CountSellTrades();
   int BuyTicket=BuyLastTicket();
   int SellTicket=SellLastTicket();

    for(cnt=OrdersTotal()-1;cnt>=0;cnt--){
        if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
            if(OrderSymbol()==Symbol()) // check for symbol
                if(OrderType()==OP_SELLSTOP) 
                ticket = OrderDelete(OrderTicket());
    } 
    for(cnt=OrdersTotal()-1;cnt>=0;cnt--){
        if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
            if(OrderSymbol()==Symbol()) // check for symbol
                if(OrderType()==OP_BUYSTOP)
                ticket = OrderDelete(OrderTicket());
    }
} 
//-------------------------------------------------------------------------------------------------------------------------------
void LastTakeProfit(){
      for(cnt= OrdersTotal()-1; cnt >= 0; cnt--)
         if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
           {
             if(OrderSymbol()==Symbol()&& OrderMagicNumber()==MagicNumber)
               {
                if(OrderType()==OP_BUY) 
                  LastBuyTakeProfit++;
                if(OrderType() ==OP_SELL)
                  LastSellTakeProfit++;
               }
           }
	}
//----------------------------------------------------------------------------------------------------------------------	
int CountBuyPendingTrades()
    {
            int buycount=0;
            int trade;
            for(trade=OrdersTotal()-1;trade>=0;trade--)
              {
               if(OrderSelect(trade,SELECT_BY_POS,MODE_TRADES))
                  {
                     if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=MagicNumber)
                        continue;
                     if(OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber)
                        if(OrderType()==OP_BUYSTOP)
                            buycount++;
                  }
              }
            return(buycount);
    }
//----------------------------------------------------------------------------------------------------------------------
int CountSellPendingTrades()
    {
            int sellcount=0;
            int trade;
            for(trade=OrdersTotal()-1;trade>=0;trade--)
              {
               if(OrderSelect(trade,SELECT_BY_POS,MODE_TRADES))
                  {
                     if(OrderSymbol()!=Symbol()||OrderMagicNumber()!=MagicNumber)
                        continue;
                     if(OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber)
                         if(OrderType()==OP_SELLSTOP)
                            sellcount++;
                  }
              }
            return(sellcount);
    }

//-----------------------------------------------------------------------------------------------------------------------
int BuyLastTicket(){
    int total  = OrdersTotal();
    int oticket = 0;
      for (cnt = total-1 ; cnt >=0 ; cnt--)
      {
       if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
         if (OrderSymbol()==Symbol())
             if(OrderType()==OP_BUY)
                  if(OrderTicket()>oticket)
                     oticket=OrderTicket();
      }
    return (oticket);
}

int SellLastTicket(){
    int total  = OrdersTotal();
    int oticket = 0;
      for (cnt = total-1 ; cnt >=0 ; cnt--)
      {
       if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
         if (OrderSymbol()==Symbol())
             if(OrderType()==OP_SELL)
                  if(OrderTicket()>oticket)
                     oticket=OrderTicket();
      }
    return (oticket);
}
//------------------------------------------------------------------------------------------------------------------------

double CalculateProfit()
     {
            double cProfit=0;
            for(cnt=OrdersTotal()-1;cnt>=0;cnt--)
              {
               if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
                {
                  if(OrderSymbol()!=Symbol())
                     continue;
                  if(OrderSymbol()==Symbol())

                        {
                           cProfit=cProfit+OrderProfit()+OrderSwap();
                        }
                        
                }        
              }
            return(cProfit);
     }
     
//------------------------------------------------------------------------------------------------------------------------     
     
void CloseThisSymbolAll(){
            int trade,tClose;
            for(trade=OrdersTotal()-1;trade>=0;trade--)
              if(OrderSelect(trade,SELECT_BY_POS,MODE_TRADES))
                if(OrderSymbol()==Symbol())
                     {
                        if(OrderType()==OP_BUY)
                           {
                            tClose=OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,clrBlue);
                                if(tClose<0)
                                    Print("Order",OrderTicket(),"failed to close error",GetLastError());
                           }
                        if(OrderType()==OP_SELL)
                           {
                            tClose=OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,clrRed);
                                if(tClose<0)
                                    Print("Order",OrderTicket(),"failed to close error",GetLastError());
                           }
                     }
               Sleep(1000);
                
              
    }  
//---------------------------------------------------------------------------------------------------------------

void ModifyAllOrder()
   {     
         for(cnt=OrdersTotal()-1;cnt>=0;cnt--)
           if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
            if(OrderSymbol()==Symbol()&&OrderMagicNumber()==MagicNumber)
              {
               if(OrderType()==OP_BUY)
               if(OrderTakeProfit()!=0)
                  {
                    ticket=OrderModify(OrderTicket(),OrderOpenPrice(),0,0,0,Yellow);// set all positions to averaged levels
                    if(ticket<0)
                        Print(iLots,"Order Buy Modify Error: ",GetLastError());
                  }
               if(OrderType()==OP_SELL)
               if(OrderTakeProfit()!=0)
                  {        
                   ticket=OrderModify(OrderTicket(),OrderOpenPrice(),0,0,0,Yellow);// set all positions to averaged levels
                   if(ticket<0)
                        Print(iLots,"Order Sell Modify Error: ",GetLastError());
          
                  }
              }  

    }

//----------------------------------------------------------------------------------------------------------------------
void ZigZagSignal()
  {
   int TradeBar=0;
   int Ret=0;
   int Limit=500;
   int j=0, i=0;
   double Zig=0,Zag=0;
   double Zig_Cur=0,Zig_Prev=0;
   
   for(i=TradeBar;i<=Limit;i++)
      {
	      Zig_Cur=iCustom(NULL,0,"ZigZag",ExtDepth,ExtDeviation,ExtBackstep,0,i);
	      Zig_Prev=iCustom(NULL,0,"ZigZag",ExtDepth,ExtDeviation,ExtBackstep,0,i+1);
	      
	      if(Zig_Cur>0)
	         {
	            j=i;
	            Zig=Zig_Cur;
	            break;
	         }
      }

   for(i=j+1;i<=Limit;i++)
      {
	      Zig_Cur=iCustom(NULL,0,"ZigZag",ExtDepth,ExtDeviation,ExtBackstep,0,i);
	      Zig_Prev=iCustom(NULL,0,"ZigZag",ExtDepth,ExtDeviation,ExtBackstep,0,i+1);
	      
	      if(Zig_Cur>0)
	         {
	            break;
	         }
      }

   if(Zig>Zig_Cur)
      {
         DOWN=Zig_Cur;
      }
   
   if(DOWN<Zig_Cur)
      {
         UP=Zig_Cur;
      }

  }

//-------------------------------------------------------------------------------------------------------------------------------------
double AllBuyLots(){
    int total  = OrdersTotal();
    double lots = 0;
      for (cnt = total-1 ; cnt >=0 ; cnt--)
      {
       if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
         if (OrderSymbol()==Symbol())
             if(OrderType()==OP_BUY)
               lots+=OrderLots();
      }
    return (lots);
}
//------------------------------------------------------------------------------------------------------------------------------------
double AllSellLots(){
    int total  = OrdersTotal();
    double lots = 0;
      for (cnt = total-1 ; cnt >=0 ; cnt--)
      {
       if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
         if (OrderSymbol()==Symbol())
             if(OrderType()==OP_SELL)
               lots+=OrderLots();
      }
    return (lots);
}