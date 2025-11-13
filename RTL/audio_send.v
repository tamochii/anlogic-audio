module audio_send #(parameter WL = 6'd32) (    // WL(word length��Ƶ�ֳ�����)
    //system reset
    input                  rst_n     ,         // ��λ�ź�

    //wm8978 interface
    input                  aud_bclk  ,         // es8388λʱ��
    input                  aud_lrc   ,         // �����ź�
    output   reg           aud_dacdat,         // ��Ƶ�������
    //user interface
    input                  play_enable,      // Playback enable
    input         [31:0]   dac_data  ,         // Ԥ�������Ƶ����
    output   reg           tx_done             // ����һ����Ƶλ�����
);

//reg define
reg              aud_lrc_d0;                   // �ӳ�һ��ʱ������
(* mark_debug = "true" *) reg    [ 5:0]    tx_cnt;                       // �������ݼ���
reg    [31:0]    dac_data_t;                   // Ԥ�������Ƶ���ݵ��ݴ�ֵ

//wire define
(* mark_debug = "true" *) wire             lrc_edge;                     //// �����ź�

//*****************************************************
//**                    main code
//*****************************************************

assign  lrc_edge = aud_lrc ^ aud_lrc_d0;     // LRC�źŵı��ؼ��

//Ϊ����aud_lrc�仯�ĵڶ���AUD_BCLK�����زɼ�aud_adcdat,�ӳٴ��Ĳɼ�
always @(posedge aud_bclk or negedge rst_n) begin
    if(!rst_n)
        aud_lrc_d0 <= 1'b0;
    else
        aud_lrc_d0 <= aud_lrc;
end

//����32λ��Ƶ���ݵļ���
always @(posedge aud_bclk or negedge rst_n) begin
    if(!rst_n) begin
        tx_cnt     <=  6'd0;
        dac_data_t <= 32'd0;
    end
    else if(lrc_edge == 1'b1) begin
        tx_cnt     <= 6'd0;
        dac_data_t <= dac_data;
    end
    else if(tx_cnt < 6'd35)
        tx_cnt <= tx_cnt + 1'b1;
end

//��������ź�
always @(posedge aud_bclk or negedge rst_n) begin
    if(!rst_n) begin
        tx_done <= 1'b0;
    end
    else if(tx_cnt == WL)
        tx_done <= 1'b1;
    else
        tx_done <= 1'b0;
end

//��Ԥ���͵���Ƶ���ݴ��з��ͳ�ȥ
always @(negedge aud_bclk or negedge rst_n) begin
    if(!rst_n) begin
        aud_dacdat <= 1'b0;
    end
    else if(tx_cnt < WL && play_enable) // Only send data if play_enable is high
        aud_dacdat <= dac_data_t[WL - 1'd1 - tx_cnt];
    else
        aud_dacdat <= 1'b0; // Otherwise, send silence
end

endmodule