
all: icezero.bin

prog: icezero.bin icezprog
	./icezprog icezero.bin

reset: icezprog
	./icezprog .

icezprog: icezprog.c
	gcc -o icezprog -Wall -Os icezprog.c -lwiringPi -lrt -lstdc++

icezero.json: icezero.v memdata.dat defines.vh
	yowasp-yosys -p 'synth_ice40 -top top -json icezero.json' icezero.v

icezero.asc: icezero.json icezero.pcf
	#arachne-pnr -d 8k -P tq144:4k -p icezero.pcf -o icezero.asc icezero.blif
	yowasp-nextpnr-ice40 --hx8k --package tq144:4k --json icezero.json --pcf icezero.pcf --asc icezero.asc

icezero.bin: icezero.asc
	#icetime -d hx8k -c 25 icezero.asc
	yowasp-icepack icezero.asc icezero.bin

memdata.dat: generate.py
	python generate.py

defines.vh: memdata.dat

testbench: testbench.v icezero.v
	iverilog -o testbench testbench.v icezero.v ../../icosoc/common/sim_sram.v $(shell yosys-config --datdir/ice40/cells_sim.v)

testbench.vcd: testbench
	./testbench

clean:
	rm -f testbench testbench.vcd
	rm -f icezero.json icezero.asc icezero.bin
	rm -f memdata.dat defines.vh

.PHONY: all prog reset clean

