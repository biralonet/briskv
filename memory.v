module Memory (
	       input		 clk,
	       input [31:0]	 mem_addr,
	       output reg [31:0] mem_rdata,
	       input		 mem_rstrb
	       );

   reg [31:0]			 mem [0:2];
   initial begin
      $readmemh("instructions.mem", mem);
   end

   always @(posedge clk) begin
      if (mem_rstrb) begin
	 mem_rdata <= mem[mem_addr[31:2]];
      end
   end

endmodule
