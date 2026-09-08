module decoder #(parameter WIDTH = 4) (
   input wire        clk,
   input wire        enable,
   input  wire [$clog2(WIDTH)-1:0] sel,
   output reg  [WIDTH-1:0] out
);

   always @(posedge clk) begin
//        out = (1'b1 << sel);
       if (enable)
           out <= (1'b1 << sel);
       else
           out <= {WIDTH{1'b0}};
   end

endmodule
