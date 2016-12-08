//+------------------------------------------------------------------+
//|                                                 class_NetRBF.mqh |
//+------------------------------------------------------------------+
#property copyright "Yurich"
//+------------------------------------------------------------------+
#define GETSIGN(x) 		 (x)<0.0?-1:1
#define SETSIGN(x,b)		 (b)>=0.0?fabs(x):-fabs(x)
#define _RESIZE(a,s) 	 if(ArrayResize(a,s)!=s) return(-4)
//+------------------------------------------------------------------+
//| Class CNetRBF                                                    |
//+------------------------------------------------------------------+
class CNetRBF
  {
   // topology parameters
   int               sizeinput;     // input dimension
   int               sizeoutput;    // output dimension
   int               sizehidden;    // hidden neurons
   int               maxhidden;     // maximal number of hidden neurons at all
   int               totalinput;    //
   int               sizeweight;    //
   // input vector
   double            inputvector[];
   // hidden layer
   double            center[];      // with sigma
   double            hout[];        // output hidden layer
   // output layer
   double            weight[];      // with bias
   int               actfunc;       // 0 - none, 1 - sigmoid or 2 - th
   // temp arrays for learning
   double            dEc[],dEw[];
   int               mepatt;        // pattern with largest error
public:
   double            mse;           // network error
   int               epoch;         // 
   int               neurons;       // number neurons in hidden layers
   //---
                     CNetRBF(int nin,int nhid,int nout);
                    ~CNetRBF(void);
   void              Calculate(const double &in[],double &out[]);
   int               Learn(int npat,const double &inp[],const double &res[],int nep,double err);
   bool              Save(int handle);
   bool              Load(int handle);
protected:
   void              Calculate(double &out[]);
   void              CalculateHiddenLayer();
   double            CalculateError(int npat,const double &inp[],const double &res[]);
   int               APC(int npat,const double &inp[]);
   void              SVD(int npat,const double &inp[],const double &res[]);
  };
//+------------------------------------------------------------------+
CNetRBF::CNetRBF(int nin,int nhid,int nout)
  {
   sizeinput=nin;
   totalinput=sizeinput+1;//+sigma;
   sizeoutput=nout;
   sizehidden=0;
   maxhidden=nhid;
   sizeweight=maxhidden+1;//+bias
   actfunc=-1;
   ArrayResize(inputvector,sizeinput);
   ArrayResize(center,maxhidden*totalinput);//with sigma
   ArrayResize(weight,sizeweight*sizeoutput);//with bias
   ArrayResize(hout,maxhidden);
  }
//+------------------------------------------------------------------+
CNetRBF::~CNetRBF(void)
  {
   ArrayFree(inputvector);
   ArrayFree(center);
   ArrayFree(hout);
   ArrayFree(weight);
  }
//+------------------------------------------------------------------+
void CNetRBF::Calculate(const double &in[],double &out[])
  {
   if(actfunc<0)
     {
      ArrayInitialize(out,0.0);
      return;
     }
   ArrayCopy(inputvector,in,0,0,sizeinput);
   Calculate(out);
  }
//+------------------------------------------------------------------+
void CNetRBF::Calculate(double &out[])
  {
   CalculateHiddenLayer();
   for(int i=0,ii=0; i<sizeoutput; i++,ii+=sizeweight)
     {
      double d=-weight[ii+sizeweight-1];//bias
      for(int j=0; j<sizehidden; j++) d+=weight[ii+j]*hout[j];
      if(actfunc==2)
        {//th
         if(d>20.0) d=1.0;
         else if(d<-20.0) d=-1.0;
         else
           {
            d=exp(d+d);
            d=(d-1.0)/(d+1.0);
           }
        }
      else if(actfunc==1) d=d>40.0?1.0:d<-40.0?0.0:1.0/(1.0+exp(-d));//sigmoid
      out[i]=d;
     }
  }
//+------------------------------------------------------------------+
void CNetRBF::CalculateHiddenLayer(void)
  {
   for(int i=0,ii=0; i<sizehidden; i++,ii+=totalinput)
     {
      int j=0;
      double d,sum=0.0;
      while(j<sizeinput)
        {
         d=inputvector[j]-center[ii+j++];
         sum+=d*d;
        }
      d=center[ii+j];//sigma
      hout[i]=exp(-sum/(2.0*d*d));
     }
  }
