  .section ".tdata","awT",@progbits
foo:  .long 25
foo1:  .long 30
  .text

test:
  l.ori r13, r0, 25
  l.ori r14, r0, 30

  # Global dynamic
  l.movhi   r3,tlsgdhi(foo)
  l.ori     r3,r3,tlsgdlo(foo)
  l.add     r3,r3,r10
  #l.jal     plt(__tls_get_addr)

  # Local dynamic
  l.movhi   r3,tlsldmhi(foo)
  l.ori     r3,r3,tlsldmlo(foo)
  l.add     r3,r3,r10
  #l.jal     plt(__tls_get_addr)

  # r3 now contains the address of the TLS block
  l.movhi   r4,dtpoffhi(foo1)
  l.ori     r4,r4,dtpofflo(foo1)
  l.add     r4,r4,r3

  # Initial exec
  # Load offset from GOT
  l.movhi   r3,gottpoffhi(foo)
  #l.lwz     r3,gottpofflo(foo)(r10)
  l.add     r3,r3,r10

  #l.lwz     r3, 0(r3)
  #l.sfeq    r3, r13
  #l.bnf     failed
  #l.nop

test_le:
  l.ori r13, r0, 25

  # Local exec
  l.movhi   r3,tpoffhi(foo)
  l.ori     r3,r3,tpofflo(foo)
  l.add     r3,r3,r10

  l.lwz     r3, 0(r3)

  l.jr  r9
  l.nop

