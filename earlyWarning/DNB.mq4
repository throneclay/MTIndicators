//--------------------------------------------------------------------
// userindicator.mq4 
// The code should be used for educational purpose only.
//--------------------------------------------------------------------
#property indicator_separate_window    // Indicator is drawn in the main window
#property indicator_buffers 1      // Number of buffers
#property indicator_color1 Red     // Color of the 1st line
//#property indicator_color2 Green      // Color of the 2nd line

input int windows = 10;

double DNB[];             // Declaring arrays (for indicator buffers)

//--------------------------------------------------------------------
int init()                          // Special function init()
{
   SetIndexBuffer(0,DNB);         // Assigning an array to a buffer
   SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,2);// Line style
   return 0;                          // Exit the special funct. init()
}

double getmeans(const double& data[], int start, int length)
{
   double mean = 0;
   int i = length;
   while(i>0)
   {
     mean += data[start+i];
     --i;
   }
   mean/=length;
   return mean;
}

double getstds(const double& data[], int start,int length)
{
   double mysd = 0;
   int i = length;
   double mean = getmeans(data, start, length);

   while(i>0)
   {
      mysd += (data[start+i]-mean)*(data[start+i]-mean);
      --i;
   }
   mysd = sqrt(mysd);
   return mysd;
}

double corr(const double& data1[], const double& data2[], int start, const int length)
{
   double meanXY = 0, meanX = 0, meanY=0;
   double stdX = 0, stdY = 0;
   double co = 0;
   double XY[100];
   int i = length;
   
   while(i>0)
   {
      XY[i] = data1[start+i]*data2[start+i];
      --i;
   }
   meanXY = getmeans(XY, 0 ,length);
   meanX = getmeans(data1, start, length);
   meanY = getmeans(data2, start, length);
   stdX = getstds(data1, start, length);
   stdY = getstds(data2, start, length);
   
   co = meanXY-meanX*meanY;
   co/=stdX;
   co/=stdY;
   
   return co;
}

double getstd(double d1, double d2, double d3, double d4)
{
   double mean = (d1+d2+d3+d4)/4;
   double mysd = (d1-mean)*(d1-mean)+(d2-mean)*(d2-mean)+(d3-mean)*(d3-mean)+(d4-mean)*(d4-mean);
   
   mysd = sqrt(mysd);
   return mysd;
}

//--------------------------------------------------------------------
int start()                         // Special function start()
{
   int i, j, Counted_bars;                // Number of counted bars
   double meanstd, meanPcc;
//--------------------------------------------------------------------
   Counted_bars=IndicatorCounted(); // Number of counted bars
   i=Bars-Counted_bars-1;           // Index of the first uncounted

   while(i>=windows)                      // Loop for uncounted bars
   {
      j = i-windows;
      //Pcc[i] = Open[j];
      meanstd = getstd(Open[j], Close[j], High[j], Low[j]);
      
      meanPcc = corr(Open, Close, j, windows);
      meanPcc +=corr(Open, High, j, windows);
      meanPcc +=corr(Open, Low, j, windows);
      meanPcc +=corr(Close, High, j, windows);
      meanPcc +=corr(Close, Low, j, windows);
      meanPcc +=corr(High, Low, j, windows);
      meanPcc /= 6;
      DNB[j] = meanstd*meanPcc;
      
      i--;                          // Calculating index of the next bar
   }
//--------------------------------------------------------------------
   return 0;                          // Exit the special funct. start()
}
//--------------------------------------------------------------------