//+------------------------------------------------------------------+
double CNetRBF::CalculateError(int npat,const double &inp[],const double &res[])
  {
   int i,ii,j,jj;
   double d,r,sse,maxerror=0.0,kt=1.0;
   double target[],out[];
   ArrayResize(out,sizeoutput);
   ArrayResize(target,sizeoutput);
   ArrayInitialize(dEc,0.0);
   ArrayInitialize(dEw,0.0);
   mse=0.0;
   for(int pat=0; pat<npat; pat++)
     {
      // get pattern
      ArrayCopy(inputvector,inp,0,pat*sizeinput,sizeinput);
      ArrayCopy(target,res,0,pat*sizeoutput,sizeoutput);
      // compute output of current pattern
      Calculate(out);
      // compute error and dE's
      sse=0.0;
      for(i=0,ii=0; i<sizeoutput; i++,ii+=sizeweight)
        {
         target[i]=out[i]-target[i];
         d=target[i];
         sse+=d*d;
         if(actfunc>0) d*=actfunc==2?1-out[i]*out[i]:out[i]*(1.0-out[i]);//th or sigmoid
         d*=kt;
         for(j=0,jj=ii; j<sizehidden; j++,jj++) dEw[jj]+=d*hout[j];
         dEw[ii+sizeweight-1]+=d;//dEdbias
        }
      for(i=0,ii=0; i<sizehidden; i++,ii+=totalinput)
        {
         double x,sum1=0.0,sum2,sum3=0.0;
         for(j=0,jj=0; j<sizeoutput; j++,jj+=sizeweight) sum1+=target[j]*weight[jj+i];
         r=center[ii+sizeinput];//sigma
         x=r*r;
         sum2=kt*hout[i]*sum1/x;
         for(j=0,jj=ii; j<sizeinput; j++,jj++)
           {
            d=inputvector[j]-center[jj];
            dEc[jj]+=sum2*d;
            sum3+=d*d;
           }
         dEc[jj]+=kt*hout[i]*sum1*sum3/(x*r);//dEdsigma
        }
      if(sse>maxerror)
        {
         mepatt=pat;
         maxerror=sse;
        }
      mse+=sse/2;
     }
   return(mse/npat);
  }
