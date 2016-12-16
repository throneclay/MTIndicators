//--------------------------------------------------------------------
// userindicator.mq4 
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property indicator_separate_window    // Indicator is drawn in the main window
#property indicator_buffers 1      // Number of buffers
#property indicator_color1 Red     // Color of the 1st line

input int windows = 5;

double logHV[];             // History Volatility


//--------------------------------------------------------------------
int init()                          // Special function init()
{
   SetIndexBuffer(0,logHV);         // Assigning an array to a buffer
   SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2);// Line style
   SetIndexLabel (0,"log History Volatility");
   
   return 0;                          // Exit the special funct. init()
}

// Log Rate of Return  
double ilogR(const string & symbol, int timeframe, int shift)
{
   double close = iClose(symbol, timeframe, shift);
   double open = iOpen(symbol, timeframe, shift); 
   double logR = log(close)-log(open);
   
   return logR;

}

double logHistoryVolatility(const string& symbol, int start, int length)
{
   double sd = 0.0;
   
   // calculate means
   double mean = 0.0;
   int j = length;
   while(j>0)
   {
     mean += ilogR(symbol, 0, start+j);
     --j;
   }
   mean/=length;
   
   // calculate volatility(standard deviation)
   int i = length;
   while(i>0)
   {
      double temp = ilogR(symbol, 0, start+i)-mean;
      sd += temp*temp;
      --i;
   }
   sd/=(length-1);
   
   return sqrt(sd);
}



//--------------------------------------------------------------------
int start()                         // Special function start()
{
   int i,  Counted_bars;                // Number of counted bars
//--------------------------------------------------------------------
   Counted_bars=IndicatorCounted(); // Number of counted bars
   i=Bars-Counted_bars-windows-1;           // Index of the first uncounted
   
   while(i>=0)                      // Loop for uncounted bars
   {
      logHV[i] = logHistoryVolatility(_Symbol, i, windows);
      
      i--;                          // Calculating index of the next bar
   }
//--------------------------------------------------------------------
   return 0;                          // Exit the special funct. start()
}
//--------------------------------------------------------------------
