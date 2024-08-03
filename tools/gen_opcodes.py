#!/usr/bin/env/python3

import sys

misc_1000 = {
  "sbit":  "001100bb",
  "rbit":  "001101bb",
  "tbit1": "001110bb",
  "tcy":   "0100xxxx",
  "tcmiy": "0110xxxx",
  "ldx":   "001111xx",
  "ldp":   "0001xxxx",
  "alec":  "0111xxxx",
  "ynec":  "0101xxxx",
  "br":    "10xxxxxx",
  "call":  "11xxxxxx"
}

misc_1100 = {
  "sbit":  "001100bb",
  "rbit":  "001101bb",
  "tbit1": "001110bb",
  "tcy":   "0100xxxx",
  "tcmiy": "0110xxxx",
  "ldx":   "00101xxx",
  "ldp":   "0001xxxx",
  "ynec":  "0101xxxx",
  "br":    "10xxxxxx",
  "call":  "11xxxxxx"
}

tms1000_opcodes = [ ]
tms1100_opcodes = [ ]

tms1000_names = { }
tms1100_names = { }

tms1000_hex = { }
tms1100_hex = { }

def hex_to_bin(n):
  n = int(n, 16)
  s = ""

  for i in range(0, 8):
    if (n & 1) == 0:
      s = "0" + s
    else:
      s = "1" + s

    n = n >> 1

  return s

# ---------------------------- fold here -------------------------

if len(sys.argv) != 2:
  print("Usage: python3 get_opcodes.py <tables/tms1000.cpp>")
  sys.exit(1)

fp = open(sys.argv[1], "r")

in_opcodes = False

for line in fp:
  if "table_tms1000" in line:
    in_opcodes = True
    continue

  if not in_opcodes: continue

  if line.startswith("}"): break

  line = line.strip()
  line = line.replace("{", "").replace("}","")
  line = line.replace("\"", "")
  line = line.replace(" ", "")
  line = line.strip()

  if line == "": continue
  if line.startswith("NULL"): break

  if line.startswith("//"):
    line = line.replace("//", "")
    (name, op0, op1, a) = line.split(",")

    if name in misc_1000:
      opcode = misc_1000[name]
      tms1000_opcodes.append(opcode)
      tms1000_names[opcode] = name
      tms1000_hex[opcode] = "-"

    if name in misc_1100:
      opcode = misc_1100[name]
      tms1100_opcodes.append(opcode)
      tms1100_names[opcode] = name
      tms1100_hex[opcode] = "-"
  else:
    (name, op0, op1, a) = line.split(",")

    op0 = op0.strip()
    op1 = op1.strip()

    if op0 != "-1":
      opcode = hex_to_bin(op0)
      tms1000_opcodes.append(opcode)
      tms1000_names[opcode] = name
      tms1000_hex[opcode] = op0

    if op1 != "-1":
      opcode = hex_to_bin(op1)
      tms1100_opcodes.append(opcode)
      tms1100_names[opcode] = name
      tms1100_hex[opcode] = op1

fp.close()

tms1000_opcodes.sort()
tms1100_opcodes.sort()

#print(tms1000_names)

print("-- tms1000 --")

for opcode in tms1000_opcodes:
  print("%s %s [%s]" % (opcode, tms1000_names[opcode], tms1000_hex[opcode]))

print("-- tms1100 --")

for opcode in tms1100_opcodes:
  print("%s %s [%s]" % (opcode, tms1100_names[opcode], tms1100_hex[opcode]))

