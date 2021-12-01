extern(C) ubyte* memcpy(ubyte* dest, const(ubyte)* src, size_t len) {
  ubyte* d = dest;
  const(ubyte)* s = src;
  while (len--)
    *d++ = *s++;
  return dest;
}