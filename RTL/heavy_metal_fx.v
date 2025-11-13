//----------------------------------------------------------------------------------
// Module Name: heavy_metal_fx
// Description: Adds a saturated "heavy metal" character using hard clipping,
//              softening, and edge emphasis on each incoming sample.
//----------------------------------------------------------------------------------
module heavy_metal_fx #(
    parameter integer DATA_WIDTH = 32,
    parameter integer PRE_GAIN_SHIFT = 2,
    parameter integer PRESENCE_SHIFT = 1,
    parameter integer SAT_REDUCTION_SHIFT = 3
)(
    input                             clk,
    input                             rst_n,
    input                             enable,
    input                             sample_strobe,
    input      signed [DATA_WIDTH-1:0] sample_in,
    output reg signed [DATA_WIDTH-1:0] sample_out
);

localparam signed [DATA_WIDTH-1:0] SAMPLE_MAX = {1'b0, {(DATA_WIDTH-1){1'b1}}};
localparam signed [DATA_WIDTH-1:0] SAMPLE_MIN = {1'b1, {(DATA_WIDTH-1){1'b0}}};
localparam signed [DATA_WIDTH   :0] SAMPLE_MAX_EXT = {1'b0, SAMPLE_MAX};
localparam signed [DATA_WIDTH   :0] SAMPLE_MIN_EXT = {1'b1, SAMPLE_MIN};

reg signed [DATA_WIDTH-1:0] prev_sample;
reg signed [DATA_WIDTH+PRE_GAIN_SHIFT-1:0] pre_gain;
reg signed [DATA_WIDTH-1:0] clipped;
reg signed [DATA_WIDTH-1:0] abs_val;
reg signed [DATA_WIDTH-1:0] abs_scaled;
reg signed [DATA_WIDTH-1:0] folded;
reg signed [DATA_WIDTH   :0] edge;
reg signed [DATA_WIDTH   :0] edge_boost;
reg signed [DATA_WIDTH   :0] folded_ext;
reg signed [DATA_WIDTH   :0] combined;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_sample <= {DATA_WIDTH{1'b0}};
        sample_out  <= {DATA_WIDTH{1'b0}};
    end else if (sample_strobe) begin
        if (enable) begin
            pre_gain = sample_in <<< PRE_GAIN_SHIFT;

            if (pre_gain > {{PRE_GAIN_SHIFT{1'b0}}, SAMPLE_MAX}) begin
                clipped = SAMPLE_MAX;
            end else if (pre_gain < {{PRE_GAIN_SHIFT{1'b1}}, SAMPLE_MIN}) begin
                clipped = SAMPLE_MIN;
            end else begin
                clipped = pre_gain[DATA_WIDTH-1:0];
            end

            if (clipped[DATA_WIDTH-1]) begin
                if (clipped == SAMPLE_MIN) begin
                    abs_val = SAMPLE_MAX;
                end else begin
                    abs_val = -clipped;
                end
            end else begin
                abs_val = clipped;
            end

            abs_scaled = abs_val >>> SAT_REDUCTION_SHIFT;

            if (clipped[DATA_WIDTH-1]) begin
                folded = clipped + abs_scaled;
            end else begin
                folded = clipped - abs_scaled;
            end

            edge = folded - prev_sample;
            edge_boost = edge <<< PRESENCE_SHIFT;

            folded_ext = {folded[DATA_WIDTH-1], folded};
            combined = folded_ext + edge_boost;

            if (combined > SAMPLE_MAX_EXT) begin
                sample_out <= SAMPLE_MAX;
            end else if (combined < SAMPLE_MIN_EXT) begin
                sample_out <= SAMPLE_MIN;
            end else begin
                sample_out <= combined[DATA_WIDTH-1:0];
            end

            prev_sample <= folded;
        end else begin
            sample_out <= sample_in;
            prev_sample <= sample_in;
        end
    end
end

endmodule
