#define RAND(min,max)      ((rand()/(double)SHORT_MAX)*((max)-(min))+min)
#include <class_nn/class_GRNN.mqh>
//+------------------------------------------------------------------+
void OnStart()
{
   double vector[2];       // input vector
   double out[2];          // the network responses array
   double inpdata[];       // input teaching data array
   double outdata[];       // output teaching data array
   // network creation
   CNetGRNN *net;
   net=new CNetGRNN(2,2);
   // preparation of data for the teaching
   // integer odd number from 1 to 9 is used as a test data
   ArrayResize(inpdata,100);
   ArrayResize(outdata,100);
   int m=0, k=0, n=0;
   for(int i=1; i<10; i+=2)
      for(int j=1; j<10; j+=2)
      {
         inpdata[m++]=i/10.0;
         inpdata[m++]=j/10.0;
         outdata[k++]=(i*j)/100.0;  // result of multiplying
         outdata[k++]=(i+j)/100.0;  // result of addition
         n++;
      }
   // network teaching
   net.Learn(n,inpdata,outdata,100,1.0e-8);
   Print("MSE=",net.mse);
   // test 1 - multiplication of even integer numbers
   string  s="Test 1(*) >> ";
   string s1="Test 1(+) >> ";
   for(int i=0; i<10; i++)
   {
      int d1=(int)RAND(1,10);
      int d2=(int)RAND(1,10);
      d1=d1<3?2:(d1/2)*2;
      d2=d2<3?2:(d2/2)*2;
      vector[0]=d1==0.0?0.2:d1/10.0;
      vector[1]=d2==0.0?0.2:d2/10.0;
      net.Calculate(vector,out);
      s+=(string)d1+"*"+(string)d2+"="+DoubleToString(out[0]*100,0)+" // ";
      s1+=(string)d1+"+"+(string)d2+"="+DoubleToString(out[1]*100,0)+" // ";
   }
   Print(s);
   Print(s1);
   // test 2 - multiply even at odd integers
   s ="Test 2(*) >> ";
   s1="Test 2(+) >> ";
   for(int i=0; i<10; i++)
   {
      int d1=(int)RAND(1,10);
      int d2=(int)RAND(0,8);
      d1=d1<3?2:(d1/2)*2;
      d2=(d2/2)*2+1;
      vector[0]=d1/10.0;
      vector[1]=d2/10.0;
      net.Calculate(vector,out);
      s+=(string)d1+"*"+(string)d2+"="+DoubleToString(out[0]*100,0)+" // ";
      s1+=(string)d1+"+"+(string)d2+"="+DoubleToString(out[1]*100,0)+" // ";
   }
   Print(s);
   Print(s1);
   // deleting network
   delete net;
}
