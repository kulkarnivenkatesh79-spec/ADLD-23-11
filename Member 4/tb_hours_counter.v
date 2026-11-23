`timescale 1ns/1ps
module tb_hours_counter;
    reg clk = 0, rst_n = 0, hour_tick = 0;
    wire [4:0] hour_count;
    integer errors = 0, i, exp_cnt = 0;

    hours_counter dut (.clk(clk), .rst_n(rst_n), .hour_tick(hour_tick), .hour_count(hour_count));
    always #5 clk = ~clk;

    always @(posedge clk) if (hour_count > 23) begin
        $display("FAIL: hour_count exceeded 23 (%0d)", hour_count); errors = errors + 1;
    end

    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0, tb_hours_counter);
        #22;
        if (hour_count !== 0) begin $display("FAIL: reset value"); errors = errors + 1; end
        rst_n = 1;
        repeat (4) @(negedge clk);
        if (hour_count !== 0) begin $display("FAIL: counted without enable"); errors = errors + 1; end
        for (i = 0; i < 2*24 + 3; i = i + 1) begin
            @(negedge clk) hour_tick = 1;
            @(negedge clk) hour_tick = 0;
            exp_cnt = (exp_cnt + 1) % 24;
            if (hour_count !== exp_cnt) begin
                $display("FAIL: hour_count=%0d expected %0d", hour_count, exp_cnt); errors = errors + 1;
            end
        end
        #2 rst_n = 0; #1;
        if (hour_count !== 0) begin $display("FAIL: async reset"); errors = errors + 1; end
        if (errors == 0) $display("PASS: tb_hours_counter");
        else             $display("FAILED: tb_hours_counter, %0d errors", errors);
        $finish;
    end
endmodule
