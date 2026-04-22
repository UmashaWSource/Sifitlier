"""
generate_latency_chart.py
Run from: backend/
Output:  results/latency_chart.png
"""

import os, matplotlib.pyplot as plt, numpy as np

RESULTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

# ── Data from Table 8.12 ──────────────────────────────────────────────────────
labels  = ["Local Dart\n(On-Device)", "Cloud FastAPI\n(Network)"]
values  = [0.08, 150]
colors  = ["#2E7D32", "#C62828"]

fig, ax = plt.subplots(figsize=(7, 5))
fig.patch.set_facecolor("#0D1B2A")
ax.set_facecolor("#1A2744")

bars = ax.bar(labels, values, color=colors, width=0.45,
              edgecolor="white", linewidth=0.6)

# Log scale
ax.set_yscale("log")
ax.set_ylim(0.01, 2000)
ax.set_ylabel("Inference Latency (ms) — Log Scale",
              fontsize=11, color="white")
ax.set_title("On-Device vs Cloud Inference Latency\n1,849× Speedup  |  O3 PASS: <5 ms",
             fontsize=12, fontweight="bold", color="white", pad=12)

# Target line
ax.axhline(y=5, color="#FFD600", linestyle="--", linewidth=1.8,
           label="Target: <5 ms")
ax.legend(fontsize=10, facecolor="#1A2744", labelcolor="white")

# Axis styling
ax.tick_params(colors="white")
ax.yaxis.label.set_color("white")
for spine in ax.spines.values():
    spine.set_edgecolor("#334466")
ax.grid(axis="y", alpha=0.2, color="white")

# Value labels on bars
for bar, val, label in zip(bars, values, ["0.08 ms\n✓ PASS", "~150 ms\n(network)"]):
    ax.text(bar.get_x() + bar.get_width() / 2,
            val * 2.5, label,
            ha="center", va="bottom",
            fontsize=11, fontweight="bold",
            color="white")

# Speedup annotation
ax.annotate("1,849× faster",
            xy=(0, 0.08), xytext=(0.55, 20),
            fontsize=9, color="#FFD600", fontweight="bold",
            arrowprops=dict(arrowstyle="->", color="#FFD600", lw=1.4))

plt.tight_layout()
out = os.path.join(RESULTS_DIR, "latency_chart.png")
fig.savefig(out, dpi=150, bbox_inches="tight", facecolor=fig.get_facecolor())
print(f"Saved: {out}")
plt.show()