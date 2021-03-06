//--------------------------------------------------------------------
// userindicator.mq4 
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property indicator_separate_window    // Indicator is drawn in the main window
#property indicator_buffers 1      // Number of buffers
#property indicator_color1 Red     // Color of the 1st line
#define MAXRAND 32767

double GarchV[];
double a = 0.1;
double b = 0.8;
double w =0.0;


//--------------------------------------------------------------------
int init()                          // Special function init()
{
   SetIndexBuffer(0,GarchV);         // Assigning an array to a buffer
   SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2);// Line style
   SetIndexLabel (0,"Garch Volatility");
   
   MathSrand(GetTickCount());
   
   return 0;                          // Exit the special funct. init()
}

// Log Rate of Return  
double ilogR(const string & symbol, int timeframe, int shift)
{
   double close = iClose(symbol, timeframe, shift);
   double open = iOpen(symbol, timeframe, shift); 
   double logR = log(close)-log(open);
   //double logR = close-open;
   return logR;

}

//--------------------------------------------------------------------
int start()                         // Special function start()
{
   int i,  Counted_bars;                // Number of counted bars
   double Rsq; // square of the Rate of Return 
   //double GarchNumVar = 0.00001;
   double GarchNumVar = w/(1-a-b);

//--------------------------------------------------------------------
   Counted_bars=IndicatorCounted(); // Number of counted bars
   i=Bars-Counted_bars-1;           // Index of the first uncounted
   
   while(i>=0)                      // Loop for uncounted bars
   {
      
      Rsq = MathPow(ilogR(_Symbol, 0, i), 2.0);
      GarchNumVar =w + a*Rsq +b*GarchNumVar;
      
      //GarchV[i] = (double)MathRand()/MAXRAND;
      GarchV[i] = MathSqrt(GarchNumVar);
      
      i--;                          // Calculating index of the next bar
   }
//--------------------------------------------------------------------
   return 0;                          // Exit the special funct. start()
}
//--------------------------------------------------------------------