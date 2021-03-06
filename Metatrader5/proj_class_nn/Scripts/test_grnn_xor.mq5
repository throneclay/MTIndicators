#include <class_nn/class_GRNN.mqh>
//+------------------------------------------------------------------+
double ivect[2];  // input vector
double outr[1];   // the network responses array
// the data for network teaching for the "XOR" function
// there are two ways:
// for a range of input data from -1 to 1
double inppth[]= {1,1,1,-1,-1,1,-1,-1}; // input teaching data array
double tchth[]= {-1,1,1,-1};           // output teaching data array
// for the range from 0 to 1
double inpps[]= {1,1,1,0,0,1,0,0};     // input teaching data array
double tchs[]= {0,1,1,0};              // output teaching data array
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Example for the input data range from -1 to 1");
   // network creation
   CNetGRNN *net;
   net=new CNetGRNN(2,1);
   // network teaching
   net.Learn(4,inppth,tchth,100,1.0e-8);
   // net.Learn(4,inppth,tchth,epoch,1.0e-8);
   Print("MSE=",net.mse);
   // network checking
   string s="Check >> ";
   for(int i=0,j=0; i<4; i++)
   {
      ivect[0]=inppth[j++]; ivect[1]=inppth[j++];
      net.Calculate(ivect,outr);
      s+=" "+(string)ivect[0]+" xor "+(string)ivect[1]+" = "+DoubleToString(outr[0],0)+"("+(string)tchth[i]+") // ";
   }
   Print(s);
   // deleting network
   delete net;
   //---
   Print("Example for the input data range from 0 to 1");
   net=new CNetGRNN(2,1);
   net.Learn(4,inpps,tchs,100,1.0e-8);
   Print("MSE=",net.mse);
   // saving network to a file and deleting network
   int h=FileOpen("primer.net",FILE_BIN|FILE_WRITE);
   net.Save(h);
   FileClose(h);
   delete net;
   // creating network again and downloading network from the file
   net=new CNetGRNN(2,1);
   h=FileOpen("primer.net",FILE_BIN|FILE_READ);
   net.Load(h);
   FileClose(h);
   // network checking
   s="Check >> ";
   for(int i=0,j=0; i<4; i++)
   {
      ivect[0]=inpps[j++]; ivect[1]=inpps[j++];
      net.Calculate(ivect,outr);
      s+=" "+(string)ivect[0]+" xor "+(string)ivect[1]+" = "+DoubleToString(outr[0],0)+"("+(string)tchs[i]+") // ";
   }
   Print(s);
   // 蝈耱 1
   s="Test 1 >> ";
   double in2[]= {0.9,0.9,0.9,0.1,0.1,0.9,0.1,0.1}; // input test data array
   for(int i=0,j=0; i<4; i++)
   {
      ivect[0]=in2[j++]; ivect[1]=in2[j++];
      net.Calculate(ivect,outr);
      s+=" "+(string)ivect[0]+" xor "+(string)ivect[1]+" = "+DoubleToString(outr[0],0)+"("+(string)tchs[i]+") // ";
   }
   Print(s);
   // 蝈耱 2
   s="Test 1 >> ";
   double in3[]= {0.8,0.8,0.8,0.2,0.2,0.8,0.2,0.2}; // input test data array
   for(int i=0,j=0; i<4; i++)
   {
      ivect[0]=in3[j++]; ivect[1]=in3[j++];
      net.Calculate(ivect,outr);
      s+=" "+(string)ivect[0]+" xor "+(string)ivect[1]+" = "+DoubleToString(outr[0],0)+"("+(string)tchs[i]+") // ";
   }
   Print(s);
   // deleting network
   delete net;
   FileDelete("primer.net");
}
//+------------------------------------------------------------------+
