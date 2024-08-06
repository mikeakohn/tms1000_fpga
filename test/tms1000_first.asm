.tms1000
.low_address 0
.high_address 1023

  tcy 0xa
  ldx 2
  tya

halt:
  ia
  br halt

