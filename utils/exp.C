#include <stdio.h>
#include <exception>
#include <cstdlib>

int main() {
  //std::set_terminate(__gnu_cxx::__verbose_terminate_handler);
  //
  std::set_terminate(std::abort);

#if 0
  printf("Throwing\n");
  throw 1;

#else
  try {
    printf("Throwing\n");
    throw 1;
  }
  catch (...) {
    printf(" in catch\n");
    return 1;
  }
  printf(" back in main\n");
#endif
  return 10;
}

