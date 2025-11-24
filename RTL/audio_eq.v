module audio_eq (
    input             clk,          // aud_bclk
    input             rst_n,
    input             lrc,          // Channel select
    input      [31:0] data_in,      // Input audio data
    input             data_valid,   // Input data valid pulse
    
    input             sw_treble_up,
    input             sw_treble_down,
    input             sw_bass_up,
    input             sw_bass_down,
    
    output reg [31:0] data_out,
    output reg        data_valid_out
);

    // State variables for filters (Left and Right)
    reg signed [23:0] lpf_l;
    reg signed [23:0] lpf_r;
    
    wire signed [23:0] sample_in;
    assign sample_in = data_in[23:0]; // Extract 24-bit sample
    
    reg signed [23:0] current_lpf;
    reg signed [23:0] bass_comp;
    reg signed [23:0] treble_comp;
    reg signed [23:0] sample_out_calc;
    
    // Gain factors (approximate)
    // Boost/Cut by adding/subtracting 0.5 * component
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lpf_l <= 24'd0;
            lpf_r <= 24'd0;
            data_out <= 32'd0;
            data_valid_out <= 1'b0;
        end else if (data_valid) begin
            // 1. Update LPF State
            // alpha = 1/16. y[n] = y[n-1] + (x[n] - y[n-1]) >>> 4
            // Cutoff approx 480Hz at 48kHz sample rate
            if (lrc) begin 
                current_lpf = lpf_l + ((sample_in - lpf_l) >>> 4);
                lpf_l <= current_lpf;
            end else begin
                current_lpf = lpf_r + ((sample_in - lpf_r) >>> 4);
                lpf_r <= current_lpf;
            end
            
            // 2. Calculate Components
            bass_comp = current_lpf;
            treble_comp = sample_in - current_lpf;
            
            // 3. Apply EQ
            sample_out_calc = sample_in;
            
            // Bass Control - Stronger effect (add full component)
            if (sw_bass_up)
                sample_out_calc = sample_out_calc + bass_comp; // +6dB to +9dB effective
            else if (sw_bass_down)
                sample_out_calc = sample_out_calc - bass_comp; // Cut bass
                
            // Treble Control - Stronger effect
            if (sw_treble_up)
                sample_out_calc = sample_out_calc + treble_comp; // Boost highs
            else if (sw_treble_down)
                sample_out_calc = sample_out_calc - treble_comp; // Cut highs
                
            // 4. Output with simple saturation
            if (sample_out_calc > 8388607) sample_out_calc = 8388607;
            else if (sample_out_calc < -8388608) sample_out_calc = -8388608;
            
            data_out <= {8'd0, sample_out_calc}; // Pad back to 32 bits
            data_valid_out <= 1'b1;
        end else begin
            data_valid_out <= 1'b0;
        end
    end

endmodule
