#!/usr/bin/env/python3

def calc():
  pc = 0

  for i in range(0, 64):
    print("%02x %02x" % (i, pc))

    if pc == 0x1f:
      fb = 1;
    elif pc == 0x3f:
      fb = 0;
    else:
      bit5 = (pc >> 5) & 1
      bit4 = (pc >> 4) & 1
      #fb = bit5 == bit4
      fb = (bit5 ^ bit4) ^ 1

    pc = (pc << 1 | fb) & 0x3f;

calc()

