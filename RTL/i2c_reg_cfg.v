module i2c_reg_cfg (
    input                clk      ,     // i2c_reg_cfg����ʱ�ӣ��ı���SCL��Ƶ�ʣ�
    input                rst_n    ,     // ��λ�ź�
    input                i2c_done ,     // I2Cһ�β�����ɷ����ź�
    input        [1:0]   volume   ,     // ��������ѡ������
    output  reg          i2c_exec ,     // I2C����ִ���ź�
    output  reg          cfg_done ,     // es8388�������
    output  reg  [15:0]  i2c_data       // �Ĵ�������(��ַ+����)
);

//parameter define
parameter  WL           = 6'd32;        // word length��Ƶ�ֳ���������

//parameter define
localparam REG_NUM      = 5'd27;        // �ܹ���Ҫ���õļĴ�������
localparam SPEAK_VOLUME = 6'd63;        // �������������С������0~63��


//reg define
reg    [1:0]  wl            ;           // word length��Ƶ�ֳ���������
reg    [7:0]  start_init_cnt;           // ��ʼ����ʱ������
reg    [4:0]  init_reg_cnt  ;           // �Ĵ������ø���������
reg    [5:0]  phone_volume  ;           // С0~63,Ĭ40

reg    [1:0]  volume_old;
wire          vol_changed;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) volume_old <= 2'b00;
    else volume_old <= volume;
end

assign vol_changed = (volume != volume_old) && cfg_done;

//��������
always @ (volume) begin
    case(volume)
        2'b00 : phone_volume = 6'd15;
        2'b01 : phone_volume = 6'd30;
        2'b10 : phone_volume = 6'd45;
        2'b11 : phone_volume = 6'd60;
        default : phone_volume = 6'd60;
    endcase
end

//*****************************************************
//**                    main code
//*****************************************************

//��Ƶ�ֳ���λ������������
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wl <= 2'b00;
    else begin
        case(WL)
            6'd16:  wl <= 2'b00; 
            6'd20:  wl <= 2'b01; 
            6'd24:  wl <= 2'b10; 
            6'd32:  wl <= 2'b11; 
            default: 
                    wl <= 2'd00;
        endcase
    end
end

//ϵλʱһʱ
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        start_init_cnt <= 8'd0;
    else if(vol_changed)
        start_init_cnt <= 8'd0;
    else if(start_init_cnt < 8'hff)
        start_init_cnt <= start_init_cnt + 1'b1;
end

//����I2C����
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        i2c_exec <= 1'b0;
    else if(init_reg_cnt == 5'd0 & start_init_cnt == 8'hfe)
        i2c_exec <= 1'b1;
    else if(i2c_done && init_reg_cnt < REG_NUM)
        i2c_exec <= 1'b1;
    else
        i2c_exec <= 1'b0;
end

//���üĴ�������
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        init_reg_cnt <= 5'd0;
    else if(vol_changed)
        init_reg_cnt <= 5'd0;
    else if(i2c_exec)
        init_reg_cnt <= init_reg_cnt + 1'b1;
end

//�Ĵ�����������ź�
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cfg_done <= 1'b0;
    else if(vol_changed)
        cfg_done <= 1'b0;
    else if(i2c_done & (init_reg_cnt == REG_NUM) )
        cfg_done <= 1'b1;
end

//����I2C�����ڼĴ�����ַ��������
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        i2c_data <= 16'b0;
    else begin
        case(init_reg_cnt)
                    // R0,ADC������=DAC������,ʹ��VREF��VMID
            5'd0 : i2c_data <= {8'h00 ,8'h16};
                    // R1,�����е�Դ
            5'd1 : i2c_data <= {8'h01 ,8'h00};
                    // R2,�����е�Դ
            5'd2 : i2c_data <= {8'h02 ,8'h00};
                    // R3,��ADC��Դ
            5'd3: i2c_data <=  {8'h03 ,8'h00};
                    // R4,��DAC��Դ
            5'd4 : i2c_data <= {8'h04 ,8'h3c};
                    // R8,��ģʽ��MCLK����Ƶ��BCLK�Զ�
            5'd5 : i2c_data <= {8'h08 ,8'h80};
                    // R9����˷�����6dB
            5'd6 : i2c_data <= {8'h09 ,8'h22};
                    // R12, ADC����Ϊ24bit I2Sģʽ
            5'd7 : i2c_data <= {8'h0c,8'h00};
                    // R13,����ADC������12.288/256 = 48KSPS
            5'd8 : i2c_data <= {8'h0d,8'h02};
                    // R16,������ADC��������˥��Ϊ0dB
            5'd9 : i2c_data <= {8'h10,8'h00};
                    // R17,������ADC��������˥��Ϊ0dB
            5'd10: i2c_data <= {8'h11,8'h00};
                    // R18,ALC��PGA���淶Χ�趨
            5'd11: i2c_data <= {8'h12,8'h00};
                    // R23, DAC����Ϊ24bit I2Sģʽ
            5'd12: i2c_data <= {8'h17,8'h00};
                    // R24,����DAC������12.288/256 = 48KSPS
            5'd13: i2c_data <= {8'h18,8'h02};
                    // R26,������DAC��������˥��Ϊ0dB
            5'd14: i2c_data <= {8'h1a,8'h00 };
                    // R27,������DAC��������˥��Ϊ0dB
            5'd15: i2c_data <= {8'h1b,8'h00};
                    // R39,��DAC MIXER����ʹ��
            5'd16: i2c_data <= {8'h27,8'hB8};
                    // R42,��DAC MIXER����ʹ��
            5'd17: i2c_data <= {8'h2a,8'hB8};
                    // R43,ADC��DACʹ��ͬһ��LRC
            5'd18: i2c_data <= {8'h2b,8'h80};
            // LOUT1
            5'd19: i2c_data <= {8'h2e, 2'b00, phone_volume};
            // ROUT1
            5'd20: i2c_data <= {8'h2f, 2'b00, phone_volume};
            // LOUT2
            5'd21: i2c_data <= {8'h30, 2'b00, phone_volume};
            // ROUT2
            5'd22: i2c_data <= {8'h31, 2'b00, phone_volume};
            //R10,ADC
            5'd23: i2c_data <= {8'h0a,8'h00};
            5'd26: i2c_data <= {8'hff, 8'hff}; /* WAIT_DLL: �ȴ� 1~5 ms��FSM ��ʵ�֣� */
            default : ;
        endcase
    end
end

endmodule