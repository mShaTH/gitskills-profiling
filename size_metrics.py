import sqlite3, re, collections
import pandas as pd

con = sqlite3.connect("agent_skills_sample.db")

def summarize(name, s):
    print(f"\n{name}")
    print(s.describe())
    print("variance", s.var(), "skew", s.skew(), "kurtosis", s.kurt())

# size of each distinct skill (characters of instructions)
body = pd.read_sql("SELECT body_chars FROM artifacts WHERE dedup_primary=1", con).body_chars
summarize("body_chars, distinct skills", body)

# size of bundled files (bytes)
sib = pd.read_sql("SELECT entry_size FROM artifact_siblings WHERE entry_type='file'", con).entry_size
summarize("entry_size, bundled files", sib)

# vocabulary and lines (token = lowercased \w+ match)
vocab, lines = collections.Counter(), 0
for (c,) in con.execute("SELECT content FROM artifacts WHERE dedup_primary=1 AND content IS NOT NULL"):
    vocab.update(re.findall(r"\w+", c.lower()))
    lines += c.count("\n") + 1
print("\nunique tokens", len(vocab), "| total tokens", sum(vocab.values()), "| total lines", lines)