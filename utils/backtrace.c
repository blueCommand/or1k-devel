#include <unwind.h> // GCC's internal unwinder, part of libgcc
_Unwind_Reason_Code trace_fcn(struct _Unwind_Context *ctx, void *d)
{
  int *depth = (int*)d;
  printf("\t#%d: program counter at %08x\n", *depth, _Unwind_GetIP(ctx));
  (*depth)++;
  return _URC_NO_REASON;
}

void print_backtrace_here()
{
  int depth = 0;
  _Unwind_Backtrace(&trace_fcn, &depth);
}

int func3() { print_backtrace_here(); return 0; }
int func2() { return func3(); }
int func1() { return func2(); }
int main()  { return func1(); }
