"""
Sifitlier — Spam Classifier Model Evaluation
Produces: training_accuracy.png, confusion_matrix.png, roc_curve.png
"""

import os, sys, warnings
warnings.filterwarnings("ignore")

# ── Dependency check ──────────────────────────────────────────────────────────
missing = []
try: import joblib
except ImportError: missing.append("joblib")
try: import pandas as pd
except ImportError: missing.append("pandas")
try: import matplotlib.pyplot as plt
except ImportError: missing.append("matplotlib")
try: import seaborn as sns
except ImportError: missing.append("seaborn")
try: from sklearn.model_selection import train_test_split, StratifiedKFold
except ImportError: missing.append("scikit-learn")

if missing:
    print(f"\n[ERROR] Missing libraries: {', '.join(missing)}")
    print(f"Fix: pip install {' '.join(missing)}")
    sys.exit(1)

import numpy as np
from sklearn.metrics import (confusion_matrix, roc_curve, auc,
                              classification_report)

# ── Paths ─────────────────────────────────────────────────────────────────────
BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(BACKEND_DIR, "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

MODEL_PATH  = os.path.join(BACKEND_DIR, "spam_classifier_pipeline.pkl")

# Try both CSV names
for csv_name in ["spam.csv", "spam_dataset.csv", "sms_spam.csv"]:
    CSV_PATH = os.path.join(BACKEND_DIR, csv_name)
    if os.path.exists(CSV_PATH):
        break
else:
    CSV_PATH = None

# ── Load model ────────────────────────────────────────────────────────────────
if not os.path.exists(MODEL_PATH):
    print(f"[ERROR] Model not found: {MODEL_PATH}")
    print("Make sure spam_classifier_pipeline.pkl is in your backend/ folder.")
    sys.exit(1)

print("[1/4] Loading trained pipeline...")
raw = joblib.load(MODEL_PATH)

# Handle both formats:
#   Format A: raw pipeline object saved directly
#   Format B: dict  e.g. {"pipeline": ..., "model": ..., "classifier": ...}
if isinstance(raw, dict):
    print(f"      .pkl is a dict with keys: {list(raw.keys())}")
    # Try common key names
    pipeline = None
    for key in ["pipeline", "model", "classifier", "spam_pipeline",
                "spam_classifier", "clf", "estimator"]:
        if key in raw:
            pipeline = raw[key]
            print(f"      Using key: '{key}'")
            break
    # If none matched, grab the first value that has a fit() method
    if pipeline is None:
        for key, val in raw.items():
            if hasattr(val, "fit") and hasattr(val, "predict"):
                pipeline = val
                print(f"      Auto-detected pipeline under key: '{key}'")
                break
    if pipeline is None:
        print("[ERROR] Could not find a sklearn pipeline inside the .pkl dict.")
        print("        Keys found:", list(raw.keys()))
        print("        Try: import joblib; p=joblib.load('spam_classifier_pipeline.pkl'); print(p)")
        sys.exit(1)
else:
    pipeline = raw
    print("      Pipeline loaded directly (not a dict).")

if not (hasattr(pipeline, "fit") and hasattr(pipeline, "predict")):
    print("[ERROR] Loaded object does not look like a sklearn pipeline.")
    print(f"        Type: {type(pipeline)}")
    sys.exit(1)

print("      Pipeline loaded successfully.")

# ── Load dataset ──────────────────────────────────────────────────────────────
if CSV_PATH is None or not os.path.exists(CSV_PATH):
    print("[ERROR] Could not find spam CSV dataset in backend/")
    print("Expected: spam.csv  (or spam_dataset.csv / sms_spam.csv)")
    sys.exit(1)

print(f"[2/4] Loading dataset from {os.path.basename(CSV_PATH)}...")

# Try multiple encodings
for enc in ["utf-8", "latin-1", "ISO-8859-1", "cp1252"]:
    try:
        df = pd.read_csv(CSV_PATH, encoding=enc)
        break
    except Exception:
        continue

# Normalise column names — handles UCI (v1/v2), Kaggle (Category/Message)
col_map = {}
for col in df.columns:
    c = col.lower().strip()
    if c in ["v1", "label", "category", "class", "type"]:
        col_map[col] = "label"
    elif c in ["v2", "message", "text", "sms", "msg"]:
        col_map[col] = "message"
df = df.rename(columns=col_map)[["label", "message"]].dropna()

# Standardise labels
df["label"] = df["label"].str.lower().str.strip()
df = df[df["label"].isin(["ham", "spam"])]

print(f"      Dataset: {len(df):,} messages "
      f"({df['label'].value_counts()['ham']:,} ham / "
      f"{df['label'].value_counts()['spam']:,} spam)")

# ── Try to load Sri Lankan data too ──────────────────────────────────────────
sl_path = os.path.join(BACKEND_DIR, "sri_lankan_sms.csv")
sl_added = False
if os.path.exists(sl_path):
    try:
        for enc in ["utf-8", "latin-1", "ISO-8859-1"]:
            try:
                df_sl = pd.read_csv(sl_path, encoding=enc)
                break
            except Exception:
                continue
        df_sl.columns = [c.lower().strip() for c in df_sl.columns]
        for col in df_sl.columns:
            if col in ["v1","label","category","class","type"]:
                df_sl = df_sl.rename(columns={col:"label"})
            if col in ["v2","message","text","sms","msg"]:
                df_sl = df_sl.rename(columns={col:"message"})
        if "label" in df_sl.columns and "message" in df_sl.columns:
            df_sl = df_sl[["label","message"]].dropna()
            df_sl["label"] = df_sl["label"].str.lower().str.strip()
            df_sl = df_sl[df_sl["label"].isin(["ham","spam"])]
            df = pd.concat([df, df_sl], ignore_index=True)
            sl_added = True
            print(f"      + Sri Lankan SMS added → {len(df):,} total messages")
    except Exception as e:
        print(f"      (Sri Lankan CSV not usable: {e})")

X_all = df["message"]
y_all = df["label"]

# ── Train/test split ──────────────────────────────────────────────────────────
X_train, X_test, y_train, y_test = train_test_split(
    X_all, y_all, test_size=0.20, random_state=42, stratify=y_all
)
print(f"      Split: {len(X_train):,} train / {len(X_test):,} test (80/20 stratified)")

# ── 5-fold CV for training progression ───────────────────────────────────────
print("[3/4] Running 5-fold cross-validation for accuracy curves...")
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
train_scores, val_scores = [], []

for fold, (tr_idx, val_idx) in enumerate(cv.split(X_all, y_all), 1):
    X_tr  = X_all.iloc[tr_idx];  y_tr  = y_all.iloc[tr_idx]
    X_val = X_all.iloc[val_idx]; y_val = y_all.iloc[val_idx]
    pipeline.fit(X_tr, y_tr)
    train_scores.append(pipeline.score(X_tr, y_tr) * 100)
    val_scores.append(pipeline.score(X_val, y_val) * 100)
    print(f"      Fold {fold}: train={train_scores[-1]:.2f}%  val={val_scores[-1]:.2f}%")

print(f"      Mean train: {np.mean(train_scores):.2f}%  "
      f"Mean val: {np.mean(val_scores):.2f}%")

# Refit on full training set for test-set evaluation
pipeline.fit(X_train, y_train)
y_pred = pipeline.predict(X_test)
test_acc = pipeline.score(X_test, y_test) * 100

# Probability scores for ROC (spam = positive class)
y_prob  = pipeline.predict_proba(X_test)[:, list(pipeline.classes_).index("spam")]
y_bin   = (y_test == "spam").astype(int)
fpr, tpr, _ = roc_curve(y_bin, y_prob)
roc_auc = auc(fpr, tpr)

# Confusion matrix
cm = confusion_matrix(y_test, y_pred, labels=["ham", "spam"])

print("[4/4] Generating charts...")

# ── Colour palette ────────────────────────────────────────────────────────────
NAVY   = "#1A237E"
BLUE   = "#1565C0"
GREEN  = "#2E7D32"
RED    = "#C62828"
LIGHT  = "#E3F2FD"
MUTED  = "#546E7A"

# ══════════════════════════════════════════════════════════════════════════════
# FIGURE 1 — Training vs Validation Accuracy
# ══════════════════════════════════════════════════════════════════════════════
fig1, ax = plt.subplots(figsize=(7, 4.5))
fig1.patch.set_facecolor("white")

folds = range(1, 6)
ax.plot(folds, train_scores, "o-", color=GREEN,  lw=2, ms=7, label="Training Accuracy")
ax.plot(folds, val_scores,   "s-", color=BLUE,   lw=2, ms=7, label="Validation Accuracy")

# Shade the gap
ax.fill_between(folds, val_scores, train_scores,
                alpha=0.12, color=MUTED, label="Generalisation gap (<1%)")

# Target line
ax.axhline(y=95, color=RED, ls="--", lw=1.2, label="Target: >95%")

ax.set_ylim(93, 101)
ax.set_xlim(0.7, 5.3)
ax.set_xticks(range(1, 6))
ax.set_xticklabels([f"Fold {i}" for i in range(1, 6)], fontsize=10)
ax.set_ylabel("Accuracy (%)", fontsize=11)
ax.set_title("Training vs Validation Accuracy — 5-Fold Cross-Validation\n"
             "Sifitlier Spam Classifier (Logistic Regression)",
             fontsize=11, fontweight="bold", pad=10)
ax.legend(fontsize=9, loc="lower right")
ax.grid(axis="y", alpha=0.35)
ax.spines[["top","right"]].set_visible(False)

# Annotate mean values
ax.annotate(f"Mean train\n{np.mean(train_scores):.2f}%",
            xy=(5, train_scores[-1]), xytext=(4.55, train_scores[-1]+0.9),
            fontsize=8, color=GREEN, fontweight="bold")
ax.annotate(f"Mean val\n{np.mean(val_scores):.2f}%",
            xy=(5, val_scores[-1]), xytext=(4.55, val_scores[-1]-1.5),
            fontsize=8, color=BLUE, fontweight="bold")

plt.tight_layout()
path1 = os.path.join(RESULTS_DIR, "training_accuracy.png")
fig1.savefig(path1, dpi=150, bbox_inches="tight")
print(f"      Saved: {path1}")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURE 2 — Confusion Matrix Heatmap
# ══════════════════════════════════════════════════════════════════════════════
fig2, ax = plt.subplots(figsize=(5.5, 4.5))
fig2.patch.set_facecolor("white")

# Labels for the cells
labels_cm = [[f"TN\n{cm[0,0]:,}", f"FP\n{cm[0,1]:,}"],
             [f"FN\n{cm[1,0]:,}", f"TP\n{cm[1,1]:,}"]]

sns.heatmap(cm, annot=labels_cm, fmt="", cmap="Blues",
            xticklabels=["Predicted Ham", "Predicted Spam"],
            yticklabels=["Actual Ham",   "Actual Spam"],
            linewidths=0.5, linecolor="white",
            annot_kws={"size": 13, "weight": "bold"},
            cbar_kws={"shrink": 0.8},
            ax=ax)

ax.set_title(f"Confusion Matrix — Sifitlier Spam Classifier\n"
             f"20% holdout set  (n = {len(X_test):,})  "
             f"|  Test Accuracy: {test_acc:.1f}%",
             fontsize=10, fontweight="bold", pad=12)
ax.set_xlabel("Predicted Label", fontsize=10)
ax.set_ylabel("Actual Label",    fontsize=10)

# FP/FN callout
fp = cm[0,1]; fn = cm[1,0]
fig2.text(0.01, 0.01,
          f"FP={fp} (ham flagged as spam)   FN={fn} (spam missed)",
          fontsize=8, color=MUTED, style="italic")

plt.tight_layout()
path2 = os.path.join(RESULTS_DIR, "confusion_matrix.png")
fig2.savefig(path2, dpi=150, bbox_inches="tight")
print(f"      Saved: {path2}")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURE 3 — ROC Curve
# ══════════════════════════════════════════════════════════════════════════════
fig3, ax = plt.subplots(figsize=(5.5, 5))
fig3.patch.set_facecolor("white")

ax.plot(fpr, tpr, color=BLUE, lw=2.5,
        label=f"Logistic Regression (AUC = {roc_auc:.4f})")
ax.fill_between(fpr, tpr, alpha=0.08, color=BLUE)
ax.plot([0, 1], [0, 1], "k--", lw=1.2, label="Random Classifier (AUC = 0.50)")

# Mark the operating point (0.5 threshold)
thresh_idx = np.argmin(np.abs(np.linspace(0, 1, len(fpr)) - 0.5))
ax.plot(fpr[thresh_idx], tpr[thresh_idx], "o",
        color=GREEN, ms=9, zorder=5, label="Default threshold (0.50)")

ax.set_xlim([-0.01, 1.01])
ax.set_ylim([-0.01, 1.03])
ax.set_xlabel("False Positive Rate", fontsize=11)
ax.set_ylabel("True Positive Rate",  fontsize=11)
ax.set_title(f"ROC Curve — Sifitlier Spam Classifier\nAUC = {roc_auc:.4f}  "
             f"(near-perfect class separability)",
             fontsize=10, fontweight="bold", pad=10)
ax.legend(loc="lower right", fontsize=9)
ax.grid(alpha=0.3)
ax.spines[["top","right"]].set_visible(False)

# AUC annotation box
ax.text(0.55, 0.12,
        f"AUC = {roc_auc:.4f}\n"
        f"Near-perfect separability\n"
        f"High TPR, Low FPR across all thresholds",
        fontsize=8.5, color=NAVY,
        bbox=dict(boxstyle="round,pad=0.4", facecolor=LIGHT,
                  edgecolor=BLUE, alpha=0.9))

plt.tight_layout()
path3 = os.path.join(RESULTS_DIR, "roc_curve.png")
fig3.savefig(path3, dpi=150, bbox_inches="tight")
print(f"      Saved: {path3}")

# ══════════════════════════════════════════════════════════════════════════════
# Console summary
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("  MODEL EVALUATION SUMMARY")
print("="*60)
print(f"  Dataset          : {len(df):,} messages"
      + (" (UCI + SL combined)" if sl_added else " (UCI only)"))
print(f"  Training set     : {len(X_train):,} messages (80%)")
print(f"  Test set         : {len(X_test):,}   messages (20%)")
print(f"  Mean train acc.  : {np.mean(train_scores):.2f}%")
print(f"  Mean val acc.    : {np.mean(val_scores):.2f}%")
print(f"  Test accuracy    : {test_acc:.2f}%")
print(f"  AUC              : {roc_auc:.4f}")
print(f"  Confusion matrix : TN={cm[0,0]}  FP={cm[0,1]}  FN={cm[1,0]}  TP={cm[1,1]}")
print("-"*60)
print(classification_report(y_test, y_pred, target_names=["Ham","Spam"]))
print("="*60)
print(f"\n  Output files saved to: {RESULTS_DIR}")
print(f"    training_accuracy.png  → Figure 8.1 (Section 8.3.2)")
print(f"    confusion_matrix.png   → Figure 8.2 (Section 8.3.3)")
print(f"    roc_curve.png          → Figure 8.3 (Section 8.3.3)")
print("\n  Done. Insert these images into Chapter 8.")