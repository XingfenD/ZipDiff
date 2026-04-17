"""
ZipDiff 实验结果可视化
生成三张图：
  1. 图4.1 — 8小时主实验：不一致对数 & 语料库规模随时间变化
  2. 图4.2 — 消融实验：各配置不一致对数随输入量增长对比
  3. 图4.3 — 变异算子 UCB Reward 排名（配置A，Top 15）

用法：
  python tools/plot_results.py
输出：
  evaluation/figures/fig4_1_main_experiment.png
  evaluation/figures/fig4_2_ablation_incons.png
  evaluation/figures/fig4_3_mutation_reward.png
"""

import json
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np

# ── 路径 ──────────────────────────────────────────────────────────────────────
BASE      = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATS_DIR = os.path.join(BASE, 'evaluation', 'stats')
OUT_DIR   = os.path.join(BASE, 'evaluation', 'figures')
os.makedirs(OUT_DIR, exist_ok=True)

# 字体设置（支持中文）
plt.rcParams['font.sans-serif'] = ['SimHei', 'Microsoft YaHei', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False
plt.rcParams['figure.dpi'] = 150

# ── 加载数据 ──────────────────────────────────────────────────────────────────
def load(fname):
    with open(os.path.join(STATS_DIR, fname)) as f:
        return json.load(f)

main_A  = load('20260416-121708-A.json')   # 8小时主实验
abl_A   = load('20260416-015549-A.json')   # 消融 Config A
abl_B0  = load('20260416-025608-B0.json')  # 消融 Config B0
abl_B   = load('20260416-035644-B.json')   # 消融 Config B
abl_C   = load('20260416-045657-C.json')   # 消融 Config C
abl_D   = load('20260416-055704-D.json')   # 消融 Config D（提前终止）

def extract(data, x_key='seconds_used', y_key='incons_count'):
    xs = [it[x_key] for it in data['iterations']]
    ys = [it[y_key] for it in data['iterations']]
    return xs, ys

# ══════════════════════════════════════════════════════════════════════════════
# 图4.1 — 8小时主实验
# ══════════════════════════════════════════════════════════════════════════════
fig, ax1 = plt.subplots(figsize=(8, 4.5))

t_h, incons = extract(main_A, 'seconds_used', 'incons_count')
t_h = [t / 3600 for t in t_h]
_, corpus  = extract(main_A, 'seconds_used', 'corpus_size')

color_incons = '#2563EB'
color_corpus = '#DC2626'

ax1.plot(t_h, incons, color=color_incons, linewidth=2, label='不一致解析器对数')
ax1.set_xlabel('运行时长（小时）', fontsize=12)
ax1.set_ylabel('不一致解析器对数', color=color_incons, fontsize=12)
ax1.tick_params(axis='y', labelcolor=color_incons)
ax1.set_xlim(0, 8.2)
ax1.yaxis.set_minor_locator(mticker.AutoMinorLocator())

ax2 = ax1.twinx()
ax2.plot(t_h, corpus, color=color_corpus, linewidth=2, linestyle='--', label='语料库规模')
ax2.set_ylabel('语料库种子数', color=color_corpus, fontsize=12)
ax2.tick_params(axis='y', labelcolor=color_corpus)

# 标注饱和点
sat_t = next(t for t, v in zip(t_h, incons) if v >= 946)
ax1.axvline(x=sat_t, color='gray', linestyle=':', linewidth=1.2, alpha=0.7)
ax1.annotate(f'饱和 @{sat_t:.1f}h\nincons=946',
             xy=(sat_t, 946), xytext=(sat_t + 0.4, 900),
             fontsize=9, color='gray',
             arrowprops=dict(arrowstyle='->', color='gray', lw=1))

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc='center right', fontsize=10)

