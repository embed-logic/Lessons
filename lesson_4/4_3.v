module counter4 (
    input  wire       clk,
    input  wire       reset,
    output reg [3:0]  led
);

    always @(posedge clk) begin
        if (reset)
            led <= 4'b0000;
        else
            led <= led + 1'b1;
    end

endmodule
