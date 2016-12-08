//--------------------------------------------------------------------
// userindicator.mq4 
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property indicator_separate_window    // Indicator is drawn in the main window
#property indicator_buffers 1      // Number of buffers
#property indicator_color1 Red     // Color of the 1st line
#property indicator_color2 Green     // Color of the 1st line
#define iFunc iClose

input int windows = 10;
input string vstr1= "USDJPY";
input string vstr2= "GBPJPY";

double Corr1[];             // Declaring arrays (for indicator buffers)
double Corr2[];             // Declaring arrays (for indicator buffers)

//--------------------------------------------------------------------
int init()                          // Special function init()
{
   SetIndexBuffer(0,Corr1);         // Assigning an array to a buffer
   SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2);// Line style
   SetIndexLabel (0,vstr1);
   
   SetIndexBuffer(1,Corr2);         // Assigning an array to a buffer
   SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,2);// Line style
   SetIndexLabel (1,vstr2);
   return 0;                          // Exit the special funct. init()
}

// Calculate the mean of symbol for a length time
double getmeans(const string& symbol, int start, int length)
{
   double mean = 0;
   int i = length;
   while(i>0)
   {
     mean += iFunc(symbol, 0, start+i);
     --i;
   }
   mean/=length;
   return mean;
}

// Calculate the std of symbol for a length time
double getstds(const string& symbol, int start, int length)
{
   double mysd = 0;
   int i = length;
   double mean = getmeans(symbol, start, length);

   while(i>0)
   {
      mysd += (iFunc(symbol, 0, start+i)-mean)*(iFunc(symbol, 0, start+i)-mean);
      --i;
   }
   mysd = sqrt(mysd);
   return mysd;
}

// compute the correlation between symbol1 and symbol2 for a length time
double corr(const string& symbol1, const string& symbol2, int start, const int length)
{
   double meanXY = 0, meanX = 0, meanY=0;
   double stdX = 0, stdY = 0;
   double co = 0;
   double XY[100];
   int i = length;
   
   while(i>0)
   {
      XY[length-i] = iFunc(symbol1, 0,start+i)*iFunc(symbol2,0,start+i);
      --i;
   }
   for(int j=0;j<length;j++)
   {
      meanXY+=XY[j];
   }
   meanXY/=length;
   
   meanX = getmeans(symbol1, start, length);
   meanY = getmeans(symbol2, start, length);
   stdX = getstds(symbol1, start, length);
   stdY = getstds(symbol2, start, length);
   
   double stdMul=stdX*stdY+0.000001;
   co = (meanXY-meanX*meanY)/stdMul;
   //printf("co = %f meanXY = %f mean %s = %f mean %s = %f",co,meanXY, symbol1, meanX, symbol2, meanY);
   
   // corr=(mean(X*Y)-mean(X)*mean(Y))/(stdX*stdY)
   return co;

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
      Corr1[i] = corr(_Symbol, vstr1, i, windows);
      Corr2[i] = corr(_Symbol, vstr2, i, windows);

      i--;                          // Calculating index of the next bar
   }
//--------------------------------------------------------------------
   return 0;                          // Exit the special funct. start()
}
//--------------------------------------------------------------------