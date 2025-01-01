module Processor (
	    input	      clk,
	    input	      reset,
	    output [31:0]     mem_addr,
	    input [31:0]      mem_rdata,
	    output	      mem_rstrb,
	    output reg [31:0] x1	 
);
   reg [31:0]		      pc = 0;
   reg [31:0]		      instr;

   // Decode instruction
   wire is_lui     = (instr[6:0] == 7'b0110111);
   wire is_auipc   = (instr[6:0] == 7'b0010111);
   wire	is_jal     = (instr[6:0] == 7'b1101111);
   wire	is_jalr    = (instr[6:0] == 7'b1100111);
   wire	is_branch  = (instr[6:0] == 7'b1100011);
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
	3'b000: alu_out = (funct7[5] & instr[5]) ?
			  (alu_in1 - alu_in2) :
			  (alu_in1 + alu_in2);
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
   assign write_back_data = (is_jal || is_jalr) ? pc + 4
			    : is_lui            ? u_imm
			    : is_auipc          ? pc + u_imm
			    : alu_out;
   assign write_back_en = state == EXECUTE && (is_alu_reg ||
					       is_alu_imm ||
					       is_jal     ||
					       is_jalr    ||
					       is_lui     ||
					       is_auipc);

   reg			 take_branch;
   always @(*) begin
      case (funct3)
	3'b000: take_branch = rs1 == rs2;
	3'b001: take_branch = rs1 != rs2;
	3'b100: take_branch = $signed(rs1) < $signed(rs2);
	3'b101: take_branch = $signed(rs1) >= $signed(rs2);
	3'b110: take_branch = rs1 < rs2;
	3'b111: take_branch = rs1 >= rs2;
	default: take_branch = 1'b0;
      endcase
   end

   localparam FETCH_INSTR = 0;
   localparam WAIT_INSTR = 1;
   localparam FETCH_REGS  = 2;
   localparam EXECUTE = 3;
   reg [1:0]  state = FETCH_INSTR;
   wire [31:0] next_pc =
	       (is_branch && take_branch) ? pc + b_imm
	       : is_jal                   ? pc + j_imm
	       : is_jalr                  ? rs1 + i_imm
	       : pc + 4;
   always @(posedge clk) begin
      if (reset) begin
	 pc <= 0;
	 state <= FETCH_INSTR;
      end else begin
	 if (write_back_en && rd_id != 0) begin
	    regs[rd_id] <= write_back_data;
	    if (rd_id == 1) begin
	       x1 <= write_back_data;
	    end
`ifdef BENCH
	    $display("x%0d <= %b", rd_id, write_back_data);
`endif
	 end

	 case (state)
	   FETCH_INSTR: begin
	      state <= WAIT_INSTR;
	   end
	   WAIT_INSTR: begin
	      instr <= mem_rdata;
	      state <= FETCH_REGS;
	   end
	   FETCH_REGS: begin
	      rs1 <= regs[rs1_id];
	      rs2 <= regs[rs2_id];
	      state <= EXECUTE;
	   end
	   EXECUTE: begin
	      if (!is_system) begin
		 pc <= next_pc;
	      end
	      state <= FETCH_INSTR;

`ifdef BENCH
	      if (is_system) $finish();
`endif
	   end
	 endcase
      end
   end

   assign mem_addr = pc;
   assign mem_rstrb = state == FETCH_INSTR;

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

endmodule
