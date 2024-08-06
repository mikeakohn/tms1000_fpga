.tms1000
.low_address 0
.high_address 1023

  cla
  dan

  tcy 0xa
  ldx 2

  tamiy
  dan
  tamiy
  dan

  tcy 0xa
  imac

halt:
  comx
  br halt

