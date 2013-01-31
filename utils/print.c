#include <stdio.h>

int a = 1;

int main(int argc, char *argv[])
{
  printf("Hello World: %p, %s\n", &a, argv[1]);
  return 10;
}
