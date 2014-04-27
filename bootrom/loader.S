
/* Assembly program to go into the boot ROM */
/* For use with simple_spi SPI master core and standard SPI flash
   interface-compatible parts (ST M25P16 for example.)*/
/* Currently just loads a program from SPI flash into RAM */
/* Assuming address at RAM_LOAD_BASE gets clobbered, we need
   a byte writable address somewhere!*/

#define SPI_BASE SPI0_BASE
/* simple_spi driver */	
#define SPI_SPCR 0x0
#define SPI_SPSR 0x1
#define SPI_SPDR 0x2
#define SPI_SPER 0x3
#define SPI_SPSS 0x4

#define SPI_SPCR_XFER_GO 0x51
#define SPI_SPSS_INIT 0x1
#define SPI_SPSR_RX_CHECK 0x01 /* Check bit 0 is cleared, fifo !empty*/
	
#define RAM_LOAD_BASE SDRAM_BASE
#define RESET_ADDR 0x100



.equ UART,            0x90000000
.equ SYS_CLK,         50000000
.equ BAUD,            115200
.equ UART_DIVISOR,    SYS_CLK/(16*BAUD)
.equ UART_DLL,        0
.equ UART_DLM,        1
 
.org 0x100
 
.global _start
_start:
        # r29 = UART
        l.movhi r29, hi(UART)
        l.ori r29, r29, lo(UART)
 
        # Set up ttyS0
        l.addi  r3,r0,0x7
        l.sb  0x2(r29),r3
 
        l.addi  r3,r0,0x0
        l.sb  0x1(r29),r3
 
        l.addi  r3,r0,0x3
        l.sb  0x3(r29),r3
 
        l.lbz r5,3(r29)
        l.ori r3,r5,0x80
        l.sb  0x3(r29),r3
        l.addi  r3,r0,((UART_DIVISOR>>8) & 0x000000ff)
        l.sb  UART_DLM(r29),r3
        l.addi  r3,r0,((UART_DIVISOR) & 0x000000ff)
        l.sb  UART_DLL(r29),r3
        l.sb  0x3(r29),r5
 
        # Print banner
        l.movhi r3, hi(BANNER)
        l.ori r3, r3, lo(BANNER)

        # Retrieve character
1:      l.lbz r1, 0(r3)
 
        # Stop at \0
        l.sfeq r1,r0
        l.bf banner_done
        l.nop
 
        l.jal putc
        l.nop
 
        # Next character
        l.j 1b
        l.addi r3, r3, 0x1
 
banner_done:
 
        # Progress character
        l.addi r1, r0, '.'
 
        l.jal putc
        l.nop

        # Prints r1 to UART
putc:
1:      l.lbz   r5, 5(r29)
        l.andi  r5, r5, 0x20
        l.sfeqi r5, 0x20
        l.bnf   1b
        l.nop
 
        # Write
        l.sb    0(r29), r1
 
        # Wait
1:      l.lbz   r5,5(r29)
        l.andi  r5,r5,0x60
        l.sfeqi r5, 0x60
        l.bnf   1b
        l.nop
 
        # Done
        l.jr r9
        l.nop
 
BANNER:
        .string "ORPSoC Boot ROM, loading from flash...\n\0"
        .align
