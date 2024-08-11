.tms1100
.low_address 0
.high_address 2047

;; 0x3c0 (1111 000000) is the linear address for f/00.
.org 0x3c0
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

