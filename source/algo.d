module algo;

void swap(T)(ref T a, ref T b) {
    T tmp = b;
    b = a;
    a = tmp;
}
