#property indicator_separate_window 
#property indicator_buffers 1 
#property indicator_plots   1 
//---- plot Line 
#property indicator_label1  "Line" 
#property indicator_type1   DRAW_LINE 
#property indicator_color1  Red 
#property indicator_style1  STYLE_SOLID 
#property indicator_width1  1 

#include <class_nn/class_grnn.mqh>
input int historialPeriod=20; // Period
//--- indicator buffers 
double         LineBuffer[];

CNetGRNN *net; 

double trainData[], labelData[];
int flag;
//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 

int OnInit() 
  { 
//--- indicator buffers mapping 
   SetIndexBuffer(0,LineBuffer,INDICATOR_DATA); 
   net = new CNetGRNN(20, 1);
   ArrayResize(trainData, historialPeriod*20);
   ArrayResize(labelData, historialPeriod);
   flag=0;
   //high, low, open, close -> next close 
//--- 
   return(INIT_SUCCEEDED); 
  } 
  
void OnDeinit(const int reason)
{
   printf("finished running\n");
   delete net;
} 

int PrepareData(const double& open[],const double& high[],
             const double& low[], const double& close[],
             const long& tick_volume[],int start)
{
   int inverseData = historialPeriod+start;
   for(int i=0;i<historialPeriod;i++)
     {
      inverseData--;
      trainData[20*i+0] = open[inverseData+4];
      trainData[20*i+1] = high[inverseData+4];
      trainData[20*i+2] = low[inverseData+4];
      trainData[20*i+3] = close[inverseData+4];
      trainData[20*i+4] = tick_volume[inverseData+4];
      trainData[20*i+5] = open[inverseData+3];
      trainData[20*i+6] = high[inverseData+3];
      trainData[20*i+7] = low[inverseData+3];
      trainData[20*i+8] = close[inverseData+3];
      trainData[20*i+9] = tick_volume[inverseData+3];
      trainData[20*i+10] = open[inverseData+2];
      trainData[20*i+11] = high[inverseData+2];
      trainData[20*i+12] = low[inverseData+2];
      trainData[20*i+13] = close[inverseData+2];
      trainData[20*i+14] = tick_volume[inverseData+2];
      trainData[20*i+15] = open[inverseData+1];
      trainData[20*i+16] = high[inverseData+1];
      trainData[20*i+17] = low[inverseData+1];
      trainData[20*i+18] = close[inverseData+1];
      trainData[20*i+19] = tick_volume[inverseData+1];
      labelData[i] = close[inverseData];
     }
   return 0;
}


//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total, 
                const int prev_calculated, 
                const datetime& time[], 
                const double& open[], 
                const double& high[], 
                const double& low[], 
                const double& close[], 
                const long& tick_volume[], 
                const long& volume[], 
                const int& spread[]) 
  { 
  
//--- Get the number of bars available for the current symbol and chart period 
   int bars=Bars(Symbol(),0); 
   if(flag==0)
     {
      flag=1;
   PrepareData(open, high, low, close, tick_volume ,10);
   net.Learn(historialPeriod,trainData,labelData,100,1.0e-8);
   Print("mse = ",net.mse);
   
     }
   double vector[20];
   double out[1];
   for(int i=0;i<bars-4;i++)
     {
     //printf("bars=%d, i=%d\n",bars, i);
     vector[0] = open[i+4];
      vector[1] = high[i+4];
      vector[2] = low[i+4];
      vector[3] = close[i+4];
      vector[4] = tick_volume[i+4];
      vector[5] = open[i+3];
      vector[6] = high[i+3];
      vector[7] = low[i+3];
      vector[8] = close[i+3];
      vector[9] = tick_volume[i+3];
      vector[10] = open[i+2];
      vector[11] = high[i+2];
      vector[12] = low[i+2];
      vector[13] = close[i+2];
      vector[14] = tick_volume[i+2];
      vector[15] = open[i+1];
      vector[16] = high[i+1];
      vector[17] = low[i+1];
      vector[18] = close[i+1];
      vector[19] = tick_volume[i+1];
      //net.Calculate(vector,out);
      LineBuffer[i]=high[i];
      //Print("out = ",out[0]);
     }
     Print("finished one plot!\n");
     return(rates_total); 
  } 