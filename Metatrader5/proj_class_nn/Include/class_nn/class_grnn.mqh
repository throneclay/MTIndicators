#property copyright "Zhang Shuai"

//+------------------------------------------------------------------+
#define PREVENTZERO(x)     if(x<1e-300) x=1e-300
#define RESIZE(a,s)        if(ArrayResize(a,s)!=s) return(-4)
//+------------------------------------------------------------------+
class CNetGRNN
{
   // topology parameters
   int               sizeinput;           // input dimension
   int               sizeoutput;          // output dimension
   bool              ready;               // is ready
   // hidden layer
   double            sigma[];             // sigma's
   double            samples[];           // samples
   double            targets[];           // targets
   int               patterns;            // the number of patterns(hidden neurons)
   // output data
   double            output[];
   // temp arrays for learning
   double            grad[];              // gradient
   double            temp1[];             // temp array for gradient computation
   double            temp2[];             // temp array for gradient computation
public:
   double            mse;                 // network error
   int               epoch;               //
                     CNetGRNN(int nin,int nout);
                    ~CNetGRNN();
   void              Calculate(const double &m_inp[],double &m_out[]);
   int               Learn(int npat,const double &m_inp[],const double &res[],int nep,double err);
   bool              Save(int handle);
   bool              Load(int handle);
protected:
   double            CalculateError(bool wg);
   double            CalculateError(double sig);
   void              CalculateDerivatives(const double &m_inp[],int ptr);
};
//+------------------------------------------------------------------+
CNetGRNN::CNetGRNN(int nin,int nout)
{
   sizeinput=nin;
   sizeoutput=nout;
   ready=false;
   mse=DBL_MAX;
   ArrayResize(output,nout);
}
//+------------------------------------------------------------------+
CNetGRNN::~CNetGRNN(void)
{
   ArrayFree(sigma);
   ArrayFree(samples);
   ArrayFree(targets);
   ArrayFree(output);
}
//+------------------------------------------------------------------+
void CNetGRNN::Calculate(const double &m_inp[],double &m_out[])
{
   ArrayInitialize(m_out,0.0);
   if(!ready) return;
   double sum=0.0;
   for(int pat=0,p=0; pat<patterns; pat++,p+=sizeinput)
   {
      double dist=0.0;
      for(int i=0; i<sizeinput; i++)
      {
         double d=sigma[i]==0.0?0.0:(m_inp[i]-samples[p+i])/sigma[i];
         dist+=d*d;
      }
      dist=exp(-dist);
      PREVENTZERO(dist);
      sum+=dist;
      for(int i=0; i<sizeoutput; i++)
         m_out[i]+=dist*targets[pat*sizeoutput+i];
   }
   for(int i=0; i<sizeoutput; i++) m_out[i]/=sum;
}
//+------------------------------------------------------------------+
double CNetGRNN::CalculateError(double ns)
{
   ArrayInitialize(sigma,ns);
   return(CalculateError(false));
}
//+------------------------------------------------------------------+
double CNetGRNN::CalculateError(bool wg)
{
   double err=0.0;
   if(wg) ArrayInitialize(grad,0.0);
   double inputvector[];
   for(int pat=0; pat<patterns; pat++)
   {
      ArrayCopy(inputvector,samples,0,pat*sizeinput,sizeinput);
      if(wg)   CalculateDerivatives(inputvector,pat*sizeoutput);
         else  Calculate(inputvector,output);
      double sse=0.0;
      for(int i=0, j=pat*sizeoutput; i<sizeoutput; i++,j++)
      {
         double d=output[i]-targets[j];
         sse+=d*d;
      }
      err+=sse/2;
   }
   if(wg) for(int i=0; i<sizeinput; i++) grad[i]/=patterns;
   return(err/patterns);
}
//+------------------------------------------------------------------+
CNetGRNN::CalculateDerivatives(const double &m_inp[],int ptr)
{
   int i, j, k, m;
   double  d, dist, sum;
   double inputvector[];
   ArrayInitialize(output,0.0);
   ArrayInitialize(temp1,0.0);
   sum=0.0;
   for(int pat=0; pat<patterns; pat++)
   {
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
      for(i=0; i<sizeoutput; i++) output[i]+=dist*targets[pat*sizeoutput+i];
      for(j=0, k=0, m=pat*sizeoutput; j<sizeoutput; j++,m++)
         for(i=0; i<sizeinput; i++) temp1[k++]+=temp2[i]*targets[m];
      for(i=0; i<sizeinput; i++) temp1[i]+=temp2[i];
      sum+=dist;
   }
   for(i=0; i<sizeoutput; i++) output[i]/=sum;
   for(i=0; i<sizeinput; i++)
   {
      double t1=2.0/sum*sigma[i];
      double t2=temp1[i]*t1;
      for(j=0,k=0; j<sizeoutput; j++,k+=sizeinput)
         grad[i]+=2.0*(output[j]-targets[ptr+j])*(temp1[k+i]*t1-output[j]*t2);
   }
}
//+------------------------------------------------------------------+
int CNetGRNN::Learn(int npat,const double &m_inp[],const double &res[],int nep,double err)
{
   int i, n, j, k, m, p;
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
   double minlambda=0.01;     //
   double maxlambda=1e6;      //
   double declambda=0.1;      //
   double inclambda=10;       //
   // get learning data
   n=npat*sizeinput;
   if(ArrayCopy(samples,m_inp,0,0,n)!=n) return(-4);
   n=sizeoutput*npat;
   if(ArrayCopy(targets,res,0,0,n)!=n) return(-4);
   //allocate work memory
   double hessian[], cs[], cg[], ds[];
   ArrayResize(hessian,sizeinput*sizeinput);
   ArrayResize(cg,sizeinput);
   ArrayResize(cs,sizeinput);
   ArrayResize(ds,sizeinput);
   RESIZE(temp2,sizeinput);
   RESIZE(temp1,sizeinput*sizeoutput);
   RESIZE(grad,sizeinput);
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
   int t=0;
   te=0;
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
         for(j=0; j<=i; j++)  hessian[n+j]=grad[j]*grad[i]*2;

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
         // restore sigma & gradient
         for(j=0; j<sizeinput; j++) sigma[j]+=ds[j];
         ArrayCopy(grad,cg);
      }
      if(ns) break;
      if(mse>=pmse) t++; else t=0;
      if(t>3) break;
      te=mse;
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
bool CNetGRNN::Save(int handle)
{
   FileWriteInteger(handle,sizeinput);
   FileWriteInteger(handle,sizeoutput);
   FileWriteDouble(handle,mse);
   FileWriteInteger(handle,patterns);
   FileWriteInteger(handle,ArraySize(sigma));
   FileWriteArray(handle,sigma);
   FileWriteInteger(handle,ArraySize(samples));
   FileWriteArray(handle,samples);
   FileWriteInteger(handle,ArraySize(targets));
   FileWriteArray(handle,targets);
   return(true);
}
//+------------------------------------------------------------------+
bool CNetGRNN::Load(int handle)
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
   if(FileReadArray(handle,targets,0,n)!=n) return(false);
   epoch=0;
   ready=true;
   return(true);
}
//+------------------------------------------------------------------+
