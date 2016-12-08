//+------------------------------------------------------------------+
//|                                  The multiplication and addition |
//+------------------------------------------------------------------+
#include <class_nn/class_NetRBF.mqh>
#define RAND(min,max) 	 ((rand()/(double)SHORT_MAX)*((max)-(min))+min)
//+------------------------------------------------------------------+
void OnStart()
  {
   double vector[2];         // Input vector
   double out[2];            // The network responses array
   double inpdata[];         // Input teaching data array
   double outdata[];         // Output teaching data array
                             // network creation
   CNetRBF *net;
   int epoch=10000;
   net=new CNetRBF(2,15,2);
   // preparation of data for the teaching
   ArrayResize(inpdata,200);
   ArrayResize(outdata,200);
   int m=0,k=0;
   for(int i=-10; i<10; i+=2)
      for(int j=-10; j<10; j+=2)
        {
         inpdata[m++]=i;
         inpdata[m++]=j;
         outdata[k++]=(i*j);
         outdata[k++]=(i+j);
        }
   // network teaching
   net.Learn(100,inpdata,outdata,epoch,1.0e-8);
   Print("MSE=",net.mse,"  Epoch=",net.epoch," Neurons=",net.neurons);
   // network checking
   string  s="Test 1(*) >> ";
   string s1="Test 1(+) >> ";
   for(int i=1; i<=10; i++)
     {
      int d1=(int)RAND(-10,10),d2=(int)RAND(-10,10);
      vector[0]=d1;
      vector[1]=d2;
      net.Calculate(vector,out);
      s+=(string)d1+"*"+(string)d2+"="+DoubleToString(out[0],0)+" // ";
      s1+=(string)d1+"+"+(string)d2+"="+DoubleToString(out[1],0)+" // ";
     }
   Print(s);
   Print(s1);
   s ="Test 2(*) >> ";
   s1="Test 2(+) >> ";
   for(int i=1; i<=10; i++)
     {
      int d1=(int)RAND(-20,20),d2=(int)RAND(-20,20);
      vector[0]=d1;
      vector[1]=d2;
      net.Calculate(vector,out);
      s+=(string)d1+"*"+(string)d2+"="+DoubleToString(out[0],0)+"("+string(d1*d2)+") // ";
      s1+=(string)d1+"+"+(string)d2+"="+DoubleToString(out[1],0)+" // ";
     }
   Print(s);
   Print(s1);
   // deleting network
   delete net;
  }
//+------------------------------------------------------------------+
