.tms1000
.low_address 0
.high_address 1023

;; 0x3c0 (1111 000000) is the linear address for f/00.
.org 0x3c0

  ;; Load RAM address 0x04 with 0x8.
  tcy 0x2
  tya
  tcy 0x4
  ldx 0
  tam

  ;;a6aac
  ;;alem
  cla
  cpaiz

  ;; Load A with 4 and subtract A from RAM[4].
  tcy 0xf
  tya
  tcy 0x4
  saman

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

