`timescale 1ns/1ps
module tb_minutes_counter;
    reg clk = 0, rst_n = 0, min_tick = 0;
    wire [5:0] min_count;
    wire hour_tick;
    integer errors = 0, i, exp_cnt = 0, exp_carry;
    integer carry_cycles = 0;

    minutes_counter dut (.clk(clk), .rst_n(rst_n), .min_tick(min_tick), .min_count(min_count), .hour_tick(hour_tick));

    always #5 clk = ~clk;

    // carry must never stay high two cycles in a row
    reg prev_c = 0;
    always @(posedge clk) begin
        if (hour_tick && prev_c) begin $display("FAIL: hour_tick wider than 1 cycle"); errors = errors + 1; end
        prev_c <= hour_tick;
    end

    task do_tick;
        begin
            @(negedge clk) min_tick = 1;
            @(negedge clk) min_tick = 0;           // outputs from the tick are now visible
            exp_cnt   = (exp_cnt + 1) % 60;
            exp_carry = (exp_cnt == 0);
            if (min_count !== exp_cnt) begin
                $display("FAIL: min_count=%0d expected %0d", min_count, exp_cnt); errors = errors + 1;
            end
            if (hour_tick !== exp_carry[0]) begin
                $display("FAIL: hour_tick=%b expected %b at count %0d", hour_tick, exp_carry[0], exp_cnt); errors = errors + 1;
            end
            @(negedge clk);                  // carry must have dropped
            if (hour_tick !== 1'b0) begin $display("FAIL: hour_tick stuck high"); errors = errors + 1; end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0, tb_minutes_counter);
        #22; 
        if (min_count !== 0 || hour_tick !== 0) begin $display("FAIL: reset values"); errors = errors + 1; end
        rst_n = 1;
        // no tick -> no change
        repeat (5) @(negedge clk);
        if (min_count !== 0) begin $display("FAIL: counted without enable"); errors = errors + 1; end
        // 2+ full wraps
        for (i = 0; i < 2*60 + 3; i = i + 1) do_tick;
        // async reset mid-count
        #2 rst_n = 0; #1;
        if (min_count !== 0) begin $display("FAIL: async reset"); errors = errors + 1; end
        if (errors == 0) $display("PASS: tb_minutes_counter");
        else             $display("FAILED: tb_minutes_counter, %0d errors", errors);
        $finish;
    end
endmodule
