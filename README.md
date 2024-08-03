# TMS1000

This is an implementation of the Texas Instrumens TMS1000 and TMS1100 in an
FPGA. The board being used here is an iceFUN with a Lattice iCE40 HX8K FPGA.

https://www.mikekohn.net/micro/tms1000_fpga.php

The original CPU runs 6 cycles per instruction, but this one is 3.
This can be compensated for by slowing the clock down.

Registers
=========

TMS1000 and TMS1100 have the folloing registers:

    A: 4 bit
    Y: 4 bit
    X: 2 bit on TMS1000 and 3 bit on TMS1100

For accessing RAM, the XY registers are combined to create a pointer
to RAM. So to access the nybble at location 0x18, X would be loaded with
0x1 and Y would be loaded with 0x8.

For loading instructions out of RAM there are 3 registers:

   PC: 6 bit
   PA: 4 bit (page address, called page in the Verilog)
   CA: 1 bit (chapter address, called chapter in the Verilog)

There is also a status register which, depending on the instruction will
be used as a carry flag, a not equal flag, or set to 1. All instructions
will change the flag. Again, if it's not valid for the instruction it's
always set to 1.

To save context when using the "call" function, there are some extra
registers:

    SR: Saved value of PC before subroutine call.
    PB: Saved PA (page) value before subroutine call.
    CB: Saved CA (chapter) value before subroutine call.
    CL: Call latch which is set when in a subroutine to protect SR, PB.
    CS: Chapter subroutine.

The PC (program counter) in the TMS1000 series doesn't increment by 1.
Instead it uses an LFSR (linear feedback shift register) algorithm.
Some sample code to show how it works in Python3 is in tools/pc_calc.py.
The algorithm here basically is:

    If PC is currently 0x1f: PC = (PC << 1) | 1
    If PC is currently 0x3f: PC = (PC << 1) | 0
                       Else: PC = (PC << 1) | ~(PC[bit5] ^ PC[bit4])

Memories
========

TMS1000
-------

    ROM: 1024 bytes (8 bit)
    RAM: 64 nybbles (4 bit)

TMS1100
-------

    ROM: 2048 bytes  (8 bit)
    RAM: 128 nybbles (4 bit)

I/O
===

Input
-----

There are 4 pins for input K1, K2, K3, K4.

Output
------

There are two output ports that are very different in function.
There are 8 O pins (O0 to O7) and 11 R pins (R0 to R10). The instruction
set could actually support 15 R pins if needed and that would be simple
to add to the Verilog.

The R register is a pretty standard output only register. The pins can
be turned off individtually with the setr, rstr instructions using the
Y register to point to which pin to change.

The O register is a special one. Depending on the value of the status
register, the 8 bits are set based on the value of the A register.
The logic (using the tdo instruction) is like this:

    If flag_s is 0: O register = A;
    If flag_s is 1: O is treated as a 7 seg LED display and set to 0 to F
                    depending on the value of A.

Instructions
============

These are generated by tools/gen_opcodes.py using table/tms1000.cpp from
the naken_asm assembler source repo. Opcodes are sorted by their binary
representation to make it easier to implement in Verilog.

TMS1000
-------

    00000000 comx   [0x00] Complement X.
    00000001 a8aac  [0x01] Add 8  to A setting status (as carry).
    00000010 ynea   [0x02] Status = Y != A.
    00000011 tam    [0x03] ram[XY] = A.
    00000100 tamza  [0x04] ram[XY] = A; A = 0.
    00000101 a10aac [0x05] Add 10 to A setting status (as carry).
    00000110 a6aac  [0x06] Add 6  to A setting status (as carry).
    00000111 dan    [0x07] A--; status set if no borrow
    00001000 tka    [0x08] A = value of K input pins.
    00001001 knez   [0x09] Status = (K input pins != 0).
    00001010 tdo    [0x0a] Output O = status / A (as described above).
    00001011 clo    [0x0b] Output O = 0.
    00001100 rstr   [0x0c] Set ouput R[Y] = 1.
    00001101 setr   [0x0d] Set ouput R[Y] = 0.
    00001110 ia     [0x0e] A++; status always 1.
    00001111 retn   [0x0f] Return from subroutine.
    0001xxxx ldp    [0x1-] PB = 4 bit immediate value.
    00100000 tamiy  [0x20] ram[XY] = A; A++.
    00100001 tma    [0x21] A = ram[XY].
    00100010 tmy    [0x22] Y = ram[XY].
    00100011 tya    [0x23] Y = A.
    00100100 tay    [0x24] A = Y.
    00100101 amaac  [0x25] A = A + ram[xy]; Set status (as carry).
    00100110 mnez   [0x26] Status = ram[XY] != 0.
    00100111 saman  [0x27] A = ram[XY] - A; Set status (as borrow).
    00101000 imac   [0x28] A = ram[XY] + 1; Set status (as carry).
    00101001 alem   [0x29] Set status if A <= ram[XY].
    00101010 dman   [0x2a] A = ram[XY] - 1; Set status (as borrow). 
    00101011 iyc    [0x2b] Y++; Set status (as carry).
    00101100 dyn    [0x2c] Y--; Set status (as borrow).
    00101101 cpaiz  [0x2d] A = -A; Set status if 0.
    00101110 xma    [0x2e] A <--> ram[XY].
    00101111 cla    [0x2f] A = 0;
    001100bb sbit   [-]    Set bit in ram[XY].
    001101bb rbit   [-]    Clear bit in ram[XY].
    001110bb tbit1  [-]    Test bit in ram[XY].
    001111xx ldx    [-]    Load X with immediate value.
    0100xxxx tcy    [0x4-] Load Y with immediate.
    0101xxxx ynec   [0x5-] Set status if ram[XY] != immediate value.
    0110xxxx tcmiy  [0x6-] ram[XY] = immediate; Y++.
    0111xxxx alec   [0x7-] Set status if A <= immediate.
    10xxxxxx br     [-]    Branch to address if status is set.
    11xxxxxx call   [-]    Call subroutine if status is set.

