YOSYS = yowasp-yosys
NEXTPNR = nextpnr-himbaechel
GOWIN_PACK = gowin_pack

OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump
AS = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld

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

briskv: test.v briskv.v soc.v memory.v processor.v clock.v instructions.mem
	iverilog -DBENCH -DBOARD_FREQ=10 test.v briskv.v -o briskv

briskv.json: briskv.v soc.v memory.v processor.v clock.v instructions.mem
	$(YOSYS) -p "read_verilog $<; synth_gowin -top $(TOP_MODULE) -json $@"

pnrbriskv.json: briskv.json $(CONSTRAINT_FILE)
	$(NEXTPNR) --json $< --write $@ --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CONSTRAINT_FILE)

briskv.fs: pnrbriskv.json
	$(GOWIN_PACK) -d $(FAMILY) -o $@ $<

instructions.mem: hello.bin
	xxd -e $< | cut -d' ' -f2-5 > $@

dump-elf: hello
	$(OBJDUMP) -x -d -M numeric -M no-aliases $<

dump-obj: hello.o
	$(OBJDUMP) -x -d -M numeric -M no-aliases $<

dump-bin: hello.bin
	xxd $<

dump-bin-dis: hello.bin
	riscv64-unknown-elf-objdump -D -b binary -m riscv:rv32i -M numeric -M no-aliases $<

hello.bin: hello
	$(OBJCOPY) -O binary $< $@

hello: hello.o
	$(LD) -T linker.ld -m elf32lriscv -nostdlib hello.o -o hello

hello.o: hello.s
	$(AS) $< -march=rv32i -mabi=ilp32 -o $@

clean:
	rm -f briskv.json pnrbriskv.json briskv.fs briskv hello.o hello hello.bin instructions.mem

.PHONY: test build flash clean
