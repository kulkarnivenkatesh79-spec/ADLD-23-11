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
// Member 3 : Minutes counter 0-59 with hour carry pulse
module minutes_counter(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       min_tick,
    output reg  [5:0] min_count,
    output reg        hour_tick
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            min_count <= 6'd0;
            hour_tick <= 1'b0;
        end else begin
            hour_tick <= 1'b0;
            if (min_tick) begin
                if (min_count == 6'd59) begin
                    min_count <= 6'd0;
                    hour_tick <= 1'b1;
                end else begin
                    min_count <= min_count + 6'd1;
                end
            end
        end
    end
endmodule
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
// Member 5 : Binary to BCD digit splitter
module display_ctrl(
    input  wire [4:0] hour_count,
    input  wire [5:0] min_count,
    input  wire [5:0] sec_count,
    output reg  [3:0] hour_tens,
    output reg  [3:0] hour_ones,
    output reg  [3:0] min_tens,
    output reg  [3:0] min_ones,
    output reg  [3:0] sec_tens,
    output reg  [3:0] sec_ones
);
    always @(*) begin
        hour_tens = hour_count / 10;
        hour_ones = hour_count % 10;
        min_tens  = min_count  / 10;
        min_ones  = min_count  % 10;
        sec_tens  = sec_count  / 10;
        sec_ones  = sec_count  % 10;
    end
endmodule
// Member 5 : Top-level integration
module digital_clock_top #(
    parameter integer CLK_FREQ_HZ = 50000000
)(
    input  wire       clk,
    input  wire       rst_n,
    output wire [3:0] hour_tens,
    output wire [3:0] hour_ones,
    output wire [3:0] min_tens,
    output wire [3:0] min_ones,
    output wire [3:0] sec_tens,
    output wire [3:0] sec_ones
);
    wire       tick_1s;
    wire       min_tick;
    wire       hour_tick;
    wire [5:0] sec_count;
    wire [5:0] min_count;
    wire [4:0] hour_count;

    tick_gen #(.CLK_FREQ_HZ(CLK_FREQ_HZ)) U_TICK_GEN (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s));

    seconds_counter U_SECONDS (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s),
        .sec_count(sec_count), .min_tick(min_tick));

    minutes_counter U_MINUTES (
        .clk(clk), .rst_n(rst_n), .min_tick(min_tick),
        .min_count(min_count), .hour_tick(hour_tick));

    hours_counter U_HOURS (
        .clk(clk), .rst_n(rst_n), .hour_tick(hour_tick),
        .hour_count(hour_count));

    display_ctrl U_DISPLAY (
        .hour_count(hour_count), .min_count(min_count), .sec_count(sec_count),
        .hour_tens(hour_tens), .hour_ones(hour_ones),
        .min_tens(min_tens),   .min_ones(min_ones),
        .sec_tens(sec_tens),   .sec_ones(sec_ones));
endmodule