TMS1100
-------

    00000000 mnea   [0x00] Set status if A != ram[XY].
    00000001 alem   [0x01] Set status if A <= ram[XY].
    00000010 ynea   [0x02] Status = Y != A.
    00000011 xma    [0x03] A <--> ram[XY].
    00000100 dyn    [0x04] Y--; Set status (as borrow).
    00000101 iyc    [0x05] Y++; Set status (as carry).
    00000110 amaac  [0x06] A = ram[XY] + A; Set status (as carry).
    00000111 dman   [0x07] A = ram[XY] - 1; Set status (as borrow).
    00001000 tka    [0x08] A = value of K input pins.
    00001001 comx   [0x09] Complement upper bit of X.
    00001010 tdo    [0x0a] Output O = status / A (as described above).
    00001011 comc   [0x0b] Complement chapter flag.
    00001100 rstr   [0x0c] Set ouput R[Y] = 1.
    00001101 setr   [0x0d] Set ouput R[Y] = 0.
    00001110 knez   [0x0e] Status = (K input pins != 0).
    00001111 retn   [0x0f] Return from subroutine.
    0001xxxx ldp    [0x1-] PB = 4 bit immediate value.
    00100000 tay    [0x20] Y = A.
    00100001 tma    [0x21] A = ram[XY].
    00100010 tmy    [0x22] Y = ram[XY].
    00100011 tya    [0x23] A = Y.
    00100100 tamdyn [0x24] ram[XY] = A; Y--; Set status (as borrow).
    00100101 tamiyc [0x25] ram[XY] = A; Y++; Set status (as carry).
    00100110 tamza  [0x26] ram[XY] = A; A = 0.
    00100111 tam    [0x27] ram[XY] = A.
    00101xxx ldx    [-]    Load X with immediate value.
    001100bb sbit   [-]    Set bit in ram[XY].
    001101bb rbit   [-]    Clear bit in ram[XY].
    001110bb tbit1  [-]    Test bit in ram[XY].
    00111100 saman  [0x3c] A = ram[XY] - A; Set status (as borrow).
    00111101 cpaiz  [0x3d] A = -A; Set status if 0.
    00111110 imac   [0x3e] A = ram[XY] + 1; Set status (as carry).
    00111111 mnez   [0x3f] Status = ram[XY] != 0.
    0100xxxx tcy    [-]    Load Y with immediate.
    0101xxxx ynec   [-]    Set status if ram[XY] != immediate value.
    0110xxxx tcmiy  [-]    ram[XY] = immediate; Y++.
    01110000 iac    [0x70] A++; Set status (as carry bit).
    01110001 a9aac  [0x71] Add 9  to A setting status (as carry).
    01110010 a5aac  [0x72] Add 5  to A setting status (as carry).
    01110011 a13aac [0x73] Add 13 to A setting status (as carry).
    01110100 a3aac  [0x74] Add 3  to A setting status (as carry).
    01110101 a11aac [0x75] Add 11 to A setting status (as carry).
    01110110 a7aac  [0x76] Add 7  to A setting status (as carry).
    01110111 dan    [0x77] A--; status set if no borrow
    01111000 a2aac  [0x78] Add 2  to A setting status (as carry).
    01111001 a10aac [0x79] Add 10 to A setting status (as carry).
    01111010 a6aac  [0x7a] Add 6  to A setting status (as carry).
    01111011 a14aac [0x7b] Add 14 to A setting status (as carry).
    01111100 a4aac  [0x7c] Add 4  to A setting status (as carry).
    01111101 a12aac [0x7d] Add 12 to A setting status (as carry).
    01111110 a8aac  [0x7e] Add 8  to A setting status (as carry).
    01111111 cla    [0x7f] A = 0;
    10xxxxxx br     [-]    Branch to address if status is set.
    11xxxxxx call   [-]    Call subroutine if status is set.
