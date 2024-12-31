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

   // Setup memory and initial registers
   reg [31:0]		 instr;
   reg [31:0]		 pc;
   reg [31:0]		 mem [0:8];
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
      // ebreak
      mem[5] = 32'b00000000001_00000_000_00000_1110011;
   end

   // Decode instruction
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

   wire [4:0] rs1_id = instr[19:15];
   wire [4:0] rs2_id = instr[24:20];
   wire [4:0] rd_id  = instr[11:7];

   wire [2:0] alu_sel      = instr[14:12];
   wire	      alu_sel_2    = instr[30];
   wire [6:0] store_imm_up = instr[31:25];

   wire [31:0] i_imm = {{21{instr[31]}}, instr[30:20]};
   wire [31:0] s_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
   wire [31:0] b_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
   wire [31:0] u_imm = {instr[31], instr[30:12], {12{1'b0}}};
   wire [31:0] j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

   // Registers
   reg [31:0]		 regs[0:31];
   reg [31:0]		 rs1;
   reg [31:0]		 rs2;
   wire [31:0]		 write_back_data;
   wire			 write_back_en;
   assign write_back_data = 0;
   assign write_back_en = 0;

`ifdef BENCH
   integer		 i;
   initial begin
      for (i = 0; i < 32; ++i) begin
	 regs[i] = 0;
      end
   end
`endif

   localparam FETCH_INSTR = 0;
   localparam FETCH_REGS  = 1;
   localparam EXECUTE = 2;
   reg [1:0]  state = FETCH_INSTR;
   always @(posedge clk) begin
      if (reset) begin
	 pc <= 0;
	 state <= FETCH_INSTR;
	 instr <= 32'b0000000_00000_00000_000_00000_0110011;
      end else begin
	 if (write_back_en && rd_id != 0) begin
	    regs[rd_id] <= write_back_data;
	 end

	 case (state)
	   FETCH_INSTR: begin
	      instr <= mem[pc];
	      state <= FETCH_REGS;
	   end
	   FETCH_REGS: begin
	      rs1 <= regs[rs1_id];
	      rs2 <= regs[rs2_id];
	      state <= EXECUTE;
	   end
	   EXECUTE: begin
	      if (!is_system) begin
		 pc <= pc + 1;
	      end
	      state <= FETCH_INSTR;

`ifdef BENCH
	      if (is_system) $finish();
`endif
	   end
	 endcase
      end
   end

`ifdef BENCH
   assign LEDS = is_system ? 63 : (1 << state);
`else
   assign LEDS = is_system ? ~63 : ~(1 << state);
`endif


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
	is_alu_imm: $display("alu_imm rd_id=%d rs1_id=%d imm=%d alu_sel=%0d", rd_id, rs1_id, i_imm, alu_sel);
	is_alu_reg: $display("alu_reg rd_id=%d rs1_id=%d rs2_id=%d alu_sel=%b", rd_id, rs1_id, rs2_id, alu_sel);
	is_fence:   $display("fence");
	is_system:  $display("system");
      endcase // case (1'b1)
      $display("");
   end
`endif

   assign TXD = 1'b0;

endmodule
