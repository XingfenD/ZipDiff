"""
ZipDiff 实验结果可视化
生成六张图：
  1. 图4.1 — 8小时主实验：不一致对数 & 语料库规模随时间变化
  2. 图4.2 — 消融实验：各配置不一致对数随时间变化
  3. 图4.3 — 消融实验：各配置语料库规模随时间变化
  4. 图4.4 — 变异算子 UCB Reward 排名（配置A，Top 15）
  5. 图4.8 — 消融实验：各配置不一致对数 vs 处理输入数（样本效率）
  6. 图4.9 — 消融实验：前5000输入放大视图（早期样本效率差异）

用法：
  python tools/plot_results.py
输出：
  evaluation/figures/fig4_1_main_experiment.png
  evaluation/figures/fig4_2_ablation_incons.png
  evaluation/figures/fig4_3_ablation_corpus.png
  evaluation/figures/fig4_4_mutation_reward.png
  evaluation/figures/fig4_8_sample_efficiency.png
  evaluation/figures/fig4_9_sample_efficiency_early.png
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

main_A = load('20260416-121708-A.json')   # 8小时主实验
abl_A  = load('20260416-121708-A.json')   # 消融 Config A（同主实验）
abl_B0 = load('20260416-224624-B0.json')  # 消融 Config B0（8小时）
abl_B  = load('20260417-064645-B.json')   # 消融 Config B（8小时）
abl_C  = load('20260417-144701-C.json')   # 消融 Config C（8小时）
abl_D  = load('20260417-224813-D.json')   # 消融 Config D（8小时）

def extract(data, x_key='seconds_used', y_key='incons_count'):
    xs = [it[x_key] for it in data['iterations']]
    ys = [it[y_key] for it in data['iterations']]
    return xs, ys

# ══════════════════════════════════════════════════════════════════════════════
# 图4.1 — 8小时主实验：不一致对数 & 语料库规模双轴图
# ══════════════════════════════════════════════════════════════════════════════
fig, ax1 = plt.subplots(figsize=(8, 4.5))

t_raw, incons = extract(main_A, 'seconds_used', 'incons_count')
t_h = [t / 3600 for t in t_raw]
_, corpus = extract(main_A, 'seconds_used', 'corpus_size')

color_incons = '#2563EB'
color_corpus = '#DC2626'

ax1.plot(t_h, incons, color=color_incons, linewidth=2, label='不一致解析器对数')
ax1.set_xlabel('运行时长（小时）', fontsize=12)
ax1.set_ylabel('不一致解析器对数', color=color_incons, fontsize=12)
ax1.tick_params(axis='y', labelcolor=color_incons)
ax1.set_xlim(0, 8.2)
ax1.set_ylim(0, max(incons) * 1.12)
ax1.yaxis.set_minor_locator(mticker.AutoMinorLocator())

ax2 = ax1.twinx()
ax2.plot(t_h, corpus, color=color_corpus, linewidth=2, linestyle='--', label='语料库规模')
ax2.set_ylabel('语料库种子数', color=color_corpus, fontsize=12)
ax2.tick_params(axis='y', labelcolor=color_corpus)
ax2.set_ylim(0, max(corpus) * 1.2)

# 饱和点标注
max_incons = max(incons)
sat_t = next(t for t, v in zip(t_h, incons) if v >= max_incons)
ax1.axvline(x=sat_t, color='gray', linestyle=':', linewidth=1.2, alpha=0.7)
ax1.annotate(f'饱和 @{sat_t:.1f}h\nincons={max_incons}',
             xy=(sat_t, max_incons),
             xytext=(sat_t + 0.35, max_incons * 0.88),
             fontsize=9, color='gray',
             arrowprops=dict(arrowstyle='->', color='gray', lw=1))

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc='center right', fontsize=10)
# title removed
ax1.grid(axis='x', linestyle='--', alpha=0.4)
fig.tight_layout()
out1 = os.path.join(OUT_DIR, 'fig4_1_main_experiment.png')
fig.savefig(out1, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out1}')

# ══════════════════════════════════════════════════════════════════════════════
# 图4.2 — 消融实验：不一致对数随时间变化（突出早期收敛差异）
# ══════════════════════════════════════════════════════════════════════════════
configs = [
    (abl_A,  'Config A（完整，α=0.7）',    '#2563EB', '-',   2.2),
    (abl_B0, 'Config B0（基线，α=0.0）',   '#16A34A', '--',  1.8),
    (abl_B,  'Config B（无覆盖信号）',      '#9333EA', '-.',  1.6),
    (abl_C,  'Config C（Argmax-UCB）',     '#EA580C', ':',   1.8),
    (abl_D,  'Config D（纯字节变异）',      '#6B7280', (0,(5,3)), 1.4),
]

fig, ax = plt.subplots(figsize=(9, 5))

for data, label, color, ls, lw in configs:
    xs, ys = extract(data, 'seconds_used', 'incons_count')
    xs = [x / 3600 for x in xs]
    ax.plot(xs, ys, label=label, color=color, linestyle=ls, linewidth=lw)

for data, label, color, ls, lw in configs:
    iters = data['iterations']
    last = iters[-1]
    t_end = last['seconds_used'] / 3600
    v_end = last['incons_count']
    ax.annotate(f'{v_end}', xy=(t_end, v_end),
                xytext=(t_end - 0.15, v_end + 6),
                fontsize=8, color=color, ha='right')

ax.set_xlabel('运行时长（小时）', fontsize=12)
ax.set_ylabel('不一致解析器对数', fontsize=12)
ax.legend(fontsize=9, loc='lower right')
ax.grid(linestyle='--', alpha=0.4)
ax.set_xlim(0, 8.5)
all_vals = []
for data, *_ in configs:
    _, ys = extract(data, 'seconds_used', 'incons_count')
    all_vals.extend(ys)
ax.set_ylim(max(0, min(all_vals) - 50), max(all_vals) + 60)
fig.tight_layout()
out2 = os.path.join(OUT_DIR, 'fig4_2_ablation_incons.png')
fig.savefig(out2, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out2}')

# ── 图4.2b — 不一致对数 vs 处理输入数 ──────────────────────────────────────────
fig, ax = plt.subplots(figsize=(9, 5))

for data, label, color, ls, lw in configs:
    xs, ys = extract(data, 'input_count', 'incons_count')
    ax.plot(xs, ys, label=label, color=color, linestyle=ls, linewidth=lw)
    ax.annotate(f'{ys[-1]}', xy=(xs[-1], ys[-1]),
                xytext=(xs[-1] - 200, ys[-1] + 6),
                fontsize=8, color=color, ha='right')

ax.set_xlabel('处理输入数（个）', fontsize=12)
ax.set_ylabel('不一致解析器对数', fontsize=12)
ax.legend(fontsize=9, loc='lower right')
ax.grid(linestyle='--', alpha=0.4)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x/1000)}K' if x >= 1000 else str(int(x))))
ax.set_xlim(left=0)
all_vals2 = []
for data, *_ in configs:
    _, ys = extract(data, 'input_count', 'incons_count')
    all_vals2.extend(ys)
ax.set_ylim(max(0, min(all_vals2) - 50), max(all_vals2) + 60)
fig.tight_layout()
out2b = os.path.join(OUT_DIR, 'fig4_2b_ablation_incons_by_input.png')
fig.savefig(out2b, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out2b}')

# ══════════════════════════════════════════════════════════════════════════════
# 图4.3 — 消融实验：各配置语料库规模随时间变化
# ══════════════════════════════════════════════════════════════════════════════
fig, ax = plt.subplots(figsize=(9, 5))

for data, label, color, ls, lw in configs:
    xs, ys = extract(data, 'seconds_used', 'corpus_size')
    xs = [x / 3600 for x in xs]
    ax.plot(xs, ys, label=label, color=color, linestyle=ls, linewidth=lw)

ax.set_xlabel('运行时长（小时）', fontsize=12)
ax.set_ylabel('语料库种子数', fontsize=12)
ax.legend(fontsize=9, loc='upper left')
ax.grid(linestyle='--', alpha=0.4)
ax.set_xlim(0, 8.5)
ax.set_ylim(0)
fig.tight_layout()
out3 = os.path.join(OUT_DIR, 'fig4_3_ablation_corpus.png')
fig.savefig(out3, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out3}')

# ── 图4.3b — 语料库规模 vs 处理输入数 ──────────────────────────────────────────
fig, ax = plt.subplots(figsize=(9, 5))

for data, label, color, ls, lw in configs:
    xs, ys = extract(data, 'input_count', 'corpus_size')
    ax.plot(xs, ys, label=label, color=color, linestyle=ls, linewidth=lw)

ax.set_xlabel('处理输入数（个）', fontsize=12)
ax.set_ylabel('语料库种子数', fontsize=12)
ax.legend(fontsize=9, loc='upper left')
ax.grid(linestyle='--', alpha=0.4)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x/1000)}K' if x >= 1000 else str(int(x))))
ax.set_xlim(left=0)
ax.set_ylim(0)
fig.tight_layout()
out3b = os.path.join(OUT_DIR, 'fig4_3b_ablation_corpus_by_input.png')
fig.savefig(out3b, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out3b}')

# ══════════════════════════════════════════════════════════════════════════════
# 图4.4 — 变异算子 UCB Reward 排名（配置A 8小时，Top 15）
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
bars = ax.barh(range(len(names)), rewards, color=colors, edgecolor='white', height=0.65)
ax.set_yticks(range(len(names)))
ax.set_yticklabels(names, fontsize=9)
ax.invert_yaxis()
ax.set_xlabel('UCB Reward', fontsize=12)
# title removed

# 平均线
zip_avg  = np.mean([v[0] for v in zip_muts.values()])
byte_avg = np.mean([v[0] for v in byte_muts.values()])
ax.axvline(x=zip_avg,  color='#2563EB', linestyle=':', linewidth=1, alpha=0.6,
           label=f'ZIP结构化均值 {zip_avg:.4f}')
ax.axvline(x=byte_avg, color='#DC2626', linestyle=':', linewidth=1, alpha=0.6,
           label=f'字节级均值 {byte_avg:.4f}')

from matplotlib.patches import Patch
legend_elements = [
    Patch(facecolor='#2563EB', label='ZIP结构化变异'),
    Patch(facecolor='#DC2626', label='字节级变异'),
    plt.Line2D([0], [0], color='#2563EB', linestyle=':', label=f'ZIP均值 {zip_avg:.4f}'),
    plt.Line2D([0], [0], color='#DC2626', linestyle=':', label=f'字节均值 {byte_avg:.4f}'),
]
ax.legend(handles=legend_elements, fontsize=9, loc='lower right')
ax.grid(axis='x', linestyle='--', alpha=0.4)

for i, (bar, val) in enumerate(zip(bars, rewards)):
    ax.text(val + 0.0003, i, f'{val:.4f}', va='center', fontsize=8, color='#374151')

fig.tight_layout()
out4 = os.path.join(OUT_DIR, 'fig4_4_mutation_reward.png')
fig.savefig(out4, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out4}')

# ══════════════════════════════════════════════════════════════════════════════
# 图4.8 — 消融实验：不一致对数 vs 处理输入数（样本效率全程）
# ══════════════════════════════════════════════════════════════════════════════
fig, ax = plt.subplots(figsize=(9, 5))

for data, label, color, ls, lw in configs:
    xs, ys = extract(data, 'input_count', 'incons_count')
    ax.plot(xs, ys, label=label, color=color, linestyle=ls, linewidth=lw)
    # 终点标注
    ax.annotate(f'{ys[-1]}', xy=(xs[-1], ys[-1]),
                xytext=(xs[-1] - 200, ys[-1] + 5),
                fontsize=8, color=color, ha='right')

ax.set_xlabel('处理输入数（个）', fontsize=12)
ax.set_ylabel('不一致解析器对数', fontsize=12)
# title removed
ax.legend(fontsize=9, loc='lower right')
ax.grid(linestyle='--', alpha=0.4)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x/1000)}K' if x >= 1000 else str(int(x))))

all_vals_input = []
for data, *_ in configs:
    _, ys = extract(data, 'input_count', 'incons_count')
    all_vals_input.extend(ys)
ax.set_ylim(max(0, min(all_vals_input) - 50), max(all_vals_input) + 60)
ax.set_xlim(left=0)
fig.tight_layout()
out8 = os.path.join(OUT_DIR, 'fig4_8_sample_efficiency.png')
fig.savefig(out8, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out8}')

# ══════════════════════════════════════════════════════════════════════════════
# 图4.9 — 消融实验：前5000输入放大（早期样本效率差异）
# ══════════════════════════════════════════════════════════════════════════════
fig, ax = plt.subplots(figsize=(9, 5))

EARLY_CUTOFF = 5000
for data, label, color, ls, lw in configs:
    xs, ys = extract(data, 'input_count', 'incons_count')
    # include first point beyond cutoff for a clean line end
    clip_xs, clip_ys = [], []
    for x, y in zip(xs, ys):
        clip_xs.append(x)
        clip_ys.append(y)
        if x >= EARLY_CUTOFF:
            break
    if clip_xs:
        ax.plot(clip_xs, clip_ys, label=label, color=color, linestyle=ls, linewidth=lw)
        ax.annotate(f'{clip_ys[-1]}', xy=(clip_xs[-1], clip_ys[-1]),
                    xytext=(clip_xs[-1] - 60, clip_ys[-1] + 4),
                    fontsize=8, color=color, ha='right')

ax.set_xlabel('处理输入数（个）', fontsize=12)
ax.set_ylabel('不一致解析器对数', fontsize=12)
# title removed
ax.legend(fontsize=9, loc='lower right')
ax.grid(linestyle='--', alpha=0.4)
ax.set_xlim(0, EARLY_CUTOFF + 100)

early_vals = []
for data, *_ in configs:
    xs, ys = extract(data, 'input_count', 'incons_count')
    for x, y in zip(xs, ys):
        if x <= EARLY_CUTOFF:
            early_vals.append(y)
if early_vals:
    ax.set_ylim(max(0, min(early_vals) - 30), max(early_vals) + 40)
fig.tight_layout()
out9 = os.path.join(OUT_DIR, 'fig4_9_sample_efficiency_early.png')
fig.savefig(out9, bbox_inches='tight')
plt.close(fig)
print(f'saved: {out9}')

print('\n全部图表已生成至:', OUT_DIR)

# ══════════════════════════════════════════════════════════════════════════════
# α-sweep 图组
# ══════════════════════════════════════════════════════════════════════════════
import glob as _glob

ALPHA_FILES = sorted(_glob.glob(os.path.join(STATS_DIR, 'alpha-sweep', 'alpha*.json')))
alpha_data = []
for f in ALPHA_FILES:
    with open(f) as fp:
        d = json.load(fp)
    alpha_data.append((d.get('coverage_ucb_alpha'), d))

# 颜色映射
ALPHA_COLORS = {
    0.1: '#6B7280',
    0.3: '#16A34A',
    0.5: '#2563EB',
    0.7: '#9333EA',
    1.0: '#EA580C',
    1.5: '#DC2626',
}

# ── 图A.1 — 不一致对数 vs 处理输入数 ─────────────────────────────────────────
fig, ax = plt.subplots(figsize=(9, 5))
for alpha, d in alpha_data:
    xs = [it['input_count'] for it in d['iterations']]
    ys = [it['incons_count'] for it in d['iterations']]
    color = ALPHA_COLORS.get(alpha, '#000000')
    ax.plot(xs, ys, label=f'α={alpha}', color=color, linewidth=1.8)
    ax.annotate(f'{ys[-1]}', xy=(xs[-1], ys[-1]),
                xytext=(xs[-1] + 30, ys[-1]),
                fontsize=8, color=color, va='center')

ax.set_xlabel('处理输入数（个）', fontsize=12)
ax.set_ylabel('不一致解析器对数', fontsize=12)
ax.legend(fontsize=9, loc='lower right')
ax.grid(linestyle='--', alpha=0.4)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x/1000)}K' if x >= 1000 else str(int(x))))
all_ys = [it['incons_count'] for _, d in alpha_data for it in d['iterations']]
ax.set_ylim(max(0, min(all_ys) - 50), max(all_ys) + 60)
ax.set_xlim(left=0)
fig.tight_layout()
outA1 = os.path.join(OUT_DIR, 'figA_1_alpha_sweep_incons.png')
fig.savefig(outA1, bbox_inches='tight')
plt.close(fig)
print(f'saved: {outA1}')

# ── 图A.2 — 语料库规模 vs 处理输入数 ─────────────────────────────────────────
fig, ax = plt.subplots(figsize=(9, 5))
for alpha, d in alpha_data:
    xs = [it['input_count'] for it in d['iterations']]
    ys = [it['corpus_size'] for it in d['iterations']]
    color = ALPHA_COLORS.get(alpha, '#000000')
    ax.plot(xs, ys, label=f'α={alpha}', color=color, linewidth=1.8)

ax.set_xlabel('处理输入数（个）', fontsize=12)
ax.set_ylabel('语料库种子数', fontsize=12)
ax.legend(fontsize=9, loc='upper left')
ax.grid(linestyle='--', alpha=0.4)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x/1000)}K' if x >= 1000 else str(int(x))))
ax.set_xlim(left=0)
ax.set_ylim(0)
fig.tight_layout()
outA2 = os.path.join(OUT_DIR, 'figA_2_alpha_sweep_corpus.png')
fig.savefig(outA2, bbox_inches='tight')
plt.close(fig)
print(f'saved: {outA2}')

# ── 图A.3 — 各α最终不一致对数柱状图 ─────────────────────────────────────────
fig, ax = plt.subplots(figsize=(7, 4.5))
alphas = [a for a, _ in alpha_data]
finals = [d['iterations'][-1]['incons_count'] for _, d in alpha_data]
colors = [ALPHA_COLORS.get(a, '#000000') for a in alphas]
bars = ax.bar([str(a) for a in alphas], finals, color=colors, width=0.55, edgecolor='white')
for bar, val in zip(bars, finals):
    ax.text(bar.get_x() + bar.get_width()/2, val + 3, str(val),
            ha='center', va='bottom', fontsize=10, fontweight='bold')
ax.set_xlabel('覆盖率权重 α', fontsize=12)
ax.set_ylabel('不一致解析器对数', fontsize=12)
ax.set_ylim(max(0, min(finals) - 80), max(finals) + 50)
ax.axhline(y=946, color='gray', linestyle=':', linewidth=1.2, alpha=0.7)
ax.text(len(alphas) - 0.5, 947, '上限 946', fontsize=8, color='gray')
ax.grid(axis='y', linestyle='--', alpha=0.4)
fig.tight_layout()
outA3 = os.path.join(OUT_DIR, 'figA_3_alpha_sweep_final.png')
fig.savefig(outA3, bbox_inches='tight')
plt.close(fig)
print(f'saved: {outA3}')
