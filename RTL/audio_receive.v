module audio_receive #(parameter WL = 6'd32) (      // WL(word length��Ƶ�ֳ�����)
    //system clock 50MHz
    input                 rst_n     ,               // ��λ�ź�

    //wm8978 interface
    input                 aud_bclk  ,               // es8388λʱ��
    input                 aud_lrc   ,               // �����ź�
    input                 aud_adcdat,               // ��Ƶ����
    input                 fir_enable,               // FIR filter enable signal

    //user interface
   (* mark_debug = "true" *)  output   reg          rx_done   ,               // FPGA�����������
    output   reg [31:0]   adc_data                  // FPGA���յ�����
);

// Internal wire for unfiltered data
wire signed [31:0] adc_data_unfiltered;
wire signed [31:0] adc_data_filtered;

// Instantiate the FIR filter
fir_filter #(
    .DATA_WIDTH(32),
    .TAPS_N(16)
) fir_lowpass_filter (
    .clk(aud_bclk),
    .rst_n(rst_n),
    .data_in(adc_data_unfiltered),
    .data_out(adc_data_filtered)
);

//reg define
reg              aud_lrc_d0;                        // aud_lrc�ӳ�һ��ʱ������
(* mark_debug = "true" *) reg    [ 5:0]    rx_cnt;                            // �������ݼ���
reg    [31:0]    adc_data_t;                        // Ԥ�������Ƶ���ݵ��ݴ�ֵ

//wire define
(* mark_debug = "true" *) wire             lrc_edge ;                         // �����ź�

//*****************************************************
//**                    main code
//*****************************************************

assign   lrc_edge = aud_lrc ^ aud_lrc_d0;           // LRC�źŵı��ؼ��

//Ϊ����aud_lrc�仯�ĵڶ���AUD_BCLK�����زɼ�aud_adcdat,�ӳٴ��Ĳɼ�
always @(posedge aud_bclk or negedge rst_n) begin
    if(!rst_n)
        aud_lrc_d0 <= 1'b0;
    else
        aud_lrc_d0 <= aud_lrc;
end

//�ɼ�32λ��Ƶ���ݵļ���
always @(posedge aud_bclk or negedge rst_n) begin
    if(!rst_n) begin
        rx_cnt <= 6'd0;
    end
    else if(lrc_edge == 1'b1)
        rx_cnt <= 6'd0;
    else if(rx_cnt < 6'd35)
        rx_cnt <= rx_cnt + 1'b1;
end

//�Ѳɼ�������Ƶ������ʱ�����һ���Ĵ�����
always @(posedge aud_bclk or negedge rst_n) begin
    if(!rst_n) begin
        adc_data_t <= 32'b0;
    end
    else if(rx_cnt < WL)
        adc_data_t[WL - 1'd1 - rx_cnt] <= aud_adcdat;
end

//����ʱ���ݴ��ݸ�adc_data,��ʹ��rx_done,����һ�βɼ����
always @(posedge aud_bclk or negedge rst_n) begin
    if(!rst_n) begin
        rx_done   <=  1'b0;
    end
    else if(rx_cnt == WL) begin
        rx_done <= 1'b1;
    end
    else
        rx_done <= 1'b0;
end

assign adc_data_unfiltered = adc_data_t;

always @(*) begin
    if (fir_enable) begin
        adc_data = adc_data_filtered;
    end else begin
        adc_data = adc_data_unfiltered;
    end
end

endmodule