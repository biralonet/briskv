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

   reg [4:0]		 leds;
`ifdef BENCH
   assign LEDS = leds;
`else
   assign LEDS = ~leds;
`endif

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
   reg [31:0]		 mem [0:11];
   initial begin
      pc = 0;
      // NOP: add x0, x0, x0
      //                   rs2   rs1       rd
      instr = 32'b0000000_00000_00000_000_00000_0110011;
      //
      // add x1, x0, x0
      //                    rs2   rs1       rd
      mem[0] = 32'b0000000_00000_00000_000_00001_0110011;
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
      // add x2, x1, x0
      //                    rs2   rs1       rd
      mem[5] = 32'b0000000_00000_00001_000_00010_0110011;
      // add x3, x1, x2
      //                    rs2   rs1       rd
      mem[6] = 32'b0000000_00010_00001_000_00011_0110011;
      // srli x3, x3, 3
      //                   shamt  rs1       rd
      mem[7] = 32'b0000000_00011_00011_101_00011_0010011;
      // slli x3, x3, 31
      //                   shamt  rs1       rd
      mem[8] = 32'b0000000_11111_00011_001_00011_0010011;
      // srai x3, x3, 5
      //                   shamt  rs1       rd
      mem[9] = 32'b0100000_00101_00011_101_00011_0010011;
      // srli x1, x3, 26
      //                   shamt  rs1       rd
      mem[10] = 32'b0000000_11010_00011_101_00011_0010011;
      // ebreak
      mem[11] = 32'b00000000001_00000_000_00000_1110011;
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

   wire [2:0] funct3       = instr[14:12];
   wire [6:0] funct7       = instr[31:25];

   wire [31:0] i_imm = {{21{instr[31]}}, instr[30:20]};
   wire [31:0] s_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
   wire [31:0] b_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
   wire [31:0] u_imm = {instr[31], instr[30:12], {12{1'b0}}};
   wire [31:0] j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

   // Registers
   reg [31:0]		 regs[0:31];
   reg [31:0]		 rs1;
   reg [31:0]		 rs2;

`ifdef BENCH
   integer		 i;
   initial begin
      for (i = 0; i < 32; ++i) begin
	 regs[i] = 0;
      end
   end
`endif

   wire [31:0] alu_in1 = rs1;
   wire [31:0] alu_in2 = is_alu_reg ? rs2 : i_imm;
   wire [4:0]  shamt   = is_alu_reg ? rs2[4:0] : instr[24:20];
   reg [31:0]  alu_out;
   always @(*) begin
      case (funct3)
	3'b000: alu_out = (funct7[5] & instr[5]) ? (alu_in1 - alu_in2) : (alu_in1 + alu_in2);
	3'b001: alu_out = alu_in1 << shamt;
	3'b010: alu_out = $signed(alu_in1) < $signed(alu_in2);
	3'b011: alu_out = alu_in1 < alu_in2;
	3'b100: alu_out = alu_in1 ^ alu_in2;
	3'b101: alu_out = funct7[5] ? ($signed(alu_in1) >>> shamt) : ($signed(alu_in1) >> shamt);
	3'b110: alu_out = alu_in1 | alu_in2;
	3'b111: alu_out = alu_in1 & alu_in2;
      endcase
   end

   wire [31:0]		 write_back_data;
   wire			 write_back_en;
   assign write_back_data = alu_out;
   assign write_back_en = state == EXECUTE && (is_alu_reg || is_alu_imm);

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

	    if (rd_id == 1) begin
	       leds <= write_back_data;
	    end
`ifdef BENCH
	    $display("x%0d <= %b", rd_id, write_back_data);
`endif
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
   always @(posedge clk) begin
      if (state == FETCH_REGS) begin
	 case (1'b1)
	   is_lui:     $display("lui");
	   is_auipc:   $display("auipc");
	   is_jal:     $display("jal");
	   is_jalr:    $display("jalr");
	   is_branch:  $display("branch");
	   is_load:    $display("load");
	   is_store:   $display("store");
	   is_alu_imm: $display("alu_imm rd=%d rs1=%d imm=%0d funct3=%b", rd_id, rs1_id, i_imm, funct3);
	   is_alu_reg: $display("alu_reg rd=%d rs1=%d rs2=%d funct3=%b", rd_id, rs1_id, rs2_id, funct3);
	   is_fence:   $display("fence");
	   is_system:  $display("system");
	 endcase

	 if (is_system) begin
	    $finish();
	 end
      end
   end
`endif

   assign TXD = 1'b0;

endmodule
