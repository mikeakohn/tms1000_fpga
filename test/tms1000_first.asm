.tms1000
.low_address 0
.high_address 1023

// 0x3c0 (1111 000000) is the linear address for f/00.
.org 0x3c0

  tcy 0xa
  ldx 2
  tya

halt:
  ia
  br halt

