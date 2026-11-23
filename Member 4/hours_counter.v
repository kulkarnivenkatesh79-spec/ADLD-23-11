// Member 4 : Hours counter 0-23
module hours_counter(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       hour_tick,
    output reg  [4:0] hour_count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            hour_count <= 5'd0;
        else if (hour_tick) begin
            if (hour_count == 5'd23)
                hour_count <= 5'd0;
            else
                hour_count <= hour_count + 5'd1;
        end
    end
endmodule
