import sqlite3, re, collections
from urllib.parse import urlparse
import pandas as pd
import matplotlib.pyplot as plt
from langdetect import detect, DetectorFactory
DetectorFactory.seed = 0

con = sqlite3.connect("agent_skills_sample.db")

# A. bundled files: text or not, and what they are
print(pd.read_sql("SELECT COALESCE(skipped_reason,'(none)') AS skipped_reason, COUNT(*) AS n FROM artifact_siblings WHERE entry_type='file' GROUP BY 1 ORDER BY n DESC", con))
print("bundled files with text:", con.execute("SELECT COUNT(*) FROM artifact_siblings WHERE entry_type='file' AND content IS NOT NULL").fetchone()[0])
sib = pd.read_sql("SELECT repo_full_name, artifact_path, entry_name, entry_size FROM artifact_siblings WHERE entry_type='file'", con)
sib["ext"] = sib.entry_name.str.extract(r"(\.[^./]+)$")[0].str.lower().fillna("(none)")
print(sib.ext.value_counts().head(25))

# B. computer languages among bundled scripts
lang_map = {".py":"Python",".sh":"Shell",".bash":"Shell",".js":"JavaScript",".mjs":"JavaScript",".cjs":"JavaScript",
            ".ts":"TypeScript",".rb":"Ruby",".go":"Go",".rs":"Rust",".ps1":"PowerShell",".bat":"Batch",
            ".java":"Java",".php":"PHP",".pl":"Perl",".lua":"Lua"}
sib["plang"] = sib.ext.map(lang_map)
per_skill = sib.dropna(subset=["plang"]).groupby(["repo_full_name","artifact_path"]).plang.nunique()
print("\nskills with at least one script file:", len(per_skill))
print("number of script languages per skill:\n", per_skill.value_counts().sort_index())
print(sib.plang.value_counts())

# C. URLs in skill text
skills = pd.read_sql("SELECT file_sha, content FROM artifacts WHERE dedup_primary=1 AND content IS NOT NULL", con)
url_re = re.compile(r"https?://[^\s)>\]\"'`]+")
n_with, total, dom = 0, 0, collections.Counter()
for c in skills.content:
    urls = url_re.findall(c)
    n_with += bool(urls); total += len(urls)
    hosts = set()
    for u in urls:
        try: hosts.add(urlparse(u).netloc.lower())
        except ValueError: pass
    dom.update(hosts)
print(f"\nskills with 1+ URL: {n_with} of {len(skills)} | total URLs: {total}")
print("top domains (number of skills mentioning each):")
for d, n in dom.most_common(20): print(" ", n, d)

# D. natural language of skill text (code blocks stripped)
def lang(t):
    t = re.sub(r"```.*?```", " ", t, flags=re.S)
    try: return detect(t[:2000])
    except Exception: return "unknown"
skills["lang"] = skills.content.map(lang)
print("\nnatural language of skills:\n", skills.lang.value_counts().head(15))

# E. over time (history sample only, exact SKILL.md name)
h = pd.read_sql("SELECT substr(first_commit_at,1,7) AS ym FROM artifacts WHERE history_fetched=1 AND first_commit_at IS NOT NULL AND filename='SKILL.md'", con)
print("\nfirst commits before 2025-10 (before the spec):", (h.ym < "2025-10").sum(), "of", len(h))
m = h[h.ym >= "2025-09"].ym.value_counts().sort_index()
print(m)
plt.figure(figsize=(8, 4)); plt.bar(m.index, m.values); plt.xticks(rotation=60)
plt.ylabel("skills (history sample)"); plt.title("First commit of SKILL.md files by month")
plt.tight_layout(); plt.savefig("my_plots/over_time.png", dpi=150)