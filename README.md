# GitSkills profiling (sample)

Exploratory profiling of the GitSkills dataset (agent skills mined from GitHub, MSR 2027 Mining Challenge). This follows the structure of Abram Hindle's CMPUT 660 Assignment 1, adapted to the new dataset. Everything here was built on the 13,000-skill sample. The rerun on the full dataset is still to do.

## Data

Destefanis, Graziotin, Vaccargiu, Ortu. "GitSkills: A Dataset of Agent Skills on GitHub." MSR 2027 Mining Challenge. arXiv:2608.10906.

- Sample: https://github.com/giuseppedestefanis/gitskills-sample
- Full dataset: Zenodo DOI 10.5281/zenodo.21875637, Parquet mirror at https://huggingface.co/datasets/mvaccargiu/gitskills
- Dataset metadata is CC-BY-4.0. File contents keep the license of their origin repository.

The sample database (277 MB) is not included here. To reproduce: clone the sample repo, unzip `agent_skills_sample.zip`, and put `agent_skills_sample.db` in this folder.

## Contents

| File | What it does |
|---|---|
| `queries.sql` | All SQL used (counts, scripts vs spread, robustness checks) |
| `size_metrics.py` | Step 3: size and summary statistics, vocabulary |
| `plots.py` | Step 4: distributions and plots into `my_plots/` |
| `traceability.py` | Step 5: bundled files, URLs, languages, time |
| `step*_output.txt` | Raw output of each script |
| `notes.md` | Working log of results and caveats |

Run order: `python size_metrics.py`, `python plots.py`, `python traceability.py` (needs pandas, matplotlib, langdetect), then the queries in `queries.sql`.

## Results so far (sample only)

- 74% of distinct skill contents appear exactly once. About 1.5% of repos hold 45% of all occurrences.
- About 10% of distinct skills bundle scripts (`has_scripts`), 9.5% when root-level skills are excluded.
- Skills that bundle scripts are about twice as likely to be among the widely spread ones (10+ repos): 1.4% vs 2.8% when large collection repos are excluded (Fisher p about 0.001). This is an association, not a causal claim.
- The broader "spreads more or less overall" comparison changes direction depending on whether large collection repos are included, so it is treated as exploratory.

## Limitations

- Sample only, repo sizes in the sample are thinned. Numbers to be rerun on the full data.
- Copies are exact-hash copies only, lightly edited copies are not counted.
- Folder composition (`has_scripts`, siblings) describes the representative copy's repository only.
- The `has_scripts` flag is narrower than a file-extension definition of script (71 skills in the sample differ).
- Language detection on short or mixed text is noisy.
- The "large repo" cutoff (more than 10 sampled occurrences) is arbitrary, sensitivity check pending.
