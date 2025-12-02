# 简介

这是一个基于安路FPGA开发板EG4SBG256开发板+ES8388音频编解码器的驱动程序。该驱动程序实现了通过I2S接口与ES8388芯片进行通信，以实现音频数据的采集和播放功能。

## 主要特性
- 支持 ES8388 音频编解码器，通过 I2S 完成音频数据收发，通过 I2C 进行寄存器配置。
- 支持音量控制、静音、数字均衡（EQ）与 LED 可视化显示模块。
- 面向安路 FPGA（EG4SBG256）开发板，示例引脚映射与演示工程一起提供。
- 可扩展：方便替换 DSP 算法或增加滤波/效果模块。

## 设计目标
- 实现稳定的录放通路（I2S RX/TX），并把音量与 EQ 控制放在 FPGA 可配置逻辑中。
- 使用 I2C 在系统启动和运行期间配置 ES8388 寄存器。
- 提供可视化驱动，为教学与调试提供直观反馈。

## 硬件接线（示例）
注意：下表为示例映射，具体引脚请以开发板原理图/管脚表为准。
- ES8388 -> FPGA（示例）
  - I2C SDA  -> FPGA SDA（检查板上定义）
  - I2C SCL  -> FPGA SCL
  - I2S BCLK -> FPGA BCLK（Bit Clock）
  - I2S LRCK -> FPGA LRCK（Word Select）
  - I2S SDIN -> FPGA SDIN（从 Codec 到 FPGA 的数据 / ADC）
  - I2S SDOUT-> FPGA SDOUT（从 FPGA 到 Codec 的数据 / DAC）
  - 电源与地：请确保 3.3V/芯片电源和地连接正确，注意模拟地与数字地的布线建议。

- 开发板按键 / 指示
  - 音量按键：示例 A13 / B12（可映射为两路按键或编码器）
  - 低音/高音调节：示例 A10/B10 / A11/A12
  - 静音开关：示例 A14
  - LED 可视化开关：示例 A9
  - 板载 LED：8 灯，用于频谱/动画显示

## 构建与部署（通用步骤）
1. 准备 FPGA 工具链（根据你的工作流：Anlogic 官方工具或开源流程）。  
2. 打开工程，调整约束文件（pin constraints）以匹配你的板子引脚。  
3. 运行综合（Synthesis）-> 实现（Implementation）-> 生成 Bitstream。  
4. 使用板载或外部下载工具将 bitstream 写入目标开发板。  
5. 给 ES8388 上电，FPGA 启动后通过 I2C 配置芯片寄存器（见下节）。  
6. 使用示例测试程序或外设（麦克风/扬声器）验证录放功能与 LED 可视化。

## 配置与寄存器（说明）
- 强烈建议参考 ES8388 Datasheet 获取完整寄存器地图和寄存器含义。  
- 常见启动流程（伪代码/示例）：
  - 复位 Codec（写寄存器 soft reset）
  - 配置 A/D、D/A 数据格式（I2S 左/右对齐、位宽 16/24/32）
  - 配置采样率及时钟分频
  - 设置初始音量值并取消静音
- 示例（仅作说明，具体寄存器编号以 datasheet 为准）：
  - 写入寄存器 0x00 = 0x00 // 软件复位（示例）
  - 写入音量寄存器（示例）...

## 测试用例与验证
- 回环测试：播放已知正弦波或方波，采样并检查 FFT/时域波形是否匹配。  
- 麦克风采集：通过 ADC 抓取音频并在 PC 上用工具（如 Audacity）或示波器查看。  
- 输出验证：逐步调节音量与静音开关，验证 I2C 配置命令是否生效（观察声音与 LED 反馈）。

## 故障排查（快速清单）
- 无 I2C 响应：检查 SDA / SCL 连线、上拉电阻、和电源。  
- 无 I2S 时钟（BCLK/LRCK）：确认 FPGA 输出时钟是否已配置并稳定。  
- 无音频输出或输入电平低：检查 ADC/DAC 增益与音量寄存器设置，确保未静音。  
- 串并转换错误（错位/噪声）：检查数据位宽、时钟相位（I2S 对齐）与时序。  
- LED 可视化不变：确认可视化开关信号是否接入，以及 EQ/Envelope 输出有无合理幅度。

