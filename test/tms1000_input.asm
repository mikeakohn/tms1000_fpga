.tms1000
.low_address 0
.high_address 1023

;; 0x3c0 (1111 000000) is the linear address for f/00.
.org 0x3c0
start:

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

  ;; Read K input pins.
  tcy 0x1
  setr
  tka
  rstr

  ;; Set S if A is 0 or less (should be 1 if pin is high).
  alec 0
  br set_led

  ;; Clear LED.
  tcy 0x0
  rstr

  comx
  br start

set_led:
  ;; Set LED.
  tcy 0x0
  setr

  comx
  br start

