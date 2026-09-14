module counter (
    input  wire       clk,
    input  wire       rst,
    input  wire       load,
    input  wire [3:0] data_in,
    input  wire       en,
    input  wire       up_down,
    output reg  [3:0] count
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= 4'b0000;
        else if (load)
            count <= data_in;
        else if (en) begin
            if (up_down)
                count <= count + 1'b1;
            else
                count <= count - 1'b1;
        end
    end

endmodule
