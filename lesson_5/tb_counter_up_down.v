timescale 1ns / 1ps

module tb_counter;

    reg       clk;
    reg       rst;
    reg       load;
    reg [3:0] data_in;
    reg       en;
    reg       up_down;

    wire [3:0] count;

    counter dut (
        .clk      (clk),
        .rst      (rst),
        .load     (load),
        .data_in  (data_in),
        .en       (en),
        .up_down  (up_down),
        .count    (count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst     = 1'b1;
        load    = 1'b0;
        data_in = 4'b1000;
        en      = 1'b0;
        up_down = 1'b0;

        #12;
        rst = 1'b0;

        #2
        load    = 1'b1;
        data_in = 4'd10;
           @(posedge clk);
        #1;
        
        if (count === 4'd10)
            $display("PASS: LOAD, count = %d", count);
        else
            $display("FAIL: LOAD, count = %d, expected = 10", count);
    
        load = 1'b0;
        #7;
        load    = 1'b1;
        data_in = 4'd11;
           @(posedge clk); 
        #1;   
        load = 1'b0;
        
        #10;
        rst = 1'b1;
        #1;
        rst = 1'b0;
        #15;        
        en      = 1'b1;
                 
         
    #180;
         up_down = 1'b1;
    #140;
    
        en    = 1'b0;
     #20;   
        
        $finish; 
    end
endmodule 
