//+------------------------------------------------------------------+
//|                                              clientNavigator.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#define NV 1234

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
  {
     if(id == CHARTEVENT_CUSTOM+NV + 1000)
       {
        string tempTime;
        int nvyear=0,nvmonth=0,nvday=0,nvhour=0,nvmin=0;
        double getVar;
        int theBars=0;
        long handle=ChartID();
        if(GlobalVariableCheck("globalnvYear")){
         getVar = GlobalVariableGet("globalnvYear"); nvyear = (int)getVar;
        }     
        if(GlobalVariableCheck("globalnvMonth")){
         getVar = GlobalVariableGet("globalnvMonth"); nvmonth = (int)getVar;
        }
        if(GlobalVariableCheck("globalnvDay")){
         getVar = GlobalVariableGet("globalnvDay"); nvday = (int)getVar;
        }     
        if(GlobalVariableCheck("globalnvHour")){
         getVar = GlobalVariableGet("globalnvHour"); nvhour = (int)getVar;
        }     
        if(GlobalVariableCheck("globalnvMin")){
         getVar = GlobalVariableGet("globalnvMin"); nvmin = (int)getVar;
        }
        
        tempTime = StringFormat("%d.%d.%d %d:%d",nvyear,nvmonth,nvday,nvhour,nvmin);
        
        datetime clientDest,clientCur;
        MqlDateTime tDest,tCur;
        clientDest = StrToTime(tempTime); clientCur = TimeCurrent();
        TimeToStruct(clientDest,tDest);  TimeToStruct(clientCur,tCur);
        
        //delete vline
        ObjectDelete(0,"Time_Vertical_Line");
        
        //draw vline
        ObjectCreate("Time_Vertical_Line", OBJ_VLINE, 0, clientDest, 0);
        ObjectSet("Time_Vertical_Line", OBJPROP_WIDTH, 2);
        ObjectSet("Time_Vertical_Line", OBJPROP_COLOR, Yellow);
        ObjectSet("Time_Vertical_Line", OBJPROP_BACK, true);
        
        //printf("Target date: %02d.%02d.%4d, %d:%d day of year = %d",tDest.day,tDest.mon,tDest.year,tDest.hour,tDest.min,tDest.day_of_year);
        //printf("Curent date: %02d.%02d.%4d, %d:%d day of year = %d",tCur.day,tCur.mon,tCur.year,tCur.hour,tCur.min,tCur.day_of_year);
             
        // judge bars and shift to it!
        theBars = WindowBarsPerChart()/2 - Bars(Symbol(),Period(),clientCur,clientDest);
        //printf("The bars = %d",theBars);
        
        if(handle > 0){
         ChartNavigate(handle,CHART_END,theBars);
         //printf("Successfully jump to the date")
        }
     }
  }

void OnInit()
  {
   //--- enable object create events
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_CREATE,true);
   //--- enable object delete events
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_DELETE,true);
   printf("Start Event Nvgation listening");
   Comment("Listening");
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