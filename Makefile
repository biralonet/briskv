YOSYS = yowasp-yosys
NEXTPNR = nextpnr-himbaechel
GOWIN_PACK = gowin_pack

DEVICE = GW2AR-LV18QN88C8/I7
FAMILY = GW2A-18C
CONSTRAINT_FILE = tangnano20k.cst
TOP_MODULE = top

.DEFAULT_GOAL := test

build: briskv.fs

test: test.v briskv.v
	iverilog -DBENCH -DBOARD_FREQ=10 test.v briskv.v -o briskv

flash: build
	openFPGALoader -b tangnano20k briskv.fs

clean:
	rm -f briskv.json pnrbriskv.json briskv.fs briskv

briskv.json: briskv.v soc.v clock.v
	@echo "Synthesizing with yosys..."
	$(YOSYS) -p "read_verilog $<; synth_gowin -top $(TOP_MODULE) -json $@"

pnrbriskv.json: briskv.json $(CONSTRAINT_FILE)
	@echo "Place and Route with nextpnr..."
	$(NEXTPNR) --json $< --write $@ --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CONSTRAINT_FILE)

briskv.fs: pnrbriskv.json
	@echo "Packing bitstream with gowin_pack..."
	$(GOWIN_PACK) -d $(FAMILY) -o $@ $<

.PHONY: test build flash clean
