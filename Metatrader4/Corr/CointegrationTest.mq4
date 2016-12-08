//--------------------------------------------------------------------
// userindicator.mq4 
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property indicator_separate_window    // Indicator is drawn in the main window
#property indicator_buffers 1      // Number of buffers
#property indicator_color1 Red     // Color of the 1st line

input int windows = 150;
input string vstr= "USDJPY";

double Coi[];
double iFunc(string symbol,int timeframe, int start, int pos)
{
   double vpoint  = MarketInfo(symbol,MODE_POINT);
   //double vpoint =1;
   return (iClose(symbol,timeframe, start)-iOpen(symbol, timeframe, start+pos))/vpoint;
}

//iFunc(s1,0, 0, 1)-> P1
//iFunc(s1,0, 0, 2)-> P2

double cointegration(string symbol1, string symbol2, int start, int length)
{
   double res = 0.0;
   for(int i=0;i<length;i++)
   {
      double temp = (iFunc(symbol1, 0, start, i)-iFunc(symbol2,0, start, i));
      res+=temp*temp;
   }
   return sqrt(res);
}
//--------------------------------------------------------------------
int init()                          // Special function init()
{
   SetIndexBuffer(0,Coi);         // Assigning an array to a buffer
   SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2);// Line style
   SetIndexLabel (0,vstr);
   return 0;                          // Exit the special funct. init()
}
//--------------------------------------------------------------------
int start()                         // Special function start()
{
   int i,  Counted_bars;                // Number of counted bars
//--------------------------------------------------------------------
   Counted_bars=IndicatorCounted(); // Number of counted bars
   i=Bars-Counted_bars-1;           // Index of the first uncounted
   
   while(i>=0)                      // Loop for uncounted bars
   {
      // Corr for the current Symbol and vstr
      Coi[i] = cointegration(_Symbol, vstr, i, windows);
      i--;                          // Calculating index of the next bar
   }
//--------------------------------------------------------------------
   return 0;                          // Exit the special funct. start()
}
//--------------------------------------------------------------------