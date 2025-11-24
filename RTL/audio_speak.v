module audio_speak(
    input           sys_clk   ,               // ϵͳʱ(50MHz)
    input           sys_rst_n ,               // ϵͳλ
    
    input           switch_mute,              // 
	 input   [1:0]  volume,                  //
    
    input           sw_treble_up,
    input           sw_treble_down,
    input           sw_bass_up,
    input           sw_bass_down,
    
    input           sw_visualizer,            // A9 Switch (High = Enable Visualizer)
	 
    //es8388 audio interface (master mode)
    input           aud_bclk  ,               // es8388λʱ
    input           aud_lrc   ,               // ź
    input           aud_adcdat,               // Ƶ
    output          aud_mclk  ,               // es8388ʱ
    output          aud_dacdat,               // Ƶ
    
    //es8388 control interface
    output          aud_scl   ,               // es8388SCLź
    inout           aud_sda ,                  // es8388SDAź
    output          led,
    
    output  [7:0]   led_visualizer,           // 8 LEDs for Visualizer
    
    output          ilaclk
);

//wire define
wire [31:0] adc_data;                         // FPGAɼƵ                                 
wire rst_n,locked;
wire [31:0] dac_data_in;
wire [31:0] eq_data_out;
wire        rx_done;
wire        eq_data_valid;

assign dac_data_in = switch_mute ? eq_data_out : 32'd0;

//*****************************************************
//**                    main code
//*****************************************************

reg	[7:0]	rst_cnt=0;	

always @(posedge sys_clk)
begin
	if (rst_cnt[7])
		rst_cnt <=  rst_cnt;
	else
		rst_cnt <= rst_cnt+1'b1;
end			  	

//����PLL������es8388��ʱ��
  clk_wiz_0 u_pll_clk
   (
  
    .refclk(sys_clk),// input clk_50M
    .reset(!rst_cnt[7]),// input resetn
    .stdby(1'b0),
    .extlock(locked),// output locked
    .clk0_out(chipwatcherclk),
    .clk1_out(aud_mclk) // output clk_12M12.288MHz
   );      

audio_eq u_audio_eq(
    .clk            (aud_bclk),
    .rst_n          (locked),
    .lrc            (aud_lrc),
    .data_in        (adc_data),
    .data_valid     (rx_done),
    
    .sw_treble_up   (sw_treble_up),
    .sw_treble_down (sw_treble_down),
    .sw_bass_up     (sw_bass_up),
    .sw_bass_down   (sw_bass_down),
    
    .data_out       (eq_data_out),
    .data_valid_out (eq_data_valid)
);

audio_led_visualizer u_audio_led_visualizer(
    .sys_clk        (sys_clk),
    .rst_n          (locked),
    .audio_in       (eq_data_out),
    .enable_sw      (sw_visualizer),
    .led_out        (led_visualizer)
);

//es8388ģ
es8388_ctrl u_es8388_ctrl(
    .clk                (sys_clk    ),        // ʱź
    .rst_n              (locked      ),        // λź

    .aud_bclk           (aud_bclk   ),        // es8388λʱ
    .aud_lrc            (aud_lrc    ),        // ź
    .aud_adcdat         (aud_adcdat ),        // Ƶ
    .aud_dacdat         (aud_dacdat ),        // Ƶ
    
    .aud_scl            (aud_scl    ),        // es8388SCLź
    .aud_sda            (aud_sda    ),        // es8388SDAź
    
	 .volume             (volume),              //
	 
    .adc_data           (adc_data   ),        // Ƶ
    .dac_data           (dac_data_in),        // Ƶ
    .rx_done            (rx_done),            // 1ν
    .tx_done            ()                    // 1η
);

assign led = locked;


endmodule