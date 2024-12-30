module Test();
   reg CLK;
   wire	RESET = 0;
   wire [5:0] LEDS;
   reg	      RXD = 1'b0;
   wire	      TXD;

   Briskv briskv(
	    .CLK(CLK),
	    .RESET(RESET),
	    .LEDS(LEDS),
	    .RXD(RXD),
	    .TXD(TXD));

   reg [6:0]  prev_LEDS = 0;
   initial begin
      CLK = 0;
      forever begin
	 #1 CLK = ~CLK;
	 if (LEDS != prev_LEDS) begin
	    $display("LEDS = %b", ~LEDS);
	 end
	 prev_LEDS = LEDS;
      end
   end
endmodule