//+------------------------------------------------------------------+
int CNetRBF::Learn(int npat,const double &inp[],const double &res[],int nep,double err)
  {
   int i,ii,j,jj,k,hc;
   int ce=0,cer=0,bestepoch=0,iw=0,addepoch=0,cnt=0;
   int tsw=sizeweight*sizeoutput;
   int tsc=totalinput*maxhidden;
   double r,d,toler;
   double dw[],dc[],copycenter[],copyweight[];
   int dwsign[],dcsign[];
   // errors
   double pmse=0.0,maxerror,minerror=DBL_MAX;
   // learning default parameters
   double minsigma=0.001;
   double mindistance=1e-3;
   double minadd=1e-6;
   double d0=0.0125;
   double dmin=0.0;
   double dmax=50.0;
   double plus=1.2;
   double minus=0.5;
   double minimprov=1e-7;
   // allocate work memory 
   _RESIZE(dwsign,tsw);
   _RESIZE(dw,tsw);
   _RESIZE(dcsign,tsc);
   _RESIZE(dc,tsc);
   _RESIZE(dEw,tsw);
   _RESIZE(dEc,tsc);
   _RESIZE(copyweight,tsw);
   _RESIZE(copycenter,tsc);
   // reset arrays
   ArrayInitialize(dcsign,1);
   ArrayInitialize(dc,d0);
   ArrayInitialize(dwsign,1);
   ArrayInitialize(dw,d0);
   // use APC algorithm to set the hidden neurons
   if(APC(npat,inp)>maxhidden) return(-3);// need more hidden neurons
   neurons=sizehidden;
   hc=sizehidden;
   double ds=center[totalinput-1];// default sigma
   // choice activation function for output layer
   double min=res[ArrayMinimum(res)];
   double max=res[ArrayMaximum(res)];
   if(max>1.0 || min<-1.0) actfunc=0;     // none
   else if(min<0.0) actfunc=2;            // use th
   else actfunc=1;                        // use sigmoid
   // use SVD(Singular Value Decomposition) algorithm to set weights of output layers 
   SVD(npat,inp,res);
   // use RPROP algorithm for fine tuning hidden and output layers
   for(epoch=1; epoch<=nep; epoch++)
     {
      maxerror=0.0;
      mse=CalculateError(npat,inp,res);
      if(mse<minerror)
        {
         minerror=mse;
         if(minerror<err) break;
         bestepoch=epoch;
         ce=0;
         // save best hidden & output layers
         ArrayCopy(copycenter,center);
         ArrayCopy(copyweight,weight);
         hc=sizehidden;
        }
      toler=pmse<=1.0?minimprov:minimprov*pmse;
      if(fabs(pmse-mse)>toler) cnt=0;
      else if(++cnt>5) break; // break if there is little improvement
      // update output layer
      for(i=0; i<tsw; i++)
        {
         d=dEw[i]*dwsign[i];
         if(d>0.0)
           {
            dw[i]=MathMin(dw[i]*plus,dmax);
            dwsign[i]=GETSIGN(dEw[i]);
            weight[i]-=dwsign[i]*dw[i];
           }
         else if(d<0.0)
           {
            if(mse>pmse) weight[i]+=dwsign[i]*dw[i];
            dw[i]=MathMax(dw[i]*minus,dmin);
            dwsign[i]=0;
           }
         else
           {
            dwsign[i]=GETSIGN(dEw[i]);
            weight[i]-=dwsign[i]*dw[i];
           }
        }
      // update hidden layer  			
      for(i=0,ii=0; i<sizehidden; i++,ii+=totalinput)
        {
         for(j=0,jj=ii; j<totalinput; j++,jj++)
           {
            d=dEc[jj]*dcsign[jj];
            if(d>0.0)
              {
               dc[jj]=MathMin(dc[jj]*plus,dmax);
               dcsign[jj]=GETSIGN(dEc[jj]);
               center[jj]-=dcsign[jj]*dc[jj];
              }
            else if(d<0.0)
              {
               if(mse>pmse) center[jj]+=dcsign[jj]*dc[jj];
               dc[jj]=MathMax(dc[jj]*minus,dmin);
               dcsign[jj]=0;
              }
            else
              {
               dcsign[jj]=GETSIGN(dEc[jj]);
               center[jj]-=dcsign[jj]*dc[jj];
              }
           }
         // if sigma is less than zero
         if(center[jj-1]<=0) center[jj-1]=ds;// reset sigma
                                             // if sigma is too small
         if(center[jj-1]<minsigma)
           {// delete neuron
            ArrayCopy(center,center,ii,(sizehidden-1)*totalinput,totalinput);
            ArrayCopy(dc,dc,ii,(sizehidden-1)*totalinput,totalinput);
            ArrayCopy(dEc,dEc,ii,(sizehidden-1)*totalinput,totalinput);
            for(j=0,jj=0; j<sizeoutput; j++,jj+=sizeweight)
              {
               weight[jj+i]=weight[jj+sizehidden-1];
               dw[jj+i]=dw[jj+sizehidden-1];
               dEw[jj+i]=dEw[jj+sizehidden-1];
              }
            sizehidden--;
            i--;
           }
        }
      // if two hidden neurons are too close
      if(mindistance>0.0)
        {
         for(i=0,ii=0; i<sizehidden; i++,ii+=totalinput)
            for(j=i+1,jj=j*totalinput; j<sizehidden; j++,jj+=totalinput)
              {
               d=0.0;
               for(k=0; k<sizeinput; k++)
                 {
                  r=center[ii+k]-center[jj+k];
                  d+=r*r;
                 }
               if(sqrt(d)<mindistance)
                 {// delete neuron
                  ArrayCopy(center,center,ii,(sizehidden-1)*totalinput,totalinput);
                  ArrayCopy(dc,dc,ii,(sizehidden-1)*totalinput,totalinput);
                  ArrayCopy(dEc,dEc,ii,(sizehidden-1)*totalinput,totalinput);
                  for(j=0,jj=0; j<sizeoutput; j++,jj+=sizeweight)
                    {
                     weight[jj+i]=weight[jj+sizehidden-1];
                     dw[jj+i]=dw[jj+sizehidden-1];
                     dEw[jj+i]=dEw[jj+sizehidden-1];
                    }
                  sizehidden--;
                  i--;
                  break;
                 }
              }
        }
      // ... add new hidden neuron at pattern with largest error
      if((++ce>20 || cnt>3) && sizehidden<maxhidden && minerror>minadd && epoch-addepoch>50)
        {
         addepoch=epoch;
         ii=sizehidden*totalinput;
         ArrayCopy(center,inp,ii,mepatt*sizeinput,sizeinput);
         center[ii+sizeinput]=ds;
         for(i=0; i<sizeoutput; i++) weight[i*sizeweight+sizehidden]=res[mepatt*sizeoutput+i];
         sizehidden++;
         ce=0;
         cnt=0;
        }
      pmse=mse;
     }
   if(mse>minerror)
     {// restore best hidden & output layers
      mse=minerror;
      ArrayCopy(center,copycenter);
      ArrayCopy(weight,copyweight);
      sizehidden=hc;
     }
   neurons=sizehidden;
//
   ArrayFree(dw);
   ArrayFree(dEw);
   ArrayFree(dc);
   ArrayFree(dEc);
   ArrayFree(copyweight);
   ArrayFree(copycenter);
   return(0);
  }
