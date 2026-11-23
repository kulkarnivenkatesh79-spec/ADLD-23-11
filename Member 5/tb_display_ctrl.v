`timescale 1ns/1ps
module tb_display_ctrl;
    reg  [4:0] h = 0; reg [5:0] m = 0, s = 0;
    wire [3:0] ht, ho, mt, mo, st, so;
    integer errors = 0, i;

    display_ctrl dut (.hour_count(h), .min_count(m), .sec_count(s),
        .hour_tens(ht), .hour_ones(ho), .min_tens(mt), .min_ones(mo),
        .sec_tens(st), .sec_ones(so));

    task check(input integer eh, em, es);
        begin
            #1;
            if (ht !== eh/10 || ho !== eh%10 || mt !== em/10 || mo !== em%10 ||
                st !== es/10 || so !== es%10) begin
                $display("FAIL: %0d:%0d:%0d -> %0d%0d:%0d%0d:%0d%0d", eh, em, es, ht, ho, mt, mo, st, so);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        h = 14; m = 35; s = 48; check(14, 35, 48);           // example from spec
        if (!(ht==1 && ho==4 && mt==3 && mo==5 && st==4 && so==8)) begin
            $display("FAIL: spec example"); errors = errors + 1; end
        for (i = 0; i < 60; i = i + 1) begin
            m = i; s = 59 - i; h = i % 24;
            check(i % 24, i, 59 - i);
        end
        h = 23; m = 59; s = 59; check(23, 59, 59);
        h = 0;  m = 0;  s = 0;  check(0, 0, 0);
        if (errors == 0) $display("PASS: tb_display_ctrl");
        else             $display("FAILED: tb_display_ctrl, %0d errors", errors);
        $finish;
    end
endmodule
