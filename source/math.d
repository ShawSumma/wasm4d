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

float sin(float x) {
    double sign=1;
    if (x < 0) {
        sign = -1;
        x = -x;
    }
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

float cos(float x) {
    return sin(x + PI / 2);
}

float invDistance(T, size_t n)(T[n] x, T[n] y) {
    float ret = 0;
    static foreach (i; 0..n) {
        {
            T ni = x[i] - y[i];
            ret += cast(float) ni * cast(float) ni;
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
	y  = y * (threehalfs - (x2 * y * y));   

	return y;
}

// Max error < 0.005 (or 0.29 degrees)
float atan(float z)
{
    const float n1 = 0.97239411f;
    const float n2 = -0.19194795f;
    return (n1 + n2 * z * z) * z;
}

float atan2(float y, float x)
{
    if (x != 0.0f)
    {
        if (abs(x) > abs(y))
        {
            const float z = y / x;
            if (x > 0.0)
            {
                // atan2(y,x) = atan(y/x) if x > 0
                return atan(z);
            }
            else if (y >= 0.0)
            {
                // atan2(y,x) = atan(y/x) + PI if x < 0, y >= 0
                return atan(z) + PI;
            }
            else
            {
                // atan2(y,x) = atan(y/x) - PI if x < 0, y < 0
                return atan(z) - PI;
            }
        }
        else // Use property atan(y/x) = PI/2 - atan(x/y) if |y/x| > 1.
        {
            const float z = x / y;
            if (y > 0.0)
            {
                // atan2(y,x) = PI/2 - atan(x/y) if |y/x| > 1, y > 0
                return -atan(z) + PI/2;
            }
            else
            {
                // atan2(y,x) = -PI/2 - atan(x/y) if |y/x| > 1, y < 0
                return -atan(z) - PI/2;
            }
        }
    }
    else
    {
        if (y > 0.0f) // x = 0, y > 0
        {
            return PI/2;
        }
        else if (y < 0.0f) // x = 0, y < 0
        {
            return -PI/2;
        }
    }
    return 0.0f; // x,y = 0. Could return NaN instead.
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