//+------------------------------------------------------------------+
int CNetRBF::APC(int npat,const double &inp[])
  {
   int n,i,j,ii,jj, k=0;
   double d, s, r, R0=DBL_MAX;
   int nn[];
   double tc[];
   ArrayResize(nn,maxhidden);
   ArrayResize(tc,maxhidden*sizeinput);
   // calculate R0
   s=0.0;
   for(i=0; i<npat-1; i++)
      for(j=i+1; j<npat; j++)
        {
         d=0.0;
         for(n=0; n<sizeinput; n++)
           {
            r=inp[i*sizeinput+n]-inp[j*sizeinput+n];
            d+=r*r;
           }
         if(d<R0)
           {
            R0=d;
            s+=d;
            k++;
           }
        }
   R0=s/(double)k;
   // calculate center of hidden layer
   n=1;
   nn[0]=1;
   ArrayCopy(tc,inp,0,0,sizeinput);
   for(i=1,ii=sizeinput; i<npat; i++,ii+=sizeinput)
     {
      for(j=0,jj=0; j<n; j++,jj+=sizeinput)
        {
         d=0.0;
         for(k=0; k<sizeinput; k++)
           {
            r=inp[ii+k]-tc[jj+k];
            d+=r*r;
           }
         if(d<=R0)
           {
            for(k=0; k<sizeinput; k++)
               tc[jj+k]=(tc[jj+k]*nn[j]+inp[ii+k])/(nn[j]+1);
            nn[j]++;
            break;
           }
        }
      if(j==n)
        {
         n++;
         k=ArraySize(nn);
         if(n==k)
           {
            k+=10;
            ArrayResize(nn,k);
            ArrayResize(tc,k*sizeinput);
           }
         nn[n-1]=1;
         ArrayCopy(tc,inp,(n-1)*sizeinput,ii,sizeinput);
        }
     }
   if(n>maxhidden)
     {
      if(n==npat) return(n);
      else     return(APC(n,tc));
     }
   sizehidden=n;
   double max=0.0, min=DBL_MAX;
   for(i=0; i<n-1; i++)
      for(j=i+1; j<n; j++)
        {
         s=0.0;
         for(k=0; k<sizeinput; k++)
           {
            r=tc[i*sizeinput+k]-tc[j*sizeinput+k];
            s+=r*r;
           }
         if(s>max) max=s;
        }
   for(i=0; i<n; i++)
     {
      ArrayCopy(center,tc,i*totalinput,i*sizeinput,sizeinput);
      center[i*totalinput+sizeinput]=max/sqrt(n);
     }
   ArrayFree(nn);
   ArrayFree(tc);
   return(n);
  }
