//+------------------------------------------------------------------+
//|                                                      SetTime.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property script_show_inputs
#define NV 1234
//--- input parameters
//input datetime dest=D'2015.12.23';
input datetime dest=D'2016.5.23';
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
double globalnvYear = 2000.0; //global variable
double globalnvMonth = 1.0;
double globalnvDay = 1.0;
double globalnvHour = 1.0;
double globalnvMin = 1.0;
#property indicator_chart_window

int OnInit()
{
//---
   double dyear,dmonth,dday,dhour,dmin;
   MqlDateTime nvdt;
   TimeToStruct(dest,nvdt);
   dyear = nvdt.year;
   dmonth = nvdt.mon;
   dday = nvdt.day;
   dhour = nvdt.hour;
   dmin = nvdt.min;
   
   //--- enable object create events
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_CREATE,true);
   //--- enable object delete events
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_DELETE,true);
   
   
   GlobalVariableSet("globalnvYear",dyear);
   GlobalVariableSet("globalnvMonth",dmonth);
   GlobalVariableSet("globalnvDay",dday);
   GlobalVariableSet("globalnvHour",dhour);
   GlobalVariableSet("globalnvMin",dmin);
     
   if(GlobalVariableCheck("globalnvYear")&&GlobalVariableCheck("globalnvMonth")&&GlobalVariableCheck("globalnvDay")&&GlobalVariableCheck("globalnvHour")&&GlobalVariableCheck("globalnvMin"))
   {
      printf("set success! new data is %.0f %.0f %.0f %.0f:%.0f",dyear,dmonth,dday,dhour,dmin);
      BroadcastEvent(ChartID(),0,"test");
   }

//---
   
   return(INIT_SUCCEEDED);
}
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
   
   return(rates_total);
  }
  
void BroadcastEvent(long lparam,double dparam,string sparam)
  {
   ushort eventID=CHARTEVENT_CUSTOM+NV;
   long currChart=ChartFirst();
   int i=0;
   //printf("I sent!!!!%ld\n",eventID);
   while(i<CHARTS_MAX)                 // We have certainly no more than CHARTS_MAX open charts
     {
      EventChartCustom(currChart,eventID,lparam,dparam,sparam);
      currChart=ChartNext(currChart); // We have received a new chart from the previous
      if(currChart==-1) break;        // Reached the end of the charts list
      i++;// Do not forget to increase the counter
     }
}