/* Copyright (C) 2003-2014 Free Software Foundation, Inc.

   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library.  If not, see
   <http://www.gnu.org/licenses/>.  */

#ifndef _OR1K_BITS_ATOMIC_H
#define _OR1K_BITS_ATOMIC_H     1

#include <stdint.h>

typedef int8_t  atomic8_t;
typedef int16_t atomic16_t;
typedef int32_t atomic32_t;

typedef uint8_t  uatomic8_t;
typedef uint16_t uatomic16_t;
typedef uint32_t uatomic32_t;

typedef intptr_t atomicptr_t;
typedef uintptr_t uatomicptr_t;
typedef intmax_t atomic_max_t;
typedef uintmax_t uatomic_max_t;

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

static size_t __strlen(const char *c)
{
  size_t s = 0;
  for(;*c != '\0'; ++c, ++s);
  return s;
}

#define STR_N_LEN(str) str, __strlen (str)

#define LOAD_ARGS_0()

#define ASM_ARGS_OUT_0
#define ASM_ARGS_IN_0
#define ASM_CLOBBERS_0  "r3", ASM_CLOBBERS_1

#define LOAD_ARGS_1(a)        \
    LOAD_ARGS_0 ()        \
  register long __a __asm__ ("r3") = (long)(a);
#define ASM_ARGS_OUT_1  ASM_ARGS_OUT_0, "=r" (__a)
#define ASM_ARGS_IN_1 ASM_ARGS_IN_0, "1" (__a)
#define ASM_CLOBBERS_1  "r4", ASM_CLOBBERS_2

#define LOAD_ARGS_2(a, b)     \
    LOAD_ARGS_1 (a)       \
  register long __b __asm__ ("r4") = (long)(b);
#define ASM_ARGS_OUT_2  ASM_ARGS_OUT_1, "=r" (__b)
#define ASM_ARGS_IN_2 ASM_ARGS_IN_1, "2" (__b)
#define ASM_CLOBBERS_2  "r5", ASM_CLOBBERS_3

#define LOAD_ARGS_3(a, b, c)      \
    LOAD_ARGS_2 (a, b)        \
  register long __c __asm__ ("r5") = (long)(c);
#define ASM_ARGS_OUT_3  ASM_ARGS_OUT_2, "=r" (__c)
#define ASM_ARGS_IN_3 ASM_ARGS_IN_2, "3" (__c)
#define ASM_CLOBBERS_3  "r6", ASM_CLOBBERS_4

#define LOAD_ARGS_4(a, b, c, d)     \
    LOAD_ARGS_3 (a, b, c)       \
  register long __d __asm__ ("r6") = (long)(d);
#define ASM_ARGS_OUT_4  ASM_ARGS_OUT_3, "=r" (__d)
#define ASM_ARGS_IN_4 ASM_ARGS_IN_3, "4" (__d)
#define ASM_CLOBBERS_4  "r7", ASM_CLOBBERS_5

#define LOAD_ARGS_5(a, b, c, d, e)    \
    LOAD_ARGS_4 (a, b, c, d)      \
  register long __e __asm__ ("r7") = (long)(e);
#define ASM_ARGS_OUT_5  ASM_ARGS_OUT_4, "=r" (__e)
#define ASM_ARGS_IN_5 ASM_ARGS_IN_4, "5" (__e)
#define ASM_CLOBBERS_5  "r8", ASM_CLOBBERS_6

#define LOAD_ARGS_6(a, b, c, d, e, f)   \
    LOAD_ARGS_5 (a, b, c, d, e)     \
  register long __f __asm__ ("r8") = (long)(f);
#define ASM_ARGS_OUT_6  ASM_ARGS_OUT_5, "=r" (__f)
#define ASM_ARGS_IN_6 ASM_ARGS_IN_5, "6" (__f)
#define ASM_CLOBBERS_6


#define __NR_write 64
#define DEBUG_MARKER(args...) \
        ({                                     \
            register long __sc_ret __asm__ ("r11") = __NR_write;          \
            LOAD_ARGS_3 (args)                                                 \
            __asm__ __volatile__ ("l.sys     1"                                \
                                           : "=r" (__sc_ret) ASM_ARGS_OUT_3    \
                                           : "0" (__sc_ret) ASM_ARGS_IN_3      \
                         : ASM_CLOBBERS_3                                      \
                           "r12", "r13", "r15", "r17", "r19",                  \
                           "r21", "r23", "r25", "r27", "r29",                  \
                           "r31", "memory");                                   \
            __asm__ __volatile__ ("l.nop");})

#define atomic_compare_and_exchange_val_acq(mem, newval, oldval) \
  ({                                                                    \
    DEBUG_MARKER (1, STR_N_LEN ("CAS @ " __FILE__ ":" TOSTRING(__LINE__) "\n")); \
    typeof (*mem) __oldval = (oldval);                                  \
    __atomic_compare_exchange_n (mem, (void *) &__oldval, newval, 0,    \
                                 __ATOMIC_ACQUIRE, __ATOMIC_RELAXED);   \
    __oldval;                                                           \
  })

#endif
