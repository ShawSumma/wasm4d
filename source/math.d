module math;

enum PI = 3.1415926535897932384650288;

T max(T)(T a, T b)
{
    if (a < b)
    {
        return a;
    }
    else
    {
        return b;
    }
}

T min(T)(T a, T b)
{
    if (a > b)
    {
        return a;
    }
    else
    {
        return b;
    }
}

double sine(double x){
  double sign=1;
  if (x < 0) {
      sign = -1;
      x = -x;
  }
  x*=PI/180.0;
  double res=0;
  double term=x;
  int k=1;
  while (res+term!=res){
    res+=term;
    k+=2;
    term*=-x*x/k/(k-1);
  }
  return sign*res;
}

double cosine(double x) {
    return sine(x + 90);
}

float invDistance(size_t n)(float[n] x, float[n] y) {
    float n = 0;
    static foreach (i; 0..n) {
        {
            float ni = x[i] - y[i];
            n += ni * ni;
        }
    }
    return fastInverseSqrt(n);
}


float distance(size_t n)(float[n] x, float[n] y) {
    return 1 / invDistance(x, y);
}
