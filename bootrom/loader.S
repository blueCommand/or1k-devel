
/* Assembly program to go into the boot ROM */
/* For use with simple_spi SPI master core and standard SPI flash
   interface-compatible parts (ST M25P16 for example.)*/
/* Currently just loads a program from SPI flash into RAM */
/* Assuming address at RAM_LOAD_BASE gets clobbered, we need
   a byte writable address somewhere!*/

#define SPI0_BASE           0xb0000000
#define SPI0_IRQ                     6

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
	
#define SDRAM_BASE                 0x0
#define RAM_LOAD_BASE SDRAM_BASE
#define RESET_ADDR 0x100

#define BOOTROM_ADDR_BYTE2 0x0b
#define BOOTROM_ADDR_BYTE1 0x00
#define BOOTROM_ADDR_BYTE0 0x00

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
        l.movhi r3, hi(banner)
        l.ori r3, r3, lo(banner)

        # Retrieve character
1:      l.lbz r10, 0(r3)
 
        # Stop at \0
        l.sfeq r10, r0
        l.bf spi_init
        l.nop
 
        l.jal putc
        l.nop
 
        # Next character
        l.j 1b
        l.addi r3, r3, 0x1
 
        # Prints r10 to UART
putc:
1:      l.lbz   r5, 5(r29)
        l.andi  r5, r5, 0x20
        l.sfeqi r5, 0x20
        l.bnf   1b
        l.nop
 
        # Write
        l.sb    0(r29), r10
 
        # Wait
1:      l.lbz   r5,5(r29)
        l.andi  r5,r5,0x60
        l.sfeqi r5, 0x60
        l.bnf   1b
        l.nop
 
        # Done
        l.jr r9
        l.nop

spi_init:
	l.movhi r1, RAM_LOAD_BASE
	l.movhi r4, hi(SPI_BASE)
	l.ori 	r2, r0, SPI_SPCR_XFER_GO /* Setup SPCR with enable bit set */
	l.sb 	SPI_SPCR(r4), r2
	l.sb  	SPI_SPSS(r4), r0         /* Clear SPI slave selects */
	l.ori 	r6, r0, SPI_SPSS_INIT
	l.sb  	SPI_SPSS(r4), r6         /* Set appropriate slave select */
	l.jal	spi_xfer
	l.ori 	r3, r0, 0x3              /* READ command opcode for SPI device*/
	l.jal 	spi_xfer
	l.ori 	r3, r0, BOOTROM_ADDR_BYTE2 /* Use addr if defined. MSB first */
	l.jal 	spi_xfer
	l.ori 	r3, r0, BOOTROM_ADDR_BYTE1
	l.jal 	spi_xfer
	l.ori 	r3, r0, BOOTROM_ADDR_BYTE0
	l.movhi r6, 0
	l.movhi r7, 0xffff	

copy:	
	l.jal 	spi_xfer         /* Read a byte into r3 */
	l.add 	r8, r1, r6       /* Calculate store address */
	l.sb 	0(r8), r3        /* Write byte to memory */
	l.addi 	r6, r6, 1        /* Increment counter */
	l.sfeqi r6, 0x4          /* Is this the first word ?*/
	l.bf 	store_sizeword   /* put sizeword in the register */
        l.nop

        # Show progress on UART
	l.andi 	r8, r6, 0xff
	l.sfeqi r8, 0
	l.bnf   1f
	 l.nop
	l.jal   putc
	 l.ori   r10, r0, '.'
1:

	l.sfeq 	r6, r7           /* Check if we've finished loading the words */
	l.bnf 	copy             /* Continue copying if not last word */
	l.nop

goto_reset:
        l.jal putc
        l.ori r10, r0, '!'
        l.jal putc
        l.ori r10, r0, '\r'
        l.jal putc
        l.ori r10, r0, '\n'

	l.ori 	r1, r1, RESET_ADDR
	l.jr 	r1
	l.sb  	SPI_SPSS(r4), r0 /* Clear SPI slave selects */
	
store_sizeword:

	l.lwz 	r7, 0(r1)        /* Size word is in first word of SDRAM */
	l.srli	r10, r7, 16	 /* Chop the sizeword we read in half */
	l.sfgtui r10, 0x0200	 /* It's unlikely we'll ever load > 32MB */
	l.bf	_start
	l.nop
	l.j 	copy
	l.nop

spi_xfer:
	l.sb 	SPI_SPDR(r4), r3  /* Dummy write what's in r3 */
	l.ori 	r3, r0, SPI_SPSR_RX_CHECK /* r3 = , ensure loop just once */
spi_xfer_poll:	
	l.andi 	r3, r3, SPI_SPSR_RX_CHECK /* AND read fifo bit empty */
	l.sfeqi r3, SPI_SPSR_RX_CHECK    /* is bit set? ... */
	l.bf 	spi_xfer_poll     /* ... if so, rxfifo empty, keep polling */
	l.lbz 	r3, SPI_SPSR(r4) /* Read SPSR */
	l.jr 	r9
	l.lbz 	r3, SPI_SPDR(r4) /* Get data byte */

banner:
        .string "ORPSoC Boot ROM, loading from flash: \0"
        .align
