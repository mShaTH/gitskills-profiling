# Notes: how I did Assignment 1 on GitSkills

These notes show the steps I took for Assignment 1, from the first scripts to the final Colab notebook. For each step I write what I did and why. The numbers and plots are in the report. Here I explain my process and my thinking.

## Using AI

I used an AI assistant (Claude) to help me write the code and the drafts of the report. I ran everything myself, checked the row counts against the paper, and asked questions about each step until I understood it. The notebook was also tested on the sample before I ran it on the full data.

## 1. The task and my plan

- The assignment is to describe a software dataset: the tables (schema), the sizes, plots, traceability (links, languages, change over time), and then write a short report.
- I did it on GitSkills, the dataset of the MSR 2027 Mining Challenge. It has 3.8M SKILL.md files from 282,200 public GitHub repos.
- My plan: write and test everything on the authors' 13,000 skill sample first, because it is small and fast. Then run the same analysis on the full data.
- I also wanted one specific question to answer, not only a list of averages. A specific question says more about the data than general numbers.

## 2. Version 1: scripts on the sample

I loaded the 277 MB sample (SQLite) and wrote the analysis in small steps.

- **Setup check:** the row count (29,786 files) matched the authors' README, so I knew I loaded it correctly.
- **Schema:** I printed the tables and wrote down how they connect and what is missing.
- **`size_metrics.py`:** counts and summary statistics (mean, median, variance, skew, kurtosis) for skill text length and bundled file size, and the vocabulary. I use the median next to the mean because both variables have a long tail.
- **`plots.py`:** histograms with box plots on a log scale (a log scale lets small and huge values fit on one chart), the copies per skill plot, and stars per repo.
- **`traceability.py`:** bundled files by extension, script languages, links in the skill text, natural language, and first commits by month.
- **`queries.sql`:** the SQL I ran in the terminal, saved in one file so anyone can repeat it.

## 3. Choosing the research question

- The question comes from an idea I already had for the MSR 2027 challenge: how widely skills are reused, and how often they come with scripts. The challenge call lists both as suggested directions. My first version of the idea also compared creative skills with software skills, but the data has no skill category, so I could not do that part.
- I narrowed the idea to one comparison I can test with the columns in the data: do skills that come with scripts get copied into more repos than skills without scripts? I wanted one specific context instead of only general averages.
- Why scripts: they are code that can run, so it matters if they are copied around.

## 4. How the comparison code developed (and why)

I changed the comparison step by step. Each change fixed a problem I could see in the previous one.

1. **Count copies per skill, split by scripts or no scripts.** Simplest first version.
2. **Count different repos instead of copies.** One repo can hold the same skill many times. Reuse means the skill appears in different repos.
3. **Leave out collection repos.** A few huge repos hold a big part of all the files. They could drive the whole result, so I checked the result with and without them.
4. **Use nested skills only.** If SKILL.md is at the top of a repo, the folder is probably the whole repo. Its bundled files then inflate the scripts numbers.
5. **Add checks with other cutoffs and with the exact name SKILL.md.** The cutoff for "collection repo" is my choice, so I tried more than one. Some files are named skill.md in lower case, so I also checked only the exact name.
6. **Report odds ratios with 95% intervals, not p-values.** With millions of skills a p-value is always tiny, and skills sit together inside repos. The size and direction of the odds ratio is what matters.
7. **Fix the main comparison before the full run.** A collection repo has 100 or more skill files, and widely spread means 10 or more repos. I decided this before I saw any full-data number, so I could not choose the best-looking result afterwards.

## 5. Version 2: the Colab notebook for the full data

These are the main choices in the notebook:

- **Parameters at the top** (cutoffs, sample size, memory), so I can change them in one place.
- **DuckDB on the Parquet files.** It reads only the columns a query needs, so the data does not have to fit in memory. The text column is left out of the views, so it is only read when a query asks for it.
- **A check against the paper right after loading.** The row counts must match the paper (3,797,117 files, 7,264,865 bundled rows, 282,200 repos). They did.
- **Standard views.** Column types are cast, so the same code works whether a column is a number or true/false.
- **A fixed text sample.** For links, language and vocabulary I take every skill whose content hash falls in 1 of 40 buckets. That gives 47,160 skills, and the same skills every time I rerun. I run language detection on the first 20,000 of them because it is slow.
- **Everything is saved.** The results go to `results.txt`, CSV files and plots, and the last cell zips them.

## 6. What I added to the notebook after the first full run

