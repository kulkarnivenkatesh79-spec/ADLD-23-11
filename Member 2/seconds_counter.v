// Member 2 : Seconds counter 0-59 with minute carry pulse
module seconds_counter(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick_1s,
    output reg  [5:0] sec_count,
    output reg        min_tick
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec_count <= 6'd0;
            min_tick  <= 1'b0;
        end else begin
            min_tick <= 1'b0;                 // default: no pulse
            if (tick_1s) begin
                if (sec_count == 6'd59) begin
                    sec_count <= 6'd0;
                    min_tick  <= 1'b1;        // one-cycle carry
                end else begin
                    sec_count <= sec_count + 6'd1;
                end
            end
        end
    end
endmodule
