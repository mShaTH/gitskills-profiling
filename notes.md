# GitSkills profiling notes (Assignment 1 for Abram)

Working log. All numbers are from the 13,000-skill sample unless it says "full". The full-data run is a Colab notebook (`gitskills_full_colab.ipynb`), results go in the last section.

## What the data is
- A skill is a folder with a `SKILL.md` file: written instructions that tell an AI coding agent how to do a task. It can also bundle scripts and reference files.
- GitSkills = every SKILL.md file found on public GitHub in July 2026: 3,797,117 files, 282,200 repos, 1,877,981 distinct contents.
- "Used by" in this data means "copied into a repo". There is no usage data, so I can't say how often an agent actually runs a skill.
- No package manager, so skills spread by copying folders.

## Step 1: Setup
- Cloned the sample from GitHub, unzipped to SQLite (277 MB). Same schema as the full dataset (about 41 GB SQLite, 13 GB Parquet).
- Sanity check: 29,786 rows in `artifacts`, same as the README.
- Approach: build everything on the sample, rerun on the full data.

## Step 2: Schema
- 4 tables: `artifacts` (one row per SKILL.md file occurrence), `artifact_siblings` (files bundled with a skill), `repos` (repo metadata), `mining_runs` (7 collection runs).
- Only one copy per distinct content (`dedup_primary = 1`, the representative) has full text, front matter and folder info. The other copies only have location and hash.
- The representative is chosen preferring `.claude/skills/`, and the paper says it is not assumed to be the original source. So location of distinct skills is biased, use all occurrences for location mix.
- Folder info and commit history describe only the representative's repo. Other copies may differ (paper says this too).
- Commit history exists only for standard locations plus a size-stratified sample (3,010 rows in the sample, 458,548 in full).
- Not in the data: skill domain or category, who copied from whom, whether agents use a skill, popularity per skill (stars are per repo), human vs AI authorship, what scripts do.
- Easy to answer: copy counts, sizes, locations, bundling. Hard to answer: causes, quality, real usage.
- Paper facts: folder listings are missing for 1,544 representatives (10 in the sample, same rate). The filename search also returns case variants like `skill.md` (54,289 files, 1.4%), kept in the data, so I can filter to exact `SKILL.md`. The preprint does not document the rule behind `has_scripts`.

## Step 3: Size metrics (sample)
- 29,786 file occurrences, 13,000 distinct contents, 11,841 repos, 10,786 owners.
- Location (all occurrences): 2,365 canonical, 14,882 skills-dir, 12,539 other. Full is 9.8% / 55.4% / 34.8%, so the sample leans more toward "other".
- Front matter valid: 11,291 of 13,000 distinct skills (86.9%). Full is 86.6%.
- Bundle scripts: 1,326 (10.2%). Excluding root-level SKILL.md: 1,217 of 12,834 (9.5%). Bundle reference files: 3,057 (23.5%).
- Root-level SKILL.md (at the repo root): 156 skills (1.2%), average 70 to 79 siblings, 70% flagged with scripts. The folder is probably the whole repo, so these inflate bundling numbers.
- Bundled files: 39,046 files and 8,783 folders, about 1.12 GB. 22,278 files (57%) have stored text.
- 3,010 skills have commit history, 2,434 distinct anonymised authors (includes bots).
- Skill body size: mean 6,816 chars, median 4,493, std 8,466, max 211,535, skew 5.3, kurtosis 61. Heavy right tail, so I report the median.
- Bundled file size: mean 28.6 KB, median 3.6 KB, max 50.7 MB, skew 61. A few huge files make up most of the 1.12 GB.
- Vocabulary (13,000 skills): 414,477 unique tokens, 12.3M total, 2.4M lines. Token = lowercased `\w+` match. Inflated by code, identifiers and non-English text. Vocab grows with sample size, so only compare like with like.
- Oddities: the one zero-length body is a test skill (`mock-skill`). 180 bundled files are 0 bytes. The biggest bundled files are binaries (.deb, .zip, .caffemodel, .pptx, .apk), so "bundled" does not mean scripts only, and binaries dominate total size.

