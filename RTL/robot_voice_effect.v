module robot_voice_effect (
    input             clk,
    input             rst_n,
    input             audio_in_valid,
    input      [31:0] audio_in_data,
    input             enable,         // 1: Enable Robot Effect, 0: Bypass
    
    output reg        audio_out_valid,
    output reg [31:0] audio_out_data
);

    // Parameters
    parameter SAMPLE_RATE = 48000;
    parameter CARRIER_FREQ = 500;
    // Phase increment for 32-bit accumulator: (Freq * 2^32) / SampleRate
    // 500 * 4294967296 / 48000 = 44739242
    parameter PHASE_INC = 32'd44739242; 

    // Internal Signals
    reg [31:0] phase_acc;
    wire [7:0] lut_index;
    reg signed [7:0] sine_val;
    reg signed [39:0] mult_result; // 32-bit * 8-bit = 40-bit
    reg signed [31:0] wet_signal;
    reg signed [31:0] dry_signal;
    
    // Sine LUT (256 points, 8-bit signed)
    // Amplitude approx +/- 127
    always @(*) begin
        case(lut_index)
            8'd0: sine_val = 8'd0;
            8'd1: sine_val = 8'd3;
            8'd2: sine_val = 8'd6;
            8'd3: sine_val = 8'd9;
            8'd4: sine_val = 8'd12;
            8'd5: sine_val = 8'd15;
            8'd6: sine_val = 8'd18;
            8'd7: sine_val = 8'd21;
            8'd8: sine_val = 8'd24;
            8'd9: sine_val = 8'd28;
            8'd10: sine_val = 8'd31;
            8'd11: sine_val = 8'd34;
            8'd12: sine_val = 8'd37;
            8'd13: sine_val = 8'd40;
            8'd14: sine_val = 8'd43;
            8'd15: sine_val = 8'd46;
            8'd16: sine_val = 8'd48;
            8'd17: sine_val = 8'd51;
            8'd18: sine_val = 8'd54;
            8'd19: sine_val = 8'd57;
            8'd20: sine_val = 8'd60;
            8'd21: sine_val = 8'd63;
            8'd22: sine_val = 8'd65;
            8'd23: sine_val = 8'd68;
            8'd24: sine_val = 8'd71;
            8'd25: sine_val = 8'd73;
            8'd26: sine_val = 8'd76;
            8'd27: sine_val = 8'd78;
            8'd28: sine_val = 8'd81;
            8'd29: sine_val = 8'd83;
            8'd30: sine_val = 8'd85;
            8'd31: sine_val = 8'd88;
            8'd32: sine_val = 8'd90;
            8'd33: sine_val = 8'd92;
            8'd34: sine_val = 8'd94;
            8'd35: sine_val = 8'd96;
            8'd36: sine_val = 8'd98;
            8'd37: sine_val = 8'd100;
            8'd38: sine_val = 8'd102;
            8'd39: sine_val = 8'd104;
            8'd40: sine_val = 8'd106;
            8'd41: sine_val = 8'd107;
            8'd42: sine_val = 8'd109;
            8'd43: sine_val = 8'd110;
            8'd44: sine_val = 8'd112;
            8'd45: sine_val = 8'd113;
            8'd46: sine_val = 8'd115;
            8'd47: sine_val = 8'd116;
            8'd48: sine_val = 8'd117;
            8'd49: sine_val = 8'd118;
            8'd50: sine_val = 8'd119;
            8'd51: sine_val = 8'd120;
            8'd52: sine_val = 8'd121;
            8'd53: sine_val = 8'd122;
            8'd54: sine_val = 8'd123;
            8'd55: sine_val = 8'd124;
            8'd56: sine_val = 8'd124;
            8'd57: sine_val = 8'd125;
            8'd58: sine_val = 8'd125;
            8'd59: sine_val = 8'd126;
            8'd60: sine_val = 8'd126;
            8'd61: sine_val = 8'd126;
            8'd62: sine_val = 8'd127;
            8'd63: sine_val = 8'd127;
            8'd64: sine_val = 8'd127;
            8'd65: sine_val = 8'd127;
            8'd66: sine_val = 8'd127;
            8'd67: sine_val = 8'd126;
            8'd68: sine_val = 8'd126;
            8'd69: sine_val = 8'd126;
            8'd70: sine_val = 8'd125;
            8'd71: sine_val = 8'd125;
            8'd72: sine_val = 8'd124;
            8'd73: sine_val = 8'd124;
            8'd74: sine_val = 8'd123;
            8'd75: sine_val = 8'd122;
            8'd76: sine_val = 8'd121;
            8'd77: sine_val = 8'd120;
            8'd78: sine_val = 8'd119;
            8'd79: sine_val = 8'd118;
            8'd80: sine_val = 8'd117;
            8'd81: sine_val = 8'd116;
            8'd82: sine_val = 8'd115;
            8'd83: sine_val = 8'd113;
            8'd84: sine_val = 8'd112;
            8'd85: sine_val = 8'd110;
            8'd86: sine_val = 8'd109;
            8'd87: sine_val = 8'd107;
            8'd88: sine_val = 8'd106;
            8'd89: sine_val = 8'd104;
            8'd90: sine_val = 8'd102;
            8'd91: sine_val = 8'd100;
            8'd92: sine_val = 8'd98;
            8'd93: sine_val = 8'd96;
            8'd94: sine_val = 8'd94;
            8'd95: sine_val = 8'd92;
            8'd96: sine_val = 8'd90;
            8'd97: sine_val = 8'd88;
            8'd98: sine_val = 8'd85;
            8'd99: sine_val = 8'd83;
            8'd100: sine_val = 8'd81;
            8'd101: sine_val = 8'd78;
            8'd102: sine_val = 8'd76;
            8'd103: sine_val = 8'd73;
            8'd104: sine_val = 8'd71;
            8'd105: sine_val = 8'd68;
            8'd106: sine_val = 8'd65;
            8'd107: sine_val = 8'd63;
            8'd108: sine_val = 8'd60;
            8'd109: sine_val = 8'd57;
            8'd110: sine_val = 8'd54;
            8'd111: sine_val = 8'd51;
            8'd112: sine_val = 8'd48;
            8'd113: sine_val = 8'd46;
            8'd114: sine_val = 8'd43;
            8'd115: sine_val = 8'd40;
            8'd116: sine_val = 8'd37;
            8'd117: sine_val = 8'd34;
            8'd118: sine_val = 8'd31;
            8'd119: sine_val = 8'd28;
            8'd120: sine_val = 8'd24;
            8'd121: sine_val = 8'd21;
            8'd122: sine_val = 8'd18;
            8'd123: sine_val = 8'd15;
            8'd124: sine_val = 8'd12;
            8'd125: sine_val = 8'd9;
            8'd126: sine_val = 8'd6;
            8'd127: sine_val = 8'd3;
            // Symmetry for 128-255 (Negative half)
            default: sine_val = -sine_val_pos(lut_index - 8'd128);
        endcase
    end

    // Helper function for symmetry
    function signed [7:0] sine_val_pos;
        input [7:0] idx;
        begin
            case(idx)
                8'd0: sine_val_pos = 8'd0;
                8'd1: sine_val_pos = 8'd3;
                8'd2: sine_val_pos = 8'd6;
                8'd3: sine_val_pos = 8'd9;
                8'd4: sine_val_pos = 8'd12;
                8'd5: sine_val_pos = 8'd15;
                8'd6: sine_val_pos = 8'd18;
                8'd7: sine_val_pos = 8'd21;
                8'd8: sine_val_pos = 8'd24;
                8'd9: sine_val_pos = 8'd28;
                8'd10: sine_val_pos = 8'd31;
                8'd11: sine_val_pos = 8'd34;
                8'd12: sine_val_pos = 8'd37;
                8'd13: sine_val_pos = 8'd40;
                8'd14: sine_val_pos = 8'd43;
                8'd15: sine_val_pos = 8'd46;
                8'd16: sine_val_pos = 8'd48;
                8'd17: sine_val_pos = 8'd51;
                8'd18: sine_val_pos = 8'd54;
                8'd19: sine_val_pos = 8'd57;
                8'd20: sine_val_pos = 8'd60;
                8'd21: sine_val_pos = 8'd63;
                8'd22: sine_val_pos = 8'd65;
                8'd23: sine_val_pos = 8'd68;
                8'd24: sine_val_pos = 8'd71;
                8'd25: sine_val_pos = 8'd73;
                8'd26: sine_val_pos = 8'd76;
                8'd27: sine_val_pos = 8'd78;
                8'd28: sine_val_pos = 8'd81;
                8'd29: sine_val_pos = 8'd83;
                8'd30: sine_val_pos = 8'd85;
                8'd31: sine_val_pos = 8'd88;
                8'd32: sine_val_pos = 8'd90;
                8'd33: sine_val_pos = 8'd92;
                8'd34: sine_val_pos = 8'd94;
                8'd35: sine_val_pos = 8'd96;
                8'd36: sine_val_pos = 8'd98;
                8'd37: sine_val_pos = 8'd100;
                8'd38: sine_val_pos = 8'd102;
                8'd39: sine_val_pos = 8'd104;
                8'd40: sine_val_pos = 8'd106;
                8'd41: sine_val_pos = 8'd107;
                8'd42: sine_val_pos = 8'd109;
                8'd43: sine_val_pos = 8'd110;
                8'd44: sine_val_pos = 8'd112;
                8'd45: sine_val_pos = 8'd113;
                8'd46: sine_val_pos = 8'd115;
                8'd47: sine_val_pos = 8'd116;
                8'd48: sine_val_pos = 8'd117;
                8'd49: sine_val_pos = 8'd118;
                8'd50: sine_val_pos = 8'd119;
                8'd51: sine_val_pos = 8'd120;
                8'd52: sine_val_pos = 8'd121;
                8'd53: sine_val_pos = 8'd122;
                8'd54: sine_val_pos = 8'd123;
                8'd55: sine_val_pos = 8'd124;
                8'd56: sine_val_pos = 8'd124;
                8'd57: sine_val_pos = 8'd125;
                8'd58: sine_val_pos = 8'd125;
                8'd59: sine_val_pos = 8'd126;
                8'd60: sine_val_pos = 8'd126;
                8'd61: sine_val_pos = 8'd126;
                8'd62: sine_val_pos = 8'd127;
                8'd63: sine_val_pos = 8'd127;
                8'd64: sine_val_pos = 8'd127;
                8'd65: sine_val_pos = 8'd127;
                8'd66: sine_val_pos = 8'd127;
                8'd67: sine_val_pos = 8'd126;
                8'd68: sine_val_pos = 8'd126;
                8'd69: sine_val_pos = 8'd126;
                8'd70: sine_val_pos = 8'd125;
                8'd71: sine_val_pos = 8'd125;
                8'd72: sine_val_pos = 8'd124;
                8'd73: sine_val_pos = 8'd124;
                8'd74: sine_val_pos = 8'd123;
                8'd75: sine_val_pos = 8'd122;
                8'd76: sine_val_pos = 8'd121;
                8'd77: sine_val_pos = 8'd120;
                8'd78: sine_val_pos = 8'd119;
                8'd79: sine_val_pos = 8'd118;
                8'd80: sine_val_pos = 8'd117;
                8'd81: sine_val_pos = 8'd116;
                8'd82: sine_val_pos = 8'd115;
                8'd83: sine_val_pos = 8'd113;
                8'd84: sine_val_pos = 8'd112;
                8'd85: sine_val_pos = 8'd110;
                8'd86: sine_val_pos = 8'd109;
                8'd87: sine_val_pos = 8'd107;
                8'd88: sine_val_pos = 8'd106;
                8'd89: sine_val_pos = 8'd104;
                8'd90: sine_val_pos = 8'd102;
                8'd91: sine_val_pos = 8'd100;
                8'd92: sine_val_pos = 8'd98;
                8'd93: sine_val_pos = 8'd96;
                8'd94: sine_val_pos = 8'd94;
                8'd95: sine_val_pos = 8'd92;
                8'd96: sine_val_pos = 8'd90;
                8'd97: sine_val_pos = 8'd88;
                8'd98: sine_val_pos = 8'd85;
                8'd99: sine_val_pos = 8'd83;
                8'd100: sine_val_pos = 8'd81;
                8'd101: sine_val_pos = 8'd78;
                8'd102: sine_val_pos = 8'd76;
                8'd103: sine_val_pos = 8'd73;
                8'd104: sine_val_pos = 8'd71;
                8'd105: sine_val_pos = 8'd68;
                8'd106: sine_val_pos = 8'd65;
                8'd107: sine_val_pos = 8'd63;
                8'd108: sine_val_pos = 8'd60;
                8'd109: sine_val_pos = 8'd57;
                8'd110: sine_val_pos = 8'd54;
                8'd111: sine_val_pos = 8'd51;
                8'd112: sine_val_pos = 8'd48;
                8'd113: sine_val_pos = 8'd46;
                8'd114: sine_val_pos = 8'd43;
                8'd115: sine_val_pos = 8'd40;
                8'd116: sine_val_pos = 8'd37;
                8'd117: sine_val_pos = 8'd34;
                8'd118: sine_val_pos = 8'd31;
                8'd119: sine_val_pos = 8'd28;
                8'd120: sine_val_pos = 8'd24;
                8'd121: sine_val_pos = 8'd21;
                8'd122: sine_val_pos = 8'd18;
                8'd123: sine_val_pos = 8'd15;
                8'd124: sine_val_pos = 8'd12;
                8'd125: sine_val_pos = 8'd9;
                8'd126: sine_val_pos = 8'd6;
                8'd127: sine_val_pos = 8'd3;
                default: sine_val_pos = 8'd0;
            endcase
        end
    endfunction

    // DDS Logic
    assign lut_index = phase_acc[31:24]; // Use top 8 bits for LUT index

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'd0;
        end else if (audio_in_valid) begin
            // Only update phase when new sample arrives to match sample rate
            phase_acc <= phase_acc + PHASE_INC;
        end
    end

    // Ring Modulator Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            audio_out_data <= 32'd0;
            audio_out_valid <= 1'b0;
            mult_result <= 40'd0;
            wet_signal <= 32'd0;
            dry_signal <= 32'd0;
        end else if (audio_in_valid) begin
            if (!enable) begin
                // Bypass: Pass original audio
                audio_out_data <= audio_in_data;
            end else begin
                // Robot Effect: Mix Dry and Wet signals for intelligibility
                
                // 1. Calculate Wet Signal (Ring Modulated)
                // audio_in_data * sine_val
                mult_result = $signed(audio_in_data) * sine_val;
                
                // Normalize Wet signal (divide by ~128)
                wet_signal = $signed(mult_result >>> 7);
                
                // 2. Get Dry Signal
                dry_signal = $signed(audio_in_data);
                
                // 3. Mix: 75% Dry + 25% Wet
                // This preserves the speech content while adding the robotic texture
                // Dry * 0.75 = Dry - (Dry >> 2)
                // Wet * 0.25 = Wet >> 2
                
                audio_out_data <= (dry_signal - (dry_signal >>> 2)) + (wet_signal >>> 2);
            end
            audio_out_valid <= 1'b1;
        end else begin
            audio_out_valid <= 1'b0;
        end
    end

endmodule
