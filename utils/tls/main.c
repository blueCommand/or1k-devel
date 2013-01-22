#include <stdio.h>

int main()
{
  register unsigned long r10 asm("r10");
  register unsigned long r13 asm("r13");
  register unsigned long r3  asm("r3");

  printf("Testing TLS constructs..\n");

  asm("l.ori r13,r0,25" : : : "r13");

  asm("l.movhi   r3,tpoffhi(foo)\r\n"
      "l.ori     r3,r3,tpofflo(foo)\r\n"
      "l.add     r3,r3,r10\r\n"
      "l.lwz     r3, 0(r3)\r\n" : : : "r3");

  printf("r10: %08x, r3: %08x, r13: %08x\n", r10, r3, r13);

  while(1);
  return 0;
}
