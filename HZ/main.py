import matplotlib.pyplot as plt
import glob
import pandas as pd
import os

# ================= 配置区域 =================
# 1. 设置图片清晰度 (DPI) 和尺寸 (宽, 高)
FIGURE_DPI = 300
FIGURE_SIZE = (15, 8)

# 2. 设置 Y轴范围 (dB) - 根据需要调整
Y_MIN = -90
Y_MAX = 0

# 3. 设置线条粗细
LINE_WIDTH = 1


# ===========================================

def configure_fonts():
    """自动配置中文字体，防止乱码"""
    plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示为方块的问题

    # 尝试设置字体，优先 SimHei (黑体)，其次 Microsoft YaHei (微软雅黑)
    try:
        plt.rcParams['font.sans-serif'] = ['SimHei']
    except:
        plt.rcParams['font.sans-serif'] = ['Microsoft YaHei']


def main():
    # 配置字体
    configure_fonts()

    # 创建高清画布
    plt.figure(figsize=FIGURE_SIZE, dpi=FIGURE_DPI)

    # 获取当前文件夹下所有的 txt 文件
    txt_files = glob.glob("*.txt")

    if not txt_files:
        print("错误：当前文件夹下没有找到 .txt 文件！请确保脚本和数据文件在一起。")
        return

    print(f"找到 {len(txt_files)} 个文件，开始绘制...")

    # 循环读取并绘制
    for file_path in txt_files:
        try:
            # 1. 读取数据
            # Audacity 导出通常是 Tab 分隔，跳过第一行表头(skiprows=1)
            # 如果你的 txt 没有表头，把 skiprows=1 改为 skiprows=0
            data = pd.read_csv(file_path, sep='\t', names=['Freq', 'Level'], skiprows=1, engine='python')

            # 2. 处理文件名：去除路径和 .txt 后缀，只保留文件名作为图例
            # 例如 "D:\Data\Audio_1.txt" -> "Audio_1"
            file_name = os.path.basename(file_path)  # 拿文件名
            clean_label = os.path.splitext(file_name)[0]  # 去后缀

            # 3. 绘制曲线
            plt.plot(data['Freq'], data['Level'], label=clean_label, linewidth=LINE_WIDTH)

            print(f"已添加: {clean_label}")

        except Exception as e:
            print(f"读取文件 {file_path} 失败: {e}")

    # ================= 图表美化与锁定 =================

    # 1. 锁定 X 轴 (人耳听觉范围 20Hz - 20000Hz) 并设为对数
    plt.xlim(50, 20000)
    plt.xscale('log')

    # 2. 锁定 Y 轴
    plt.ylim(Y_MIN, Y_MAX)

    # 3. 添加网格 (which='both' 同时显示主刻度和细分刻度)
    plt.grid(True, which="both", ls="-", alpha=0.3)

    # 4. 添加标签和标题
    plt.xlabel("频率 Frequency (Hz)", fontsize=12)
    plt.ylabel("电平 Level (dB)", fontsize=12)
    plt.title("音频频谱对比分析 (Spectrum Analysis)", fontsize=14)

    # 5. 显示图例 (自动放在合适位置)
    plt.legend(loc='best', fontsize=10)

    # ================= 输出 =================

    # 保存高清图片到本地
    save_name = '频谱对比结果_高清.png'
    plt.savefig(save_name, dpi=FIGURE_DPI, bbox_inches='tight')
    print(f"\n图片已保存为: {save_name}")

    # 显示窗口
    plt.show()


if __name__ == "__main__":
    main()