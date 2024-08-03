.tms1100
.high_address 1023

start:
  tcy 0x0
  setr

delay_0:
  ldx 0
  tcy 0x0
  imac
  tamza
  mnez
  br delay_0
  ldx 0
  tcy 0x1
  imac
  tamza
  mnez
  br delay_0
  ldx 0
  tcy 0x2
  imac
  tamza
  mnez
  br delay_0

  tcy 0x0
  rstr

delay_1:
  ldx 0
  tcy 0x0
  imac
  tamza
  mnez
  br delay_1
  ldx 0
  tcy 0x1
  imac
  tamza
  mnez
  br delay_1
  ldx 0
  tcy 0x2
  imac
  tamza
  mnez
  br delay_1

  comx
  br start

