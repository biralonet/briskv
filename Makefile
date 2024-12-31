YOSYS = yowasp-yosys
NEXTPNR = nextpnr-himbaechel
GOWIN_PACK = gowin_pack

OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump
AS = riscv64-unknown-elf-as

DEVICE = GW2AR-LV18QN88C8/I7
FAMILY = GW2A-18C
CONSTRAINT_FILE = tangnano20k.cst
TOP_MODULE = top

.DEFAULT_GOAL := test

build: briskv.fs

flash: briskv.fs
	openFPGALoader -b tangnano20k briskv.fs

test: briskv
	vvp briskv

briskv: test.v briskv.v soc.v instructions.mem
	iverilog -DBENCH -DBOARD_FREQ=10 test.v briskv.v -o briskv

briskv.json: briskv.v soc.v clock.v instructions.mem
	$(YOSYS) -p "read_verilog $<; synth_gowin -top $(TOP_MODULE) -json $@"

pnrbriskv.json: briskv.json $(CONSTRAINT_FILE)
	$(NEXTPNR) --json $< --write $@ --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CONSTRAINT_FILE)

briskv.fs: pnrbriskv.json
	$(GOWIN_PACK) -d $(FAMILY) -o $@ $<

instructions.mem: hello.bin
	xxd -e $< | cut -d' ' -f2-5 > $@

dump-obj: hello.o
	$(OBJDUMP) -d -M numeric -M no-aliases $<

dump-bin: hello.bin
	xxd $<

hello.bin: hello.o
	$(OBJCOPY) -O binary $< $@

hello.o: hello.s
	$(AS) $< -march=rv32i -mabi=ilp32 -o $@

clean:
	rm -f briskv.json pnrbriskv.json briskv.fs briskv hello.o hello.bin instructions.mem

.PHONY: test build flash clean
