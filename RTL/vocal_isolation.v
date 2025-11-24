module vocal_isolation (
    input             clk,
    input             rst_n,
    input             lrc,
    input      [31:0] data_in,
    input             data_valid,
    input             enable,
    
    output reg [31:0] data_out,
    output reg        data_valid_out
);

    // State variables for filters (Left and Right)
    // We use two LPFs to create a Bandpass:
    // BP = LPF_HighCutoff - LPF_LowCutoff
    // LPF_HighCutoff: ~3.4kHz (alpha ~ 0.5)
    // LPF_LowCutoff: ~300Hz (alpha ~ 1/32)
    
    reg signed [23:0] lpf_high_l, lpf_high_r;
    reg signed [23:0] lpf_low_l, lpf_low_r;
    
    wire signed [23:0] sample_in;
    assign sample_in = data_in[23:0];
    
    reg signed [23:0] next_lpf_high;
    reg signed [23:0] next_lpf_low;
    reg signed [23:0] bandpass_out;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lpf_high_l <= 24'd0; lpf_high_r <= 24'd0;
            lpf_low_l <= 24'd0; lpf_low_r <= 24'd0;
            data_out <= 32'd0;
            data_valid_out <= 1'b0;
        end else if (data_valid) begin
            if (enable) begin
                if (lrc) begin
                    // Left Channel
                    // LPF High Cutoff (3.4kHz): alpha = 1/2
                    next_lpf_high = lpf_high_l + ((sample_in - lpf_high_l) >>> 1);
                    lpf_high_l <= next_lpf_high;
                    
                    // LPF Low Cutoff (300Hz): alpha = 1/32
                    next_lpf_low = lpf_low_l + ((sample_in - lpf_low_l) >>> 5);
                    lpf_low_l <= next_lpf_low;
                end else begin
                    // Right Channel
                    next_lpf_high = lpf_high_r + ((sample_in - lpf_high_r) >>> 1);
                    lpf_high_r <= next_lpf_high;
                    
                    next_lpf_low = lpf_low_r + ((sample_in - lpf_low_r) >>> 5);
                    lpf_low_r <= next_lpf_low;
                end
                
                // Bandpass = HighCutoff - LowCutoff
                // This keeps frequencies BETWEEN LowCutoff and HighCutoff
                bandpass_out = next_lpf_high - next_lpf_low;
                
                data_out <= {8'd0, bandpass_out};
            end else begin
                // Bypass
                data_out <= data_in;
            end
            data_valid_out <= 1'b1;
        end else begin
            data_valid_out <= 1'b0;
        end
    end

endmodule