## Step 4: Distributions (sample)
- 74.0% of distinct contents appear exactly once, 78% sit in exactly one repo. Max 188 copies, max 132 repos.
- Top 1% of contents hold 22.3% of all occurrences.
- 56.4% of occurrences are copies in the sample. Full is 50.5%, so the sample has more duplication (2.29 vs 2.02 occurrences per content). Singletons in the full data are roughly 80% (eyeballed from the authors' plot, not exact). Same shapes, different proportions, so report numbers from the full data.
- Long tail plus a small head of heavily copied skills. Not claiming a power law without fitting and testing one.
- Body size: one hump around 3k to 10k characters, thin tail of near-empty skills. Bundled size: peak around 3 to 5 KB, long right tail.
- Stars: 54% of repos have 0 stars, median 3 among starred, tail up to 10^5. Sample repos are biased toward repos that hold sampled skills.
- Repo size (sample counts, thinned): 181 repos (1.5%) hold 45% of occurrences, 102 repos with 21+ skills hold 41%. Single-skill repos are 79% of repos but 31% of occurrences. Recompute on full data.

## Step 5: Traceability (sample)
- Bundled files: half are `.md` (19,251). Script files: Python 4,261, JavaScript 1,463, TypeScript 930, Shell 915, Go 668.
- 1,398 skills have at least one script-extension file (10.8%). 1,214 of them use one script language, 184 use two or more.
- Why the other 43% of bundled files have no stored text is unknown (`skipped_reason` is empty).
- URLs: 3,573 of 13,000 skills (27.5%) contain a URL, 18,561 in total, github.com in 1,300. Many top domains are placeholders (example.com, localhost, "..."), so the cleaned count goes in the full run.
- Language: 90.4% English, at least 9.6% other (Chinese 216, German 179, Japanese 148, Portuguese 116). Detection is noisy on short or mixed text. Check about 20 by hand before reporting.
- Over time: 2 of 2,955 first commits predate Oct 2025. Monthly first commits grow from 12 (Oct 2025) to 629 (Jun 2026). July is partial. History sample only, and a file's first commit can date a rename.

## Step 6: Do skills that bundle scripts spread differently? (sample)

### has_scripts flag vs file extensions
- All 1,326 flagged skills have script-extension files in my list. 71 more skills have such files but flag 0 (mostly `.mjs` and whole Go projects). So the flag is a bit narrower than my list. The rule is not documented in the preprint, could ask the authors.

### Results
Spread = number of distinct repos holding the exact same content. "Wide" = 10+ repos. OR = odds ratio for script skills vs non-script skills (above 1 means scripts spread more). Nested = not root-level.

| setting | no scripts / scripts | in 2+ repos | OR (95% CI) | in 10+ repos | OR (95% CI) |
|---|---|---|---|---|---|
| all repos, all skills | 11,664 / 1,326 | 22.5% vs 16.9% | 0.70 (0.60-0.81) | 1.3% vs 2.6% | 2.01 (1.39-2.92) |
| all repos, nested | 11,617 / 1,217 | 22.6% vs 17.9% | 0.75 (0.64-0.87) | 1.3% vs 2.9% | 2.19 (1.51-3.18) |
| exclude repos with 11+ sampled files, nested | 8,495 / 1,059 | 11.0% vs 13.3% | 1.24 (1.03-1.51) | 1.4% vs 2.8% | 2.05 (1.37-3.08) |
| exclude 6+, nested | 8,046 / 977 | 10.6% vs 11.9% | 1.13 (0.92-1.39) | 1.1% vs 1.9% | 1.79 (1.09-2.96) |
| exclude 21+, nested | 8,778 / 1,078 | 11.3% vs 13.5% | 1.23 (1.02-1.48) | 1.4% vs 2.8% | 1.97 (1.31-2.94) |
| exclude 11+, exact SKILL.md name only | 8,392 / 1,037 | 11.0% vs 13.5% | 1.27 (1.05-1.53) | 1.4% vs 2.9% | 2.07 (1.38-3.11) |

Reading:
- Robust: skills that bundle scripts are about twice as likely to be among the widely spread ones (OR 1.8 to 2.2 in every setting).
- Not robust: whether script skills spread MORE or LESS overall. It flips from OR 0.7 (all repos) to 1.2 (collection repos excluded), and at the 6+ cutoff the gap is not significant (p = 0.23). Exploratory only.
- The first "scripts spread less" result was driven by big collection repos copying non-script skills a lot.
- Earlier versions of these numbers (8.0% vs 11.6%, p about 6e-5) came from a query with a denominator problem and are superseded by the table above.

### Who are the widely spread script skills? (35 in the sample)
- About 10 cybersecurity skills, about 7 scientific or bio skills, and a few that look like Anthropic example skills (docx, pdf, webapp-testing, need to verify).
- One repo holds 17 of the 35 (`gabrielmoreira/agent-skills-mirror`), others hold 13 and 12 (`my-claude`, `claude-skill-registry-data`). Many hold exactly 8. Names suggest mirrors and collections, but I have only read names. Open them to confirm.
- Collection test (repos with 11+ sampled files): 28% of the copies of widely spread script skills sit in collection repos, against 44% for widely spread non-script skills. So collections do NOT explain script-skill spread better than non-script spread. My earlier guess that script skills spread through collections is only weakly supported.
- 26 of the 35 sit in the canonical location, but the representative rule prefers `.claude/skills/`, so this means little.

## Caveats (go in the report)
- Sample only, repo sizes in the sample are thinned (about 0.7% of distinct contents). Rerun on full data.
- Association only, no causal claim. Domain (lots of security skills) and collection repos are confounders.
- Copies are exact-hash only, so lightly edited copies are missed.
- Folder info (`has_scripts`, siblings) comes from the representative's repo only.
- p-values assume independent skills, but skills cluster inside repos, so they are optimistic. With millions of rows almost everything is "significant", so I report odds ratios and whether the direction holds across settings.
- I looked at several cuts of the data, so only the main comparison (below) is a planned test. The rest is exploratory.
- Language detection is noisy on short text. `has_scripts` rule is undocumented. Case variants like `skill.md` are 1.4% of files.

## Full-data run (Colab)
Notebook: `gitskills_full_colab.ipynb`. It downloads the Parquet mirror to Colab, runs DuckDB over it, and saves results.txt, CSVs and plots.

Decided before seeing any full-data number:
- Collection repo = 100+ skill files in the repo. Sensitivity at 20 and 1000.
- Wide = same content in 10+ repos.
- Main comparison: nested skills, spread counted outside collection repos, scripts vs no scripts, outcome = in 10+ repos (2+ repos is secondary).
- Text analyses (URLs, language, vocab) use a deterministic 1/40 sample of distinct skills, language on the first 20,000 of those.

TODO after the run (paste from results.txt):
- [ ] Row counts match the paper (3,797,117 / 7,264,865 / 282,200 / 7)
- [ ] Reuse concentration: % copies (expect 50.5), singletons, top 1% share, bucket table vs authors' plot
- [ ] Summary stats table (body size, bundled size)
- [ ] Script share overall and nested, flag vs extension table
- [ ] Main comparison table, all settings
- [ ] Widely spread script skills, which repos hold them, % of copies in collection repos
- [ ] Cleaned URL domains, language mix (spot-checked by hand), over-time plot
- [ ] Open the top collection repos and a few widely spread script skills, read what the scripts do

## Questions for Abram
- Is "scripts and how widely skills spread" the slice you want me to focus on?
- Do you know the rule behind `has_scripts`, or should I ask the dataset authors?
- When do you want the PDF report, and in what format?