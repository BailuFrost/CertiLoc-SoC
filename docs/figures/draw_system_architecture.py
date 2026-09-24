"""绘制阶段1无CPU定位加速器的系统架构图。"""

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch


plt.rcParams["font.sans-serif"] = ["Microsoft YaHei", "SimHei", "DejaVu Sans"]
plt.rcParams["axes.unicode_minus"] = False

INK = "#1C2430"
MUTED = "#4B5565"
FPGA_EDGE = "#243044"
EDGE = "#314056"
PC_FILL = "#EEF2F6"
CLK_FILL = "#F6E8C8"
COMM_FILL = "#D9E8F6"
GEOM_FILL = "#F8E7D6"
MEM_FILL = "#E9E0F6"


def rounded(ax, x, y, w, h, face, radius=0.35, lw=1.15):
    ax.add_patch(
        FancyBboxPatch(
            (x, y),
            w,
            h,
            boxstyle=f"round,pad=0.012,rounding_size={radius}",
            facecolor=face,
            edgecolor=EDGE,
            linewidth=lw,
        )
    )


def label(ax, x, y, text, size=11, weight="regular", color=INK):
    ax.text(x, y, text, fontsize=size, fontweight=weight, color=color, ha="center", va="center", linespacing=1.2)


def arrow(ax, start, end, style="-|>"):
    ax.add_patch(
        FancyArrowPatch(
            start,
            end,
            arrowstyle=style,
            mutation_scale=11,
            linewidth=1.1,
            color=FPGA_EDGE,
            shrinkA=1,
            shrinkB=1,
            joinstyle="miter",
        )
    )


def module(ax, x, y, w, h, face, title, subtitle):
    rounded(ax, x, y, w, h, face, radius=0.28)
    label(ax, x + w / 2, y + h * 0.62, title, 11, "bold")
    label(ax, x + w / 2, y + h * 0.32, subtitle, 9, color=MUTED)


def main():
    fig, ax = plt.subplots(figsize=(13.8, 7.8), dpi=150)
    ax.set_xlim(0, 138)
    ax.set_ylim(0, 78)
    ax.axis("off")
    fig.patch.set_facecolor("white")
    ax.set_facecolor("white")

    rounded(ax, 2, 30, 16, 18, PC_FILL, radius=0.45, lw=1.3)
    label(ax, 10, 42.2, "PC 上位机", 13, "bold")
    label(ax, 10, 37.6, "配置与观测", 10, color=MUTED)
    label(ax, 10, 34.2, "结果与对照", 10, color=MUTED)

    rounded(ax, 22, 3, 113, 72, "#FCFCFD", radius=0.5, lw=1.55)
    label(ax, 78.5, 71.2, "radio_localization_fpga_top", 14, "bold")
    label(ax, 78.5, 68.2, "Basys 3 · XC7A35T · 100 MHz 单时钟域 · 无片上 CPU", 10, color=MUTED)

    rounded(ax, 25, 59.4, 107, 6.4, CLK_FILL, radius=0.28)
    label(ax, 40, 62.6, "clk_100mhz_i", 11, "bold")
    label(ax, 64, 62.6, "复位同步", 11, "bold")
    label(ax, 88, 62.6, "同步复位", 11, "bold")
    label(ax, 114, 62.6, "LED0–3 / debug_trigger", 10, "bold")
    arrow(ax, (49.5, 62.6), (57.2, 62.6))
    arrow(ax, (70.8, 62.6), (80.6, 62.6))

    module(ax, 25, 47.2, 24, 9.2, COMM_FILL, "uart_rx", "115200 bit/s · 8N1")
    module(ax, 54, 47.2, 24, 9.2, COMM_FILL, "packet_decoder", "crc16_ccitt_byte")
    module(ax, 83, 47.2, 24, 9.2, COMM_FILL, "command_adapter", "命令与观测提交")
    arrow(ax, (49.2, 51.8), (53.8, 51.8))
    arrow(ax, (78.2, 51.8), (82.8, 51.8))
    arrow(ax, (18.1, 41.2), (24.8, 51.8))
    label(ax, 20.6, 54.6, "RX", 8, color=MUTED)

    rounded(ax, 25, 17.6, 107, 26.6, "#F7FBF5", radius=0.4, lw=1.25)
    label(ax, 78.5, 41.6, "localization_command_ctrl", 12, "bold")
    label(ax, 78.5, 39.0, "调度、观测寄存、错误与结果锁存", 9, color=MUTED)

    module(ax, 27.6, 29.6, 22.6, 7.6, MEM_FILL, "观测存储", "最多 20 条")
    module(ax, 53.0, 29.6, 22.6, 7.6, GEOM_FILL, "constraint_gen", "cordic_sincos")
    module(ax, 78.4, 29.6, 22.6, 7.6, GEOM_FILL, "clip_engine", "分类与交点")
    module(ax, 53.0, 19.0, 22.6, 7.2, MEM_FILL, "polygon ROM", "720 × Q16.16")
    module(ax, 78.4, 19.0, 22.6, 7.2, MEM_FILL, "vertex RAM", "A/B 双缓冲")
    module(ax, 103.8, 19.0, 22.6, 7.2, GEOM_FILL, "diameter_engine", "顶点对穷举")
    arrow(ax, (50.2, 33.4), (52.8, 33.4))
    arrow(ax, (75.6, 33.4), (78.2, 33.4))
    arrow(ax, (89.7, 29.4), (89.7, 26.4), style="<|-|>")
    arrow(ax, (75.6, 22.6), (78.2, 22.6))
    arrow(ax, (101.0, 22.6), (103.6, 22.6))
    arrow(ax, (107.2, 47.2), (107.2, 44.4))

    module(ax, 108, 6.2, 24, 8.8, COMM_FILL, "响应选择", "解析错误优先")
    module(ax, 79, 6.2, 24, 8.8, COMM_FILL, "response_adapter", "结果与顶点分页")
    module(ax, 50, 6.2, 24, 8.8, COMM_FILL, "packet_encoder", "crc16_ccitt_byte")
    module(ax, 25, 6.2, 20, 8.8, COMM_FILL, "uart_tx", "115200 bit/s · 8N1")
    arrow(ax, (119.8, 17.6), (119.8, 15.2))
    arrow(ax, (108, 10.6), (103.2, 10.6))
    arrow(ax, (79, 10.6), (74.2, 10.6))
    arrow(ax, (50, 10.6), (45.2, 10.6))
    arrow(ax, (25, 10.6), (18.1, 34.8))
    label(ax, 20.4, 16.8, "TX", 8, color=MUTED)

    out = Path(__file__).resolve().parent / "system_architecture.png"
    fig.savefig(out, dpi=150, bbox_inches="tight", facecolor="white", pad_inches=0.16)
    plt.close(fig)


if __name__ == "__main__":
    main()
