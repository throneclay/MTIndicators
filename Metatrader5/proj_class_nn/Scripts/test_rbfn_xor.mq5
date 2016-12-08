//+------------------------------------------------------------------+
//|                                                 Test problem XOR |
//+------------------------------------------------------------------+
#include <class_nn/class_NetRBF.mqh>
//+------------------------------------------------------------------+
// the data for network teaching for the "XOR" function
// there are two ways:
// for a range of input data from -1 to 1
double inppth[]={1,1,1,-1,-1,1,-1,-1}; // input teaching data array
double tchth[]={-1,1,1,-1};            // output teaching data array
// for a range of input data from 0 to 1
double inpps[]={1,1,1,0,0,1,0,0};      // input teaching data array
double tchs[]={0,1,1,0};               // output teaching data array
//+------------------------------------------------------------------+
void OnStart()
  {
   CNetRBF *net;
   double ivect[2];     // input vector
   double out[1];       // the network responses array
   int epoch=1000;
   //---
   Print("Example for the input data range from -1 to 1");
   // network creation
   net=new CNetRBF(2,2,1);
   // network teaching
   net.Learn(4,inppth,tchth,epoch,1.0e-8);
   Print("MSE=",net.mse,"  Epoch=",net.epoch," Neurons=",net.neurons);
   // network checking
   for(int i=0,j=0; i<4; i++)
     {
      ivect[0]=inppth[j++]; ivect[1]=inppth[j++];
      net.Calculate(ivect,out);
      Print("Input=",(string)ivect[0],", ",(string)ivect[1]," Exit=",DoubleToString(out[0],0)," Test=",(string)tchth[i]);
     }
   // deleting network
   delete net;
   //---
   Print("Example for the input data range from 0 to 1");
   net=new CNetRBF(2,2,1);
   net.Learn(4,inpps,tchs,epoch,1.0e-8);
   Print("MSE=",net.mse,"  Epoch=",net.epoch," Neurons=",net.neurons);
   // saving network to a file and deleting network
   int h=FileOpen("primer.net",FILE_BIN|FILE_WRITE);
   net.Save(h);
   FileClose(h);
   delete net;
   // creating network again and downloading network from the file
   net=new CNetRBF(2,2,1);
   h=FileOpen("primer.net",FILE_BIN|FILE_READ);
   net.Load(h);
   FileClose(h);
   // network checking
   for(int i=0,j=0; i<4; i++)
     {
      ivect[0]=inpps[j++]; ivect[1]=inpps[j++];
      net.Calculate(ivect,out);
      Print("Input=",(string)ivect[0],", ",(string)ivect[1]," Exit=",DoubleToString(out[0],0)," Test=",(string)tchs[i]);
     }
   // deleting network
   delete net;
   FileDelete("primer.net");
  }
//+------------------------------------------------------------------+