## 常见命令/调试工具建议
- I2C 扫描工具：用于确认 Codec 地址是否存在并可响应。  
- 示波器/逻辑分析仪：观测 BCLK/LRCK/SDIN/SDOUT 时序。  
- 音频工具（PC 端）：录放验证音质、时延与失真。

## 致谢
- 感谢 ES8388 方案与安路 FPGA 提供的硬件平台与资料参考。  
- 若使用第三方参考代码或算法，请在相应文件中注明来源并遵循原作者许可。

## 系统架构图

```mermaid
graph LR
    %% ================= 样式定义 =================
    %% 紫色系：外部硬件
    classDef purple fill:#f3e5f5,stroke:#8e24aa,stroke-width:2px,rx:5,ry:5;
    %% 黄色系：FPGA 接口与逻辑
    classDef logic fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,rx:5,ry:5;
    %% 绿色系：FPGA 核心算法
    classDef core fill:#dcedc8,stroke:#558b2f,stroke-width:3px,rx:10,ry:10;

    %% ================= 外部独立设备 =================
    Mic(["麦克风输入"]):::purple
    Codec[("ES8388声卡(I2S/I2C 接口)")]:::purple
    Speaker(["扬声器/耳机输出"]):::purple
    %% 修改：LED改为六边形
    LEDs{{"板载LED灯*8"}}:::purple

    %% ================= 开关控制面板 (成组) =================
    subgraph Controls ["板载开关"]
        direction TB
        SwVol{{"音量调节"}}:::purple
        SwTreble{{"高频调节"}}:::purple
        SwBass{{"低频调节"}}:::purple
        SwMute{{"静音开关"}}:::purple
        SwVis{{"可视化开关"}}:::purple
    end

    %% ================= FPGA 系统 =================
    subgraph FPGA ["顶层模块audio_speak"]
        direction LR
        Ctrl[("I2S 控制 & 音量控制(es8388_ctrl)")]:::logic
        EQ[("数字均衡器(audio_eq)")]:::core
        Mute[("静音代码(位于顶层模块)")]:::logic
        Vis[("音量可视化(audio_led_visualizer)")]:::logic
    end

    %% ================= 连线逻辑 =================
    
    %% 1. 音频主链路
    Mic ==> Codec
    Codec ==> |"I2S ADC"| Ctrl
    Ctrl ==> |"32位 并行数据"| EQ
    EQ ==> |"均衡后数据"| Mute
    Mute ==> |"DAC 数据"| Ctrl
    Ctrl ==> |"I2S DAC"| Codec
    Codec ==> Speaker

    %% 2. 视觉链路
    EQ ==> Vis
    Vis ==> |"驱动信号"| LEDs

    %% 3. 控制信号链路 (从控制面板接入)
    SwVol -.-> |"A13/B12"| Ctrl
    SwTreble -.-> |"A11/A12"| EQ
    SwBass -.-> |"A10/B10"| EQ
    SwMute -.-> |"A14"| Mute
    SwVis -.-> |"A9"| Vis
```

```mermaid
graph LR
    %% 样式定义 (保持一致)
    classDef purple fill:#f3e5f5,stroke:#8e24aa,stroke-width:2px,rx:5,ry:5;
    classDef algo fill:#dcedc8,stroke:#558b2f,stroke-width:2px,rx:0,ry:0;
    classDef logic fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,rx:0,ry:0;

    %% 外部接口
    I2S_In(["I2S数据输入"]):::purple
    I2S_Out(["I2S数据输出"]):::purple
    I2C_Bus(["I2C总线(SCL/SDA)"]):::purple
    
    %% 开关组
    Sw_Mute{{"静音开关(A14)"}}:::purple
    Sw_Vol{{"音量按键(A13/B12)"}}:::purple


    %% 内部逻辑
    subgraph Ctrl_Logic ["驱动以及音量控制功能 (es8388_ctrl + audio_speak)"]
        direction TB
        
        %% 数据通路
        RX["串转并(audio_receive)"]:::algo
        TX["并转串(audio_send)"]:::algo
        Mux{"静音选择器(Mux)"}:::logic
        
        %% 控制通路
        CFG["I2C配置状态机(i2c_reg_cfg)"]:::algo
    end

    %% 连线关系
    %% 1. 音频数据流 (Data Path)
    I2S_In ==> |"串行数据"| RX
    RX ==> |"32位并行数据"| Mux
    Mux ==> |"DAC数据"| TX
    TX ==> |"串行数据"| I2S_Out

    %% 2. 静音控制
    Sw_Mute -.-> |"1:正常 / 0:静音"| Mux

    %% 3. 硬件配置流 (Config Path)
    Sw_Vol -.-> |"音量等级"| CFG
    CFG ==> |"寄存器读写"| I2C_Bus
    
    %% 细节标注 (静音逻辑是纯组合逻辑)
    style Mux stroke-dasharray: 5 5
```

