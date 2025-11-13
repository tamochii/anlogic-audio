//----------------------------------------------------------------------------------
// Module Name: fir_filter
// Description: A simple parameterized FIR filter
//----------------------------------------------------------------------------------
module fir_filter #(
    parameter DATA_WIDTH = 16,      // Input/Output data width
    parameter TAPS_N = 16           // Number of filter taps (order + 1)
)(
    input clk,
    input rst_n,
    input signed [DATA_WIDTH-1:0] data_in,
    output reg signed [DATA_WIDTH-1:0] data_out
);

// Internal registers
reg signed [DATA_WIDTH-1:0] shift_reg [0:TAPS_N-1];
reg signed [DATA_WIDTH-1:0] coeff [0:TAPS_N-1];
wire signed [DATA_WIDTH*2-1:0] product [0:TAPS_N-1];
wire signed [DATA_WIDTH*2+3:0] sum [0:TAPS_N-1];

integer i;

// Initialize coefficients (16-tap averaging filter for strong low-pass effect)
initial begin
    coeff[0] = 16'd16;
    coeff[1] = 16'd16;
    coeff[2] = 16'd16;
    coeff[3] = 16'd16;
    coeff[4] = 16'd16;
    coeff[5] = 16'd16;
    coeff[6] = 16'd16;
    coeff[7] = 16'd16;
    coeff[8] = 16'd16;
    coeff[9] = 16'd16;
    coeff[10] = 16'd16;
    coeff[11] = 16'd16;
    coeff[12] = 16'd16;
    coeff[13] = 16'd16;
    coeff[14] = 16'd16;
    coeff[15] = 16'd16;
end

// Shift register for input data
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < TAPS_N; i = i + 1) begin
            shift_reg[i] <= 0;
        end
    end else begin
        shift_reg[0] <= data_in;
        for (i = 1; i < TAPS_N; i = i + 1) begin
            shift_reg[i] <= shift_reg[i-1];
        end
    end
end

// Multiply stage (combinational)
genvar j;
generate
    for (j = 0; j < TAPS_N; j = j + 1) begin : multiply_stage
        assign product[j] = shift_reg[j] * coeff[j];
    end
endgenerate

// Add stage (combinational)
assign sum[0] = product[0];
genvar k;
generate
    for (k = 1; k < TAPS_N; k = k + 1) begin : add_stage
        assign sum[k] = sum[k-1] + product[k];
    end
endgenerate

// Output register with scaling (assuming coefficients sum up to 256 for this example)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 0;
    end else begin
        // The result is scaled down to fit the output width.
        // The shift amount depends on the sum of coefficients.
        // For this example (8 * 32 = 256), we shift right by 8.
        data_out <= sum[TAPS_N-1] >>> 8;
    end
end

endmodule
