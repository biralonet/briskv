module Clock (
	      input  CLK,
	      input RESET,
	      output clk,
	      output reset
);

   parameter	     BITS = 0;
   reg [BITS:0]	     counter = 0;
   
   always @(posedge CLK) begin
      counter <= counter + 1;
   end

   assign clk = counter[BITS];
   assign reset = RESET;
endmodule