ax1.set_title('图4.1  8小时主实验（Config A，α=0.7）', fontsize=13, pad=10)
ax1.grid(axis='x', linestyle='--', alpha=0.4)
fig.tight_layout()
out1 = os.path.join(OUT_DIR, 'fig4_1_main_experiment.png')
fig.savefig(out1, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out1}')

# ══════════════════════════════════════════════════════════════════════════════
# 图4.2 — 消融实验：不一致对数随输入量增长
# ══════════════════════════════════════════════════════════════════════════════
fig, ax = plt.subplots(figsize=(8, 4.5))

configs = [
    (abl_A,  'Config A（完整，α=0.7）',    '#2563EB', '-',  2.0),
    (abl_B0, 'Config B0（基线，α=0.0）',   '#16A34A', '--', 1.8),
    (abl_B,  'Config B（无覆盖信号）',      '#9333EA', '-.',  1.6),
    (abl_C,  'Config C（Argmax-UCB）',     '#EA580C', ':',  1.8),
    (abl_D,  'Config D（纯字节变异*）',    '#6B7280', '--', 1.4),
]

for data, label, color, ls, lw in configs:
    xs, ys = extract(data, 'input_count', 'incons_count')
    ax.plot(xs, ys, label=label, color=color, linestyle=ls, linewidth=lw)

ax.set_xlabel('处理输入数', fontsize=12)
ax.set_ylabel('不一致解析器对数', fontsize=12)
ax.set_title('图4.2  消融实验：各配置不一致对数随输入量增长', fontsize=13, pad=10)
ax.legend(fontsize=9, loc='lower right')
ax.grid(linestyle='--', alpha=0.4)
ax.set_xlim(0)
ax.set_ylim(0)
fig.tight_layout()
out2 = os.path.join(OUT_DIR, 'fig4_2_ablation_incons.png')
fig.savefig(out2, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out2}')

# ══════════════════════════════════════════════════════════════════════════════
# 图4.3 — 变异算子 UCB Reward 排名（配置A 8小时，Top 15）
# ══════════════════════════════════════════════════════════════════════════════
zip_muts  = main_A['mutations']['zip']
byte_muts = main_A['mutations']['bytes']

all_muts = {}
for name, (reward, ucb) in zip_muts.items():
    all_muts[name] = (reward, 'ZIP结构化')
for name, (reward, ucb) in byte_muts.items():
    all_muts[name] = (reward, '字节级')

sorted_muts = sorted(all_muts.items(), key=lambda x: x[1][0], reverse=True)[:15]
names   = [m[0] for m in sorted_muts]
rewards = [m[1][0] for m in sorted_muts]
types   = [m[1][1] for m in sorted_muts]
colors  = ['#2563EB' if t == 'ZIP结构化' else '#DC2626' for t in types]

fig, ax = plt.subplots(figsize=(9, 5.5))
bars = ax.barh(range(len(names)), rewards, color=colors, edgecolor='white', height=0.7)
ax.set_yticks(range(len(names)))
ax.set_yticklabels(names, fontsize=9)
ax.invert_yaxis()
ax.set_xlabel('UCB Reward', fontsize=12)
ax.set_title('图4.3  变异算子 UCB Reward 排名（Config A 8小时，Top 15）', fontsize=12, pad=10)

# 图例
from matplotlib.patches import Patch
legend_elements = [Patch(facecolor='#2563EB', label='ZIP结构化变异'),
                   Patch(facecolor='#DC2626', label='字节级变异')]
ax.legend(handles=legend_elements, fontsize=10, loc='lower right')
ax.grid(axis='x', linestyle='--', alpha=0.4)

# 数值标注
for i, (bar, val) in enumerate(zip(bars, rewards)):
    ax.text(val + 0.0005, i, f'{val:.4f}', va='center', fontsize=8, color='#374151')

fig.tight_layout()
out3 = os.path.join(OUT_DIR, 'fig4_3_mutation_reward.png')
fig.savefig(out3, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out3}')

print('\n全部图表已生成至:', OUT_DIR)
