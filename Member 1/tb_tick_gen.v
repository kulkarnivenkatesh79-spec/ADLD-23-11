`timescale 1ns/1ps
module tb_tick_gen;
    localparam integer N = 10;            // reduced "1 second" = 10 clocks
    reg clk = 0, rst_n = 0;
    wire tick_1s;
    integer errors = 0, cycles = 0, pulses = 0;
    reg prev = 0;

    tick_gen #(.CLK_FREQ_HZ(N)) dut (.clk(clk), .rst_n(rst_n), .tick_1s(tick_1s));

    always #5 clk = ~clk;

    // Monitor: pulse width and spacing
    always @(posedge clk) if (rst_n) begin
        cycles <= cycles + 1;
        if (tick_1s && prev) begin
            $display("FAIL: tick_1s wider than one cycle @%0t", $time); errors = errors + 1;
        end
        if (tick_1s) pulses <= pulses + 1;
        prev <= tick_1s;
    end

    integer last = 0, idx = 0;
    always @(posedge clk) if (rst_n && tick_1s) begin
        if (pulses > 0 && (idx - last) != N) begin
            $display("FAIL: pulse spacing %0d != %0d", idx - last, N); errors = errors + 1;
        end
        last = idx;
    end
    always @(posedge clk) if (rst_n) idx = idx + 1;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0, tb_tick_gen);
        #22 rst_n = 1;
        #(10*N*5);                          // ~5 pulses
        if (pulses < 4) begin $display("FAIL: too few pulses (%0d)", pulses); errors = errors + 1; end
        // async reset mid-run
        #3 rst_n = 0; #1;
        if (tick_1s !== 0) begin $display("FAIL: reset did not clear tick"); errors = errors + 1; end
        #20 rst_n = 1;
        if (errors == 0) $display("PASS: tb_tick_gen");
        else             $display("FAILED: tb_tick_gen, %0d errors", errors);
        $finish;
    end
endmodule