```mermaid
graph LR
    %% 样式定义
    classDef purple fill:#f3e5f5,stroke:#8e24aa,stroke-width:2px,rx:5,ry:5;
    classDef algo fill:#dcedc8,stroke:#558b2f,stroke-width:2px,rx:0,ry:0;
    classDef logic fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,rx:0,ry:0;

    %% 输入输出
    Audio_In(["音频输入"]):::purple
    Sw_Vis{{"可视化开关(A9)"}}:::purple
    LEDs(["LED*8输出"]):::purple

    %% 处理逻辑
    subgraph Vis_Logic ["可视化处理 (audio_led_visualizer)"]
        direction TB
        
        %% 模式选择
        Mode{"模式选择"}:::logic
        
        %% 路径A：频谱显示
        Abs["取绝对值"]:::algo
        Envelope["包络检波"]:::algo
        Mapping["阈值量化映射"]:::algo
        
        %% 路径B：待机动画
        Anim["待机动画生成(弹跳小球算法)"]:::algo
        
    end

    %% 连线
    Audio_In ==> Abs
    Abs ==> Envelope
    Envelope ==> Mapping
    
    Mapping ==> Mode
    Anim ==> Mode
    
    Sw_Vis -.-> |"1: 频谱模式 / 0: 待机动画"| Mode
    Mode ==> LEDs
    
    %% 细节标注
    style Envelope stroke-dasharray: 5 5
```

```mermaid
graph LR
    %% 样式定义 (保持一致)
    classDef purple fill:#f3e5f5,stroke:#8e24aa,stroke-width:2px,rx:5,ry:5;
    classDef algo fill:#dcedc8,stroke:#558b2f,stroke-width:2px,rx:0,ry:0;
    classDef logic fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,rx:0,ry:0;

    %% 输入输出
    Audio_In(["音频输入"]):::purple
    Audio_Out(["均衡后输出"]):::purple
    
    %% 开关组
    Sw_Bass{{"低音键(Low+/-)"}}:::purple
    Sw_Treble{{"高音键(High+/-)"}}:::purple

    %% 算法流程
    subgraph DSP_Logic ["DSP算法流程(audio_eq)"]
        direction TB
        
        %% 核心运算单元
        LPF["低通滤波(分频)"]:::algo
        Sub["减法提取高频"]:::algo
        
        Calc_Bass["低频增益计算"]:::algo
        Calc_Treble["高频增益计算"]:::algo
        
        Sum{"信号叠加"}:::logic
        Sat["防溢出饱和处理"]:::algo
    end

    %% 连线关系
    %% 1. 分频逻辑
    Audio_In ==> LPF
    Audio_In ==> Sub
    LPF ==> |"低频分量"| Calc_Bass
    LPF ==> |"减去低频"| Sub
    Sub ==> |"剩余即高频"| Calc_Treble

    %% 2. 增益控制
    Sw_Bass -.-> |"A10/B10"| Calc_Bass
    Sw_Treble -.-> |"A11/A12"| Calc_Treble

    %% 3. 混合输出
    Audio_In ==> Sum
    Calc_Bass ==> Sum
    Calc_Treble ==> Sum
    
    Sum ==> Sat
    Sat ==> Audio_Out
```