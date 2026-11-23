// Member 1 : One-second enable pulse generator
module tick_gen #(
    parameter integer CLK_FREQ_HZ = 50000000
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick_1s
);
    localparam integer MAX_COUNT = CLK_FREQ_HZ - 1;
    reg [31:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 32'd0;
            tick_1s <= 1'b0;
        end else if (cnt == MAX_COUNT) begin
            cnt     <= 32'd0;
            tick_1s <= 1'b1;   // one-cycle pulse
        end else begin
            cnt     <= cnt + 32'd1;
            tick_1s <= 1'b0;
        end
    end
endmodule
