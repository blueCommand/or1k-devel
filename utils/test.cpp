// Testcase for proper handling of
// c++ type, constructors and destructors.

#include <stdio.h>
#include <cstdlib>

int c, d;

struct A
{
  int i;
  A () { i = ++c; printf ("A() %d\n", i); }
  A (const A&) { i = ++c; printf ("A(const A&) %d\n", i); }
  ~A() { printf ("~A() %d\n", i); ++d; }
};

void
f()
{
  printf ("Throwing 1...\n");
  throw A();
}

void another_function(int arg)
{
  printf("test: %d\n", arg);
}


int
main (int argc, char *argv[])
{
  try
  {
    A a;
    try
      {
        f();
      }
    catch (A)
      {
        printf ("Caught.\n");
      }
  }
  catch(...)
  {
    abort();
  }
  printf ("c == %d, d == %d\n", c, d);

  another_function(c);
  return c != d;
}