- **Overlap check for two websites.** w3id.org and edamontology.org had almost the same counts. I added one check to see if the same skills mention both. 324 of the 329 skills that mention w3id.org also mention edamontology.org, so they very likely come from one copied template.
- **Step 7: the copied collection.** In the repos that hold the most widely spread script skills, many repos had similar sizes. I took one security skills repo (790 skills) as the source and counted how many other repos hold the same files. 17 repos hold at least half of it, and 16 of them hold 72% to 99%. I also compared creation dates. 4 of the 17 repos were created before my source, so my source may not be the original.
- **Step 8: commits, authors and links.** I added this after I compared my report with the assignment rubric, which asks for commits, authors and links between things. The cell measures commits per skill file, who the first-commit authors are, whether a SKILL.md names its own bundled files, and what kinds of GitHub links it contains.
- **Figure 6, the odds ratio plot.** The comparison table has six settings and four columns of numbers, which is hard to read. The plot shows every odds ratio with its 95% interval on a log scale. The dashed line at 1 means no difference, and the main comparison is red. It also shows right away that the answer depends on the cutoff. The notebook now draws it from the table, so the numbers are not typed by hand.

## 7. Questions I asked while checking the work

- **Why a 1/40 sample? Why not 25 or 100 buckets?** 40 is a size choice. 1/25 would give about 75,000 skills and 1/100 about 19,000. All of them give almost the same percentages (within about 0.3 to 0.6 points). I picked the size that keeps memory and run time reasonable.
- **Why 95% intervals?** It is the usual convention. 90% would give narrower intervals and 99% wider ones around the same estimate.
- **Why not fit a power law?** A straight line on a log-log plot is not enough proof, because other long-tail shapes look straight too. A proper check needs a fit and a comparison with other shapes. I only claim a long tail.
- **Why does the report mention .claude/skills/?** It is the folder where Claude Code looks for skills in a repo. The dataset calls it the canonical location, and the dataset prefers the copy in that folder as the representative of each skill. So I use all files when I look at locations.
- **What is the has_scripts rule?** The paper does not say how it is decided. I made my own rule from file endings (.py, .sh, .js and so on). The flag is a subset of my rule: 11,507 skills have script files but the flag is 0. I report the flag and say that the rule is undocumented.
- **Where do the widely spread skills come from?** The data has no origin column, so I did not check. A next step is to match them to the public example skills repo using file_sha.

## 8. Checking against the rubric

I read the report against the rubric on the assignment page (schema, size metrics, traceability, explanations, graphics, mining). It changed the report and the notebook like this:

- Schema: I added how the tables connect, and what is missing, including that there are no bug reports, issues or comments.
- Size metrics: I added variance, text sizes per skill, and commits and authors.
- Traceability: I added whether skills name their own files, and the kinds of GitHub links.
- Explanations: I added a table that defines each term (skill, copy, spread, collection repo and so on), because the words could be read in more than one way.
- Graphics: I added the odds ratio plot.

## 9. Findings

- 3,797,117 skill files, 1,877,981 different skills, 282,200 repos. 50.5% of the files are exact copies.
- 79.3% of skills appear only once. 312 repos (0.11%) hold 36.7% of all skill files.
- 11.4% of skills have scripts (10.7% when I leave out root-level skills), 25.9% have reference files.
- Main comparison: outside collection repos, 0.81% of script skills and 0.70% of the other skills are in 10 or more repos. The odds ratio is 1.15 (95% interval 1.08 to 1.23). It is small, and it changes with the cutoff: 1.41 when I leave out only the biggest repos, and 1.08 (interval includes 1) when I leave out repos with 20 or more files.
- About three quarters of the copies of widely spread skills are in collection repos (75.1% without scripts, 73.5% with scripts). So collections do most of the copying.
- The sample gave a different answer than the full data. On the sample, script skills looked about twice as likely to be in 10 or more repos. In a sample, repo sizes are cut down, so a cutoff of "more than 10 sampled files" means a much bigger repo in the full data. That is why I report the full data numbers.
- One security skills collection (790 skills) is copied into 17 other repos. 4 of them are older than my source, so I do not know the original yet.
- At least half of the skills have one commit. The 10 most active first-commit authors hold 8.6% of the skills with history.
- About 64% of skills with bundled files name at least one of them in the SKILL.md. About a third never do.

## 10. Open items

- Find the original source of the security skills collection.
- Match the widely spread skills to the public example skills repo with file_sha.
- Read what the widely spread scripts do (network calls, shell commands).
- Check some language detections by hand.
- Define skill topics, to study one specific area.
- Ask the dataset authors how has_scripts is decided? Should I?
- Fit a power law properly.

## 11. Files in my repo

- `README.md`: short overview.
- `gitskills_full_colab.ipynb`: Results are saved to `results.txt`, CSV files and plots, and zipped at the end.
- `queries.sql`: the SQL used on the sample.
- `size_metrics.py`, `plots.py`, `traceability.py` and their output files: the sample scripts.
- This notes file.