YOSYS = yowasp-yosys
NEXTPNR = nextpnr-himbaechel
GOWIN_PACK = gowin_pack

DEVICE = GW2AR-LV18QN88C8/I7
FAMILY = GW2A-18C
CONSTRAINT_FILE = tangnano20k.cst
TOP_MODULE = top

.DEFAULT_GOAL := test

flash: build
	openFPGALoader -b tangnano20k briskv.fs

build: briskv.fs

test: briskv
	vvp briskv

briskv: test.v briskv.v soc.v
	iverilog -DBENCH -DBOARD_FREQ=10 test.v briskv.v -o briskv

briskv.json: briskv.v soc.v clock.v
	$(YOSYS) -p "read_verilog $<; synth_gowin -top $(TOP_MODULE) -json $@"

pnrbriskv.json: briskv.json $(CONSTRAINT_FILE)
	$(NEXTPNR) --json $< --write $@ --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CONSTRAINT_FILE)

briskv.fs: pnrbriskv.json
	$(GOWIN_PACK) -d $(FAMILY) -o $@ $<

clean:
	rm -f briskv.json pnrbriskv.json briskv.fs briskv hello.o hello.bin

.PHONY: test build flash clean
