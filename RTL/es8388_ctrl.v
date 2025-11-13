module es8388_ctrl(
    input                clk        ,   // ʱ���ź�
    input                rst_n      ,   // ��λ�ź�
    
    //audio interface(mast  
    input                aud_bclk   ,   // es8388λʱ��
    input                aud_lrc    ,   // �����ź�
    input                aud_adcdat ,   // ��Ƶ����
    output               aud_dacdat ,   // ��Ƶ���
    
    //control interfac  
    output               aud_scl    ,   // es8388��SCL�ź�
    inout                aud_sda    ,   // es8388��SDA�ź�
    
    //user i    
    output     [31:0]    adc_data   ,   // �������Ƶ����
    input      [31:0]    dac_data   ,   // Ƶ
	 
	 input      [1:0]    volume     ,    //
    input                fir_enable ,   // FIR filter enable
    input                play_enable,   // Playback enable
    output               rx_done    ,   // һβɼ
    output               tx_done        // һη
);

//parameter define
parameter    WL = 6'd24;                // word length��Ƶ�ֳ�����

//*****************************************************
//**                    main code
//*****************************************************

//����es8388�Ĵ�������ģ��
es8388_config #(
    .WL             (WL)
) u_es8388_config(
    .clk            (clk),              // ʱ���ź�
    .rst_n          (rst_n),            // ��λ�ź�
    
	 .volume       (volume),          //������������
	 
    .aud_scl        (aud_scl),          // es8388��SCLʱ��
    .aud_sda        (aud_sda)           // es8388��SDA�ź�
);

//����es8388��Ƶ����ģ��
audio_receive #(
    .WL             (WL)
) u_audio_receive(    
    .rst_n          (rst_n),            // λź
    
    .aud_bclk       (aud_bclk),         // es8388λʱ
    .aud_lrc        (aud_lrc),          // ź
    .aud_adcdat     (aud_adcdat),       // Ƶ
    .fir_enable     (fir_enable),
        
    .adc_data       (adc_data),         // FPGAյ
    .rx_done        (rx_done)           // FPGA
);

//����es8388��Ƶ����ģ��
audio_send #(
    .WL             (WL)
) u_audio_send(
    .rst_n          (rst_n),            // λź
        
    .aud_bclk       (aud_bclk),         // es83888λʱ
    .aud_lrc        (aud_lrc),          // ź
    .aud_dacdat     (aud_dacdat),       // ��Ƶ
    
    .play_enable    (play_enable),
    .dac_data       (dac_data),         // ԤƵ
    .tx_done        (tx_done)           // ź
);

endmodule