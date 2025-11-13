module audio_speak(
    input           sys_clk   ,               // ϵͳʱ��(50MHz)
    input           sys_rst_n ,               // ϵͳ��λ
    
     input   [1:0]  volume,                  //
     input          play_enable,             // Playback enable (connect to A14)
     input          filter_enable,           // FIR Filter enable (connect to A13)
     input          metal_enable,            // Heavy metal style enable (connect to B12)
	 
    //es8388 audio interface (master mode)
    input           aud_bclk  ,               // es8388λʱ��
    input           aud_lrc   ,               // �����ź�
    input           aud_adcdat,               // ��Ƶ����
    output          aud_mclk  ,               // es8388����ʱ��
    output          aud_dacdat,               // ��Ƶ���
    
    //es8388 control interface
    output          aud_scl   ,               // es8388��SCL�ź�
    inout           aud_sda ,                  // es8388��SDA�ź�
    output          led,
    output          filter_led,
    output          play_led,
    output          ilaclk
);

//wire define
wire signed [31:0] adc_data;                  // FPGA�ɼ�����Ƶ����
wire signed [31:0] metal_data;                // Heavy metal processed audio sample
wire signed [31:0] playback_data;             // Selected audio sample for playback
wire rst_n,locked;
wire chipwatcherclk;                          // Internal PLL output for monitoring/debug
wire rx_done;
wire tx_done;

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
    .clk1_out(aud_mclk) // output clk_12M��12.288MHz
   );      


//����es8388����ģ��
heavy_metal_fx u_heavy_metal_fx(
	.clk            (aud_bclk     ),
	.rst_n          (locked       ),
	.enable         (metal_enable ),
	.sample_strobe  (rx_done      ),
	.sample_in      (adc_data     ),
	.sample_out     (metal_data   )
);

assign playback_data = metal_enable ? metal_data : adc_data;

es8388_ctrl u_es8388_ctrl(
    .clk                (sys_clk    ),        // ʱ���ź�
    .rst_n              (locked      ),        // ��λ�ź�

    .aud_bclk           (aud_bclk   ),        // es8388λʱ��
    .aud_lrc            (aud_lrc    ),        // �����ź�
    .aud_adcdat         (aud_adcdat ),        // ��Ƶ����
    .aud_dacdat         (aud_dacdat ),        // ��Ƶ���
    
    .aud_scl            (aud_scl    ),        // es8388��SCL�ź�
    .aud_sda            (aud_sda    ),        // es8388SDAź
    
	 .volume             (volume),              //
	 .fir_enable         (filter_enable),         // Connect to the input switch
	 .play_enable        (play_enable),         // Connect to the input switch
	 
    .adc_data           (adc_data   ),        // Ƶ
    .dac_data           (playback_data),      // Ƶ
    .rx_done            (rx_done   ),        // 1�ν������
    .tx_done            (tx_done   )         // 1η
);

assign led = locked;
assign filter_led = filter_enable;
assign play_led = play_enable;


endmodule