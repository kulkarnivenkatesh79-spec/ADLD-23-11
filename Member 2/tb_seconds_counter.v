`timescale 1ns/1ps
module tb_seconds_counter;
    reg clk = 0, rst_n = 0, tick_1s = 0;
    wire [5:0] sec_count;
    wire min_tick;
    integer errors = 0, i, exp_cnt = 0, exp_carry;
    integer carry_cycles = 0;

    seconds_counter dut (.clk(clk), .rst_n(rst_n), .tick_1s(tick_1s), .sec_count(sec_count), .min_tick(min_tick));

    always #5 clk = ~clk;

    // carry must never stay high two cycles in a row
    reg prev_c = 0;
    always @(posedge clk) begin
        if (min_tick && prev_c) begin $display("FAIL: min_tick wider than 1 cycle"); errors = errors + 1; end
        prev_c <= min_tick;
    end

    task do_tick;
        begin
            @(negedge clk) tick_1s = 1;
            @(negedge clk) tick_1s = 0;           // outputs from the tick are now visible
            exp_cnt   = (exp_cnt + 1) % 60;
            exp_carry = (exp_cnt == 0);
            if (sec_count !== exp_cnt) begin
                $display("FAIL: sec_count=%0d expected %0d", sec_count, exp_cnt); errors = errors + 1;
            end
            if (min_tick !== exp_carry[0]) begin
                $display("FAIL: min_tick=%b expected %b at count %0d", min_tick, exp_carry[0], exp_cnt); errors = errors + 1;
            end
            @(negedge clk);                  // carry must have dropped
            if (min_tick !== 1'b0) begin $display("FAIL: min_tick stuck high"); errors = errors + 1; end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0, tb_seconds_counter);
        #22; 
        if (sec_count !== 0 || min_tick !== 0) begin $display("FAIL: reset values"); errors = errors + 1; end
        rst_n = 1;
        // no tick -> no change
        repeat (5) @(negedge clk);
        if (sec_count !== 0) begin $display("FAIL: counted without enable"); errors = errors + 1; end
        // 2+ full wraps
        for (i = 0; i < 2*60 + 3; i = i + 1) do_tick;
        // async reset mid-count
        #2 rst_n = 0; #1;
        if (sec_count !== 0) begin $display("FAIL: async reset"); errors = errors + 1; end
        if (errors == 0) $display("PASS: tb_seconds_counter");
        else             $display("FAILED: tb_seconds_counter, %0d errors", errors);
        $finish;
    end
endmodule
