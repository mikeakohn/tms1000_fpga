
PROGRAM=tms1000
SOURCE=src/$(PROGRAM).v

default:
	yosys -q -p "synth_ice40 -top $(PROGRAM) -json $(PROGRAM).json" $(SOURCE)
	nextpnr-ice40 -r --hx8k --json $(PROGRAM).json --package cb132 --asc $(PROGRAM).asc --opt-timing --pcf icefun.pcf
	icepack $(PROGRAM).asc $(PROGRAM).bin

tms1100:
	yosys -q -p "synth_ice40 -top tms1100 -json tms1100.json" src/tms1100.v
	nextpnr-ice40 -r --hx8k --json tms1100.json --package cb132 --asc tms1100.asc --opt-timing --pcf icefun.pcf
	icepack tms1100.asc tms1100.bin

blips:
	yosys -q -p "synth_ice40 -top iceblips -json $(PROGRAM).json" src/iceblips.v src/tms1000.v
	nextpnr-ice40 -r --lp1k --json $(PROGRAM).json --package cm36 --asc $(PROGRAM).asc --opt-timing --pcf iceblips.pcf --pcf-allow-unconstrained
	icepack $(PROGRAM).asc $(PROGRAM).bin

program:
	iceFUNprog $(PROGRAM).bin

blink:
	naken_asm -l -type bin -o rom.bin test/tms1000_blink.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

first:
	naken_asm -l -type bin -o rom.bin test/tms1000_first.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

second:
	naken_asm -l -type bin -o rom.bin test/tms1000_second.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

blink_tms1100:
	naken_asm -l -type bin -o rom.bin test/tms1100_blink.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

simon:
	#python3 tools/bin2txt.py mp3300.bin > rom.txt
	python3 tools/bin2txt.py simon.bin > rom.txt

clean:
	@rm -f $(PROGRAM).bin $(PROGRAM).json $(PROGRAM).asc *.lst
	@rm -f blink.bin test_alu.bin test_shift.bin test_subroutine.bin
	@rm -f button.bin
	@echo "Clean!"

