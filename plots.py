import sqlite3, os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

os.makedirs("my_plots", exist_ok=True)
con = sqlite3.connect("agent_skills_sample.db")

def hist_log(s, title, xlabel, fname):
    s = s[s > 0]
    bins = np.logspace(np.log10(s.min()), np.log10(s.max()), 50)
    fig, (a, b) = plt.subplots(1, 2, figsize=(11, 4), gridspec_kw={"width_ratios": [3, 1]})
    a.hist(s, bins=bins); a.set_xscale("log"); a.set_xlabel(xlabel); a.set_ylabel("count"); a.set_title(title)
    b.boxplot(np.log10(s)); b.set_ylabel("log10(" + xlabel + ")"); b.set_xticks([])
    fig.tight_layout(); fig.savefig("my_plots/" + fname, dpi=150); plt.close(fig)

# 1. copies per distinct content (reuse concentration)
copies = pd.read_sql("SELECT file_sha, COUNT(*) AS copies FROM artifacts GROUP BY file_sha", con).copies
print(copies.describe())
print("singletons %:", round((copies == 1).mean() * 100, 1))
print("max copies:", copies.max())
top1 = copies.sort_values(ascending=False).head(int(len(copies) * 0.01)).sum()
print("share of all occurrences held by top 1% of contents %:", round(top1 / copies.sum() * 100, 1))
vc = copies.value_counts().sort_index()
plt.figure(figsize=(6, 4)); plt.loglog(vc.index, vc.values, "o")
plt.xlabel("copies of the same content"); plt.ylabel("number of distinct contents")
plt.title("Copies per distinct content"); plt.tight_layout(); plt.savefig("my_plots/copies.png", dpi=150); plt.close()

# 2. skill body size
body = pd.read_sql("SELECT body_chars FROM artifacts WHERE dedup_primary=1", con).body_chars
print("zero-length bodies:", (body == 0).sum())
hist_log(body, "Skill body length (distinct skills)", "body_chars", "body_size.png")

# 3. bundled file size
sib = pd.read_sql("SELECT entry_size FROM artifact_siblings WHERE entry_type='file'", con).entry_size
print("zero-byte bundled files:", (sib == 0).sum())
hist_log(sib, "Bundled file size", "entry_size (bytes)", "bundled_size.png")

# 4. repo stars
stars = pd.read_sql("SELECT stars FROM repos WHERE metadata_fetched=1", con).stars
print("repos with 0 stars %:", round((stars == 0).mean() * 100, 1))
hist_log(stars, "Stars per repo (repos with 1+ stars)", "stars", "stars.png")