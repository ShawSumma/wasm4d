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

T abs(T)(T v) {
    if (v < 0) {
        return -v;
    } else {
        return v;
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

float invDistance(T, size_t n)(T[n] x, T[n] y) {
    float ret = 0;
    static foreach (i; 0..n) {
        {
            T ni = x[i] - y[i];
            ret += cast(float) ni * ni;
        }
    }
    return fastInverseSqrt(ret);
}

float distance(T, size_t n)(T[n] x, T[n] y) {
    return 1 / invDistance(x, y);
}

float fastInverseSqrt(float number)
{
	long i;
	float x2, y;
	const float threehalfs = 1.5F;

	x2 = number * 0.5F;
	y  = number;
	i  = * cast(int *) &y;                       
	i  = 0x5f3759df - ( i >> 1 );               
	y  = * cast(float *) &i;
	y  = y * (threehalfs - (x2 * y * y));   

	return y;
}

float atan2( float y, float x )
{
    uint sign_mask = 0x80000000;
    float b = 0.596227;

    // Extract the sign bits
    uint ux_s  = sign_mask & *cast(uint *)&x;
    uint uy_s  = sign_mask & *cast(uint *)&y;

    // Determine the quadrant offset
    float q = cast(float)( ( ~ux_s & uy_s ) >> 29 | ux_s >> 30 ); 

    // Calculate the arctangent in the first quadrant
    float bxy_a = abs( b * x * y );
    float num = bxy_a + y * y;
    float atan_1q =  num / ( x * x + bxy_a + num );

    // Translate it to the proper quadrant
    uint uatan_2q = (ux_s ^ uy_s) | *cast(uint *)&atan_1q;
    return q + *cast(float *)&uatan_2q;
} 


float lerp(float a, float b, float mix) 
{
    return a * mix + b * (1 - mix);
}

T total(T, size_t n)(T[n] vals) {
    T ret = 0;
    foreach (v; vals) {
        ret += v;
    }
    return ret;
}