//+------------------------------------------------------------------+
void CNetRBF::SVD(int npat,const double &inp[],const double &res[])
  {
   int i,j,k,jj,ii;
   int n=0,nm=0,sw=sizehidden+1;
   double s,c,f,g,h,x,y,z;
   // allocated memory for svd matrices
   double cim[],im[],v[],w[],temp[];
   ArrayResize(cim,npat*sw);
   ArrayResize(v,sw*sw);
   ArrayResize(w,sw);
   ArrayResize(temp,sw);
   // fill input matrix
   for(i=0,ii=0; i<npat; i++,ii+=sw)
     {
      ArrayCopy(inputvector,inp,0,i*sizeinput,sizeinput);
      // compute output of current pattern
      Calculate(temp);
      for(j=0; j<sizehidden; j++) cim[ii+j]=hout[j];
      cim[ii+j]=-1.0;
     }
   for(int nout=0; nout<sizeoutput; nout++)
     {
      ArrayCopy(im,cim);
      // perform decomposition
      g=c=0.0;
      for(i=0,ii=0; i<sw; i++,ii+=sw)
        {
         n=i+2;
         temp[i]=c*g;
         g=s=c=0.0;
         if(i<npat)
           {
            for(k=i,jj=ii; k<npat; k++,jj+=sw) c+=fabs(im[jj+i]);
            if(c!=0.0)
              {
               for(k=i,jj=ii; k<npat; k++,jj+=sw)
                 {
                  im[jj+i]/=c;
                  s+=im[jj+i]*im[jj+i];
                 }
               f=im[ii+i];
               g=-SETSIGN(sqrt(s),f);
               h=f*g-s;
               im[ii+i]=f-g;
               for(j=n-1; j<sw; j++)
                 {
                  s=0.0;
                  for(k=i,jj=ii; k<npat; k++,jj+=sw) s+=im[jj+i]*im[jj+j];
                  f=s/h;
                  for(k=i,jj=ii; k<npat; k++,jj+=sw) im[jj+j]+=f*im[jj+i];
                 }
               for(k=i,jj=ii; k<npat; k++,jj+=sw) im[jj+i]*=c;
              }
           }
         w[i]=c*g;
         g=s=c=0.0;
         if(i+1<=npat && i+1!=sw)
           {
            for(k=n-1; k<sw; k++) c+=fabs(im[ii+k]);
            if(c!=0.0)
              {
               for(k=n-1; k<sw; k++)
                 {
                  im[ii+k]/=c;
                  s+=im[ii+k]*im[ii+k];
                 }
               f=im[ii+n-1];
               g=-SETSIGN(sqrt(s),f);
               h=f*g-s;
               im[ii+n-1]=f-g;
               for(k=n-1; k<sw; k++) temp[k]=im[ii+k]/h;
               for(j=n-1,jj=j*sw; j<npat; j++,jj+=sw)
                 {
                  s=0.0;
                  for(k=n-1; k<sw; k++) s+=im[jj+k]*im[ii+k];
                  for(k=n-1; k<sw; k++) im[jj+k]+=s*temp[k];
                 }
               for(k=n-1; k<sw; k++) im[ii+k]*=c;
              }
           }
        }
      for(i=sw-1,n=sw; i>=0; i--,n--)
        {
         if(i<sw-1)
           {
            if(g!=0.0)
              {
               for(j=n; j<sw; j++) v[j*sw+i]=(im[i*sw+j]/im[i*sw+n])/g;
               for(j=n; j<sw; j++)
                 {
                  s=0.0;
                  for(k=n; k<sw; k++) s+=im[i*sw+k]*v[k*sw+j];
                  for(k=n; k<sw; k++) v[k*sw+j]+=s*v[k*sw+i];
                 }
              }
            for(j=n; j<sw; j++) v[i*sw+j]=v[j*sw+i]=0.0;
           }
         v[i*sw+i]=1.0;
         g=temp[i];
        }
      for(i=MathMin(npat,sw)-1,n=i+1,ii=i*sw; i>=0; i--,n--,ii-=sw)
        {
         g=w[i];
         for(j=n; j<sw; j++) im[ii+j]=0.0;
         if(g!=0.0)
           {
            for(j=n; j<sw; j++)
              {
               for(s=0.0,k=n,jj=n*sw; k<npat; k++,jj+=sw) s+=im[jj+i]*im[jj+j];
               f=(s/im[i*sw+i])/g;
               for(k=i,jj=i*sw; k<npat; k++,jj+=sw) im[jj+j]+=f*im[jj+i];
              }
            for(j=i; j<npat; j++) im[j*sw+i]/=g;
           }
         else for(j=i; j<npat; j++) im[j*sw+i]=0.0;
         im[ii+i]++;
        }
      for(k=sw-1; k>=0; k--)
        {
         for(int m=0; m<30; m++)
           {
            bool flag=true;
            for(n=k; n>=0; n--)
              {
               nm=n-1;
               if(fabs(temp[n])<DBL_EPSILON)
                 {
                  flag=false;
                  break;
                 }
               if(fabs(w[nm])<DBL_EPSILON) break;
              }
            if(flag)
              {
               c=0.0;
               s=1.0;
               for(i=n; i<k+1; i++)
                 {
                  f=s*temp[i];
                  temp[i]*=c;
                  if(fabs(f)<=DBL_EPSILON) break;
                  h=sqrt(f*f+w[i]*w[i]);
                  c=w[i]/h;
                  w[i]=h;
                  s=-f*h;
                  for(j=0,jj=0; j<npat; j++,jj+=sw)
                    {
                     y=im[jj+nm];
                     z=im[jj+i];
                     im[jj+nm]=y*c+z*s;
                     im[jj+i]=z*c-y*s;
                    }
                 }
              }
            z=w[k];
            if(n==k)
              {
               if(z<0.0)
                 {
                  w[k]=-z;
                  for(j=0,jj=0; j<sw; j++,jj+=sw) v[jj+k]=-v[jj+k];
                 }
               break;
              }
            x=w[n];
            nm=k-1;
            f=((w[nm]-z)*(w[nm]+z)+(temp[nm]-temp[k])*(temp[nm]+temp[k]))/(2.0*temp[k]*w[nm]);
            f=((x-z)*(x+z)+temp[k]*((w[nm]/(f+SETSIGN(sqrt(f*f+1.0),f)))-temp[k]))/x;
            c=s=1.0;
            for(j=n,i=n+1; j<=nm; j++,i++)
              {
               h=s*temp[i];
               g=c*temp[i];
               temp[j]=sqrt(f*f+h*h);
               c=f/temp[j];
               s=h/temp[j];
               f=x*c+g*s;
               g=g*c-x*s;
               h=w[i]*s;
               y=w[i]*c;
               for(jj=0,ii=0; jj<sw; jj++,ii+=sw)
                 {
                  x=v[ii+j];
                  z=v[ii+i];
                  v[ii+j]=x*c+z*s;
                  v[ii+i]=z*c-x*s;
                 }
               z=sqrt(f*f+h*h);
               w[j]=z;
               if(z!=0)
                 {
                  z=1.0/z;
                  c=f*z;
                  s=h*z;
                 }
               f=c*g+s*y;
               x=c*y-s*g;
               for(jj=0,ii=0; jj<npat; jj++,ii+=sw)
                 {
                  y=im[ii+j];
                  z=im[ii+i];
                  im[ii+j]=y*c+z*s;
                  im[ii+i]=z*c-y*s;
                 }
              }
            temp[n]=0.0;
            temp[k]=f;
            w[k]=x;
           }
        }
      // perform back substitution to get result
      for(j=0; j<sw; j++)
        {
         s=0.0;
         if(w[j]>1e-20)
           {
            for(i=0; i<npat; i++) s+=im[i*sw+j]*res[i*sizeoutput+nout];
            s/=w[j];
           }
         temp[j]=s;
        }
      // set weights
      for(j=0; j<sw; j++)
        {
         s=0;
         for(i=0; i<sw; i++) s+=v[j*sw+i]*temp[i];
         if(j<sw-1) weight[nout*sizeweight+j]=s;
         else     weight[(nout+1)*sizeweight-1]=s;   //bias
        }
     }
   ArrayFree(im);
   ArrayFree(cim);
   ArrayFree(v);
   ArrayFree(w);
   ArrayFree(temp);
  }
