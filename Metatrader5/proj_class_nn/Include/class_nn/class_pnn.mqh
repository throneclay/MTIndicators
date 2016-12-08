//+------------------------------------------------------------------+
//|                                                    class_PNN.mqh |
//+------------------------------------------------------------------+
#property copyright "Yurich"
//+------------------------------------------------------------------+
#define PREVENTZERO(x)     if(x<1e-300) x=1e-300
#define RESIZE(a,s)        if(ArrayResize(a,(s))!=(s)) return(-4)
//+------------------------------------------------------------------+
class CNetPNN
{
   // topology parameters
   int               sizeinput;           // input dimension
   int               sizeoutput;          // output dimension
   bool              ready;               // is ready
   // hidden layer
   double            sigma[];             // sigma's
   double            samples[];           // samples
   double            classes[];           // classes
   int               patterns;            // number of patterns(hidden neurons)
   int               counter[];           // number of samples in each class
   // output data
   double            output[];
   // temp arrays for learning
   double            grad[];              // gradient
   double            temp1[];             // temp array for gradient computation
   double            temp2[];             // temp array for gradient computation
   int               currpatt;            //
public:
   double            mse;                 // network error
   int               epoch;               //
                     CNetPNN(int nin,int nout);
                    ~CNetPNN();
   int               Calculate(const double &m_inp[]);
   int               Learn(int npat,const double &m_inp[],const double &res[],int nep,double err);
   bool              Save(int handle);
   bool              Load(int handle);
protected:
   double            CalculateError(bool wg);
   double            CalculateError(double sig);
   int               CalculateDerivatives(const double &m_inp[]);
   void              svdcmp(double &a[],double &b[],double &x[]);
};
//+------------------------------------------------------------------+
CNetPNN::CNetPNN(int nin,int nout)
{
   sizeinput=nin;
   sizeoutput=nout;
   ready=false;
   mse=DBL_MAX;
   ArrayResize(output,nout);
   currpatt=-1;
}
//+------------------------------------------------------------------+
CNetPNN::~CNetPNN(void)
{
   ArrayFree(sigma);
   ArrayFree(samples);
   ArrayFree(classes);
   ArrayFree(counter);
   ArrayFree(output);
}
//+------------------------------------------------------------------+
int CNetPNN::Calculate(const double &m_inp[])
{
   if(!ready) return(-1);
   ArrayInitialize(output,0.0);
   for(int pat=0,p=0; pat<patterns; pat++,p+=sizeinput)
   {
      if(pat==currpatt) continue;
      double dist=0.0;
      for(int i=0; i<sizeinput; i++)
      {
         double d=sigma[i]==0.0?0.0:(m_inp[i]-samples[p+i])/sigma[i];
         dist+=d*d;
      }
      dist=exp(-dist);
      PREVENTZERO(dist);
      output[(int)classes[pat]]+=dist;
   }
   for(int i=0; i<sizeoutput; i++) output[i]/=counter[i];
   return(ArrayMaximum(output));
}
//+------------------------------------------------------------------+
double CNetPNN::CalculateError(double ns)
{
   ArrayInitialize(sigma,ns);
   return(CalculateError(false));
}
//+------------------------------------------------------------------+
double CNetPNN::CalculateError(bool wg)
{
   int r;
   double err=0.0;
   if(wg) ArrayInitialize(grad,0.0);
   double inputvector[];
   for(int pat=0; pat<patterns; pat++)
   {
      currpatt=pat;
      ArrayCopy(inputvector,samples,0,pat*sizeinput,sizeinput);
      if(wg)  r=CalculateDerivatives(inputvector);
      else r=Calculate(inputvector);
      double sse=0.0;
      for(int i=0; i<sizeoutput; i++)
         if(i!=r) sse+=output[i]*output[i];
      err+=sse/2;
   }
   currpatt=-1;
   if(wg) for(int i=0; i<sizeinput; i++) grad[i]/=patterns;
   return(err/patterns);
}
//+------------------------------------------------------------------+
int CNetPNN::CalculateDerivatives(const double &m_inp[])
{
   int i, j;
   double  d, dist, sum;
   double inputvector[];
   ArrayInitialize(output,0.0);
   ArrayInitialize(temp1,0.0);
   for(int pat=0; pat<patterns; pat++)
   {
      if(pat==currpatt) continue;
      ArrayCopy(inputvector,samples,0,pat*sizeinput,sizeinput);
      dist=0.0;
      for(i=0; i<sizeinput; i++)
      {
         d=sigma[i]==0.0?0.0:(m_inp[i]-inputvector[i])/sigma[i];
         temp2[i]=d*d;
         dist+=temp2[i];
         temp2[i]*=d;
      }
      dist=exp(-dist);
      d=dist;
      PREVENTZERO(dist);
      j=(int)classes[pat];
      output[j]+=dist;
      j*=sizeinput;

      for(i=0; i<sizeinput; i++) temp1[j+i]+=temp2[i];
   }
   sum=0.0;
   for(i=0; i<sizeoutput; i++)
   {
      output[i]/=counter[i];
      sum+=output[i];
   }
   PREVENTZERO(sum);
   double t1=0.0;
   for(i=0; i<sizeinput; i++)
   {
      double t2=2.0/sum*sigma[i];
      for(j=0; j<sizeoutput; j++)
      {
         temp1[j*sizeinput+i]/=counter[j];
         temp1[j*sizeinput+i]*=t2;
         t1+=temp1[j*sizeinput+i];
      }
      for(j=0; j<sizeoutput; j++)
      {
         d=j==(int)classes[currpatt]?2.0*(output[j]-1.0):2.0*output[j];
         grad[i]+=d*(temp1[j*sizeinput+i]-output[j]*t1);
      }
   }
   return(ArrayMaximum(output));
}
//+------------------------------------------------------------------+
int CNetPNN::Learn(int npat,const double &m_inp[],const double &res[],int nep,double err)
{
   int i, n, j, k, cnt=0;
   double pmse=DBL_MAX;
   double lsigma;             // lower of the best sigma.
   double lserr;              // the error for lsigma
   double msigma;             // best sigma
   double mserr;              // the error for msigma
   double hsigma;             // higher of the best sigma
   double hserr;              // the error for hsigma
   // learning default parameters
   double sigmaLow=0.001;     // the low value for the sigma search
   double sigmaHigh=10;       // the high value for the sigma search
   double rate=exp(log(sigmaHigh/sigmaLow)/100);
   double ilambda=2;          // initial lambda
   double minlambda=1e-2;     //
   double maxlambda=1e6;      //
   double inclambda=10;       //
   // get learning data
   RESIZE(counter,sizeoutput);
   ArrayInitialize(counter,0);
   for(int pat=0; pat<npat; pat++)
   {
      i=(int)res[pat];
      if(i>=sizeoutput || i<0)
      {
         //Print("Incorrect target class - ",i," from pattern=",pat);
         return(-1);
      }
      counter[i]++;
   }
   n=npat*sizeinput;
   if(ArrayCopy(samples,m_inp,0,0,n)!=n) return(-4);
   if(ArrayCopy(classes,res,0,0,npat)!=npat) return(-4);
   //allocate work memory
   double hessian[], cs[], cg[], ds[];
   ArrayResize(hessian,sizeinput*sizeinput);
   ArrayResize(cs,sizeinput);
   ArrayResize(ds,sizeinput);
   RESIZE(temp2,sizeinput);
   RESIZE(temp1,sizeinput*sizeoutput);
   RESIZE(grad,sizeinput);
   RESIZE(cg,sizeinput);
   RESIZE(sigma,sizeinput);
   patterns=npat;
   ready=true;
   // rough search of the global minimum with single sigma
   double xs=sigmaHigh;
   int ibest=-1;
   mserr=DBL_MAX;
   hserr=-1.0;
   double te=err*10;
   for(i=0; i<100; i++)
   {
      mse=CalculateError(xs);
      if(mse<mserr)
      {
         ibest=i;
         msigma=xs;
         hserr=mserr=mse;
         lserr=pmse;
      }
      else if(i==ibest+1) hserr=mse;
      pmse=mse;
      if(mse<=te) break;
      xs/=rate;
   }
   hsigma=msigma*rate;
   lsigma=msigma/rate;
   rate/=10;
   if(hserr<=mserr)
   {
      while(++i<100)
      {
         hserr=CalculateError(hsigma);
         if(hserr>mserr || (lserr==mserr && mserr==hserr)) break;
         lsigma=msigma;
         lserr=mserr;
         msigma=hsigma;
         mserr=hserr;
         hsigma*=rate;
      }
   }
   else if(ibest==0)
   {
      while(++i<100)
      {
         lserr=CalculateError(lsigma);
         if(lserr>mserr || (lserr==mserr && mserr==hserr)) break;
         hsigma=msigma;
         hserr=mserr;
         msigma=lsigma;
         mserr=lserr;
         lsigma/=rate;
      }
   }
   ArrayInitialize(sigma,msigma);
   ArrayInitialize(cs,msigma);
   // compute the error and gradient before start the main loop
   pmse=mse=CalculateError(true);
   double lambda=ilambda, sum, temp;
   int t=0, m, p;
   epoch=1;
   // the main loop
   while(epoch<nep && mse>err)
   {
      epoch++;
      if(lambda>=maxlambda/inclambda) lambda=ilambda;
      if(lambda<minlambda)  lambda=ilambda;
      if(mse<pmse)
      {
         pmse=mse;
         ArrayCopy(cs,sigma);
      }
      // compute perturbed approximate hessian
      for(i=0,n=0; i<sizeinput; i++,n+=sizeinput)
      {
         for(j=0,k=0; j<=i; j++,k+=sizeinput)  hessian[n+j]=grad[j]*grad[i]*2;

         cg[i]=grad[i];
      }
      bool ns=false;
      while(lambda<=maxlambda)
      {
         for(k=0,m=0; k<sizeinput; k++,m+=sizeinput)
         {
            sum=hessian[k+m]+lambda;

            for(j=0; j<k; j++)
            {
               temp=hessian[m+j];
               sum-=temp*temp;
            }
            if(sum<=0.0)
            {
               //cannot solve
               lambda*=inclambda;
               ns=true;
               continue;
            }
            hessian[m+k]=sqrt(sum);
            for(i=k+1,p=i*sizeinput; i<sizeinput; i++,p+=sizeinput)
            {
               sum=hessian[p+k];
               for(j=0; j<k; j++) sum-=hessian[p+j]*hessian[m+j];
               hessian[p+k]=sum/(lambda+hessian[m+k]);
            }
         }
         // normal
         for(i=0,m=0; i<sizeinput; i++,m+=sizeinput) ds[i]=grad[i]/(lambda+hessian[m+i]);
         // transpose
         for(i=sizeinput-1,m=i*sizeinput; i>=0; i--,m-=sizeinput)
         {
            sum=ds[i];
            for(j=i+1,k=j*sizeinput; j<sizeinput; j++,k+=sizeinput) sum-=hessian[k+i]*ds[j];
            ds[i]=sum/(lambda+hessian[m+i]);
         }
         ns=false;
         // update sigma
         for(j=0; j<sizeinput; j++) sigma[j]-=ds[j];
         // calculate next error
         mse=CalculateError(true);
         if(mse<pmse)
         {
            lambda/=inclambda;
            break;
         }
         lambda*=inclambda;
         // restore sigma and gradient
         for(j=0; j<sizeinput; j++) sigma[j]+=ds[j];
         ArrayCopy(grad,cg);
      }
      if(ns) break;
      if(mse>=pmse) t++; else t=0;
      if(t>3) break;
   }
   if(mse>pmse)
   {
      ArrayCopy(sigma,cs);
      mse=pmse;
   }
   //---
   ArrayFree(temp2);
   ArrayFree(temp1);
   ArrayFree(grad);
   ArrayFree(hessian);
   ArrayFree(cs);
   ArrayFree(cg);
   ArrayFree(ds);
   return(0);
}
//+------------------------------------------------------------------+
bool CNetPNN::Save(int handle)
{
   FileWriteInteger(handle,sizeinput);
   FileWriteInteger(handle,sizeoutput);
   FileWriteDouble(handle,mse);
   FileWriteInteger(handle,patterns);
   FileWriteInteger(handle,ArraySize(sigma));
   FileWriteArray(handle,sigma);
   FileWriteInteger(handle,ArraySize(samples));
   FileWriteArray(handle,samples);
   FileWriteInteger(handle,ArraySize(classes));
   FileWriteArray(handle,classes);
   FileWriteInteger(handle,ArraySize(counter));
   FileWriteArray(handle,counter);
   return(true);
}
//+------------------------------------------------------------------+
bool CNetPNN::Load(int handle)
{
   int n;
   ready=false;
   if(FileReadInteger(handle)!=sizeinput) return(false);
   if(FileReadInteger(handle)!=sizeoutput) return(false);
   mse=FileReadDouble(handle);
   patterns=FileReadInteger(handle);
   n=FileReadInteger(handle);
   if(FileReadArray(handle,sigma,0,n)!=n) return(false);
   n=FileReadInteger(handle);
   if(FileReadArray(handle,samples,0,n)!=n) return(false);
   n=FileReadInteger(handle);
   if(FileReadArray(handle,classes,0,n)!=n) return(false);
   n=FileReadInteger(handle);
   if(FileReadArray(handle,counter,0,n)!=n) return(false);
   epoch=0;
   ready=true;
   return(true);
}
//+------------------------------------------------------------------+
