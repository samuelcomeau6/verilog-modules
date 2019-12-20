SRC = $(wildcard *_tb.v)
SRC := $(addprefix .,$(SRC))
DEPS =
PINS_DEF = pins.pcf
DEV = lp8k
PACK = cm81


all: $(SRC:_tb.v=test)

%_tb: %_tb.v %.v
	@iverilog -o $@ $^

%_tb.vcd: %_tb
	vvp -iN $< +vcd=$@

clean:
	rm -f *.blif *.asc *.rpt *.bin *.vcd

.%test: %_tb
	@vvp -iN $<
	@echo Sat > $@
	@git commit -m "Auto-commit on successful build"

%.blif: %.v
	yosys -p 'synth_ice40 -blif $@' $< $(DEPS)

%.asc: $(PINS_DEF) %.blif
	arachne-pnr -q -d 8k -P $(PACK) -o $@ -p $^

%.rpt: %.asc
	icetime -d $(DEV) -mtr $@ $<


.SECONDARY:
.PHONY: all prog clean flash
.SILENT: