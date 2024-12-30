`include "clock.v"

module Briskv (
	    input	 CLK,
	    input	 RESET,
	    output [5:0] LEDS,
	    input	 RXD,
	    output	 TXD
);

   wire			 clk;
   wire			 reset;

   Clock #(
`ifdef BENCH
	   .BITS(18)
`else
	   .BITS(24)
`endif
   ) clock (
	    .CLK(CLK),
	    .RESET(RESET),
	    .clk(clk),
	    .reset(reset));

   reg [31:0]		 instr;
   reg [31:0]		 pc;
   reg [31:0]		 mem [0:10];
   initial begin
      pc = 0;
      // NOP: add x0, x0, x0
      //                   rs2   rs1       rd
      instr = 32'b0000000_00000_00000_000_00000_0110011;
      //
      // add x1, x0, x0
      //                    rs2   rs1       rd
      mem[0] = 32'b0000000_00000_00000_000_00000_0110011;
      // addi x1, x1, 1
      //           imm[11:0]    rs1       rd
      mem[1] = 32'b00000000001_00001_000_00001_0010011;
      // addi x1, x1, 1
      //           imm[11:0]   rs1       rd
      mem[2] = 32'b00000000001_00001_000_00001_0010011;
      // addi x1, x1, 1
      //           imm[11:0]    rs1       rd
      mem[3] = 32'b00000000001_00001_000_00001_0010011;
      // addi x1, x1, 1
      //           imm[11:0]    rs1       rd
      mem[4] = 32'b00000000001_00001_000_00001_0010011;
      // lw x2, 0(x1)
      //           imm[11:0]    rs1       rd
      mem[5] = 32'b00000000000_00001_010_00010_0000011;
      // sw x2, 0(x1)
      //        imm[11:5]  rs2   rs1    imm[4:0]
      mem[6] = 32'b000000_00010_00001_010_00000_0100011;
      // ebreak
      mem[7] = 32'b00000000001_00000_000_00000_1110011;
   end // initial begin

   wire is_lui     = (instr[6:0] == 7'b0110111);
   wire is_auipc   = (instr[6:0] == 7'b0010111);
   wire	is_jal     = (instr[6:0] == 7'b1101111);
   wire	is_jalr    = (instr[6:0] == 7'b1100111);
   wire	is_branch  = (instr[6:0] == 7'b1101111);
   wire is_load    = (instr[6:0] == 7'b0000011);
   wire is_store   = (instr[6:0] == 7'b0100011);
   wire is_alu_imm = (instr[6:0] == 7'b0010011);
   wire is_alu_reg = (instr[6:0] == 7'b0110011);
   wire is_fence   = (instr[6:0] == 7'b0001111);
   wire is_system  = (instr[6:0] == 7'b1110011);

   wire [4:0] rs1 = instr[19:15];
   wire [4:0] rs2 = instr[24:20];
   wire [4:0] rd  = instr[11:7];

   wire [2:0] alu_sel      = instr[14:12];
   wire	      alu_sel_2    = instr[30];
   wire [6:0] store_imm_up = instr[31:25];

   wire [31:0] i_imm = {{21{instr[31]}}, instr[30:20]};
   wire [31:0] s_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
   wire [31:0] b_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
   wire [31:0] u_imm = {instr[31], instr[30:12], {12{1'b0}}};
   wire [31:0] j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

   always @(posedge clk) begin
      if (reset) begin
	 pc <= 0;
	 // NOP: add x0, x0, x0
	 //                   rs2   rs1       rd
	 instr = 32'b0000000_00000_00000_000_00000_0110011;
      end else if (!is_system) begin
	 instr <= mem[pc];
	 pc <= pc + 1;
      end
`ifdef BENCH
      if (is_system) $finish();
`endif
   end

`ifdef BENCH
   assign LEDS = (is_system) ? 63 : {pc[0], is_alu_reg, is_alu_imm, is_store, is_load};
`else
   assign LEDS = ~((is_system) ? 63 : {pc[0], is_alu_reg, is_alu_imm, is_store, is_load});
`endif
   assign TXD = 1'b0;

`ifdef BENCH
   always @(posedge clk) begin
      $display("pc=%0d", pc);
      case (1'b1)
	is_lui:     $display("lui");
	is_auipc:   $display("auipc");
	is_jal:     $display("jal");
	is_jalr:    $display("jalr");
	is_branch:  $display("branch");
	is_load:    $display("load");
	is_store:   $display("store");
	is_alu_imm: $display("alu_imm rd=%d rs1=%d rs2=%d imm=%0d", rd, rs1, i_imm, alu_sel);
	is_alu_reg: $display("alu_reg rd=%d rs1=%d rs2=%d alu_sel=%b", rd, rs1, rs2, alu_sel);
	is_fence:   $display("fence");
	is_system:  $display("system");
      endcase // case (1'b1)
      $display("");
   end
`endif

endmodule