//+------------------------------------------------------------------+
bool CNetRBF::Save(int handle)
  {
   FileWriteInteger(handle,sizeinput);
   FileWriteInteger(handle,sizeoutput);
   FileWriteInteger(handle,sizehidden);
   FileWriteInteger(handle,maxhidden);
   FileWriteInteger(handle,actfunc);
   FileWriteDouble(handle,mse);
   FileWriteInteger(handle,ArraySize(center));
   FileWriteArray(handle,center);
   FileWriteInteger(handle,ArraySize(weight));
   FileWriteArray(handle,weight);
   return(true);
  }
//+------------------------------------------------------------------+
bool CNetRBF::Load(int handle)
  {
   int n;
   if(FileReadInteger(handle)!=sizeinput) return(false);
   if(FileReadInteger(handle)!=sizeoutput) return(false);
   n=FileReadInteger(handle);
   if(n>maxhidden) return(false);
   sizehidden=n;
   neurons=n;
   epoch=0;
   if(FileReadInteger(handle)!=maxhidden) return(false);
   actfunc=FileReadInteger(handle);
   mse=FileReadDouble(handle);
   n=FileReadInteger(handle);
   if(n!=totalinput*maxhidden) return(false);
   if(FileReadArray(handle,center,0,n)!=n) return(false);
   n=FileReadInteger(handle);
   if(n!=sizeweight*sizeoutput) return(false);
   if(FileReadArray(handle,weight,0,n)!=n) return(false);
   return(true);
  }
//+------------------------------------------------------------------+
