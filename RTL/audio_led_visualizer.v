module audio_led_visualizer (
    input             sys_clk,
    input             rst_n,
    input      [31:0] audio_in,      // 24-bit signed (padded to 32)
    input             enable_sw,     // A9
    
    output reg [7:0]  led_out
);

    // Parameters
    parameter DECAY_RATE = 2000; // Adjust for decay speed

    // Signals
    reg [23:0] abs_audio;
    reg [23:0] current_level;
    reg [15:0] decay_counter;
    
    // Animation Signals
    reg [23:0] anim_cnt;
    reg [2:0]  anim_pos;
    reg        anim_dir; // 0: Up (0->7), 1: Down (7->0)
    
    // Animation Logic (Bouncing Ball)
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            anim_cnt <= 24'd0;
            anim_pos <= 3'd0;
            anim_dir <= 1'b0;
        end else if (!enable_sw) begin
            // Speed control: ~80ms per step (50MHz clock)
            if (anim_cnt >= 24'd4000000) begin 
                anim_cnt <= 24'd0;
                if (anim_dir == 1'b0) begin // Moving Up
                    if (anim_pos == 3'd7) begin
                        anim_dir <= 1'b1;
                        anim_pos <= 3'd6;
                    end else begin
                        anim_pos <= anim_pos + 1'b1;
                    end
                end else begin // Moving Down
                    if (anim_pos == 3'd0) begin
                        anim_dir <= 1'b0;
                        anim_pos <= 3'd1;
                    end else begin
                        anim_pos <= anim_pos - 1'b1;
                    end
                end
            end else begin
                anim_cnt <= anim_cnt + 1'b1;
            end
        end else begin
            // Reset animation when visualizer is active
            anim_cnt <= 24'd0;
            anim_pos <= 3'd0;
            anim_dir <= 1'b0;
        end
    end
    
    // 1. Absolute Value Calculation
    // audio_in comes from audio_eq, which outputs {8'd0, signed_24bit}.
    // So the data is in [23:0], and bit 23 is the sign bit.
    // We must NOT look at bit 31, because it is always 0 (padded).
    always @(*) begin
        if (audio_in[23] == 1'b1) // Negative (24-bit signed)
            abs_audio = ~audio_in[23:0] + 1'b1;
        else
            abs_audio = audio_in[23:0];
    end

    // 2. Peak Hold & Decay
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            current_level <= 24'd0;
            decay_counter <= 16'd0;
        end else begin
            if (enable_sw) begin
                if (abs_audio > current_level) begin
                    // Attack: Immediate update
                    current_level <= abs_audio;
                    decay_counter <= 16'd0;
                end else begin
                    // Decay: Slow decrement
                    if (decay_counter >= DECAY_RATE) begin
                        if (current_level > 24'd0)
                            current_level <= current_level - (current_level >> 8) - 24'd100; // Exponential-ish decay
                        decay_counter <= 16'd0;
                    end else begin
                        decay_counter <= decay_counter + 1'b1;
                    end
                end
            end else begin
                current_level <= 24'd0;
            end
        end
    end

    // 3. LED Mapping (Thermometer Scale)
    // Max amplitude is 2^23 = 8,388,608.
    // We use a logarithmic-like scale to make it responsive to low volume.
    always @(*) begin
        if (!enable_sw) begin
            // Standby Animation: Single LED moving back and forth
            led_out = 8'd1 << anim_pos;
        end else begin
            if (current_level > 24'd6000000)      led_out = 8'b11111111; // Peak
            else if (current_level > 24'd4000000) led_out = 8'b01111111;
            else if (current_level > 24'd2000000) led_out = 8'b00111111;
            else if (current_level > 24'd1000000) led_out = 8'b00011111;
            else if (current_level > 24'd500000)  led_out = 8'b00001111;
            else if (current_level > 24'd200000)  led_out = 8'b00000111;
            else if (current_level > 24'd50000)   led_out = 8'b00000011;
            else if (current_level > 24'd10000)   led_out = 8'b00000001; // Very sensitive low threshold
            else led_out = 8'b00000000;
        end
    end

endmodule
