# GitSkills profiling

Exploratory profiling of the GitSkills dataset (agent skills mined from GitHub, MSR 2027 Mining Challenge). This follows the structure of Abram Hindle's CMPUT 660 Assignment 1, adapted to the new dataset. The scripts here were built on the 13,000-skill sample. The full-data rerun is a Google Colab notebook (`gitskills_full_colab.ipynb`) that downloads the Parquet mirror and runs the same analyses with DuckDB.

## Data

Destefanis, Graziotin, Vaccargiu, Ortu. "GitSkills: A Dataset of Agent Skills on GitHub." MSR 2027 Mining Challenge. arXiv:2608.10906.

- Sample: https://github.com/giuseppedestefanis/gitskills-sample
- Full dataset: Zenodo DOI 10.5281/zenodo.21875637, Parquet mirror at https://huggingface.co/datasets/mvaccargiu/gitskills
- Dataset metadata is CC-BY-4.0. File contents keep the license of their origin repository.

The sample database (277 MB) is not included here. To reproduce: clone the sample repo, unzip `agent_skills_sample.zip`, and put `agent_skills_sample.db` in this folder.

## Contents

| File | What it does |
|---|---|
| `gitskills_full_colab.ipynb` | Full-data run on Google Colab (Steps 3 to 6), writes results.txt, CSVs and plots |
| `queries.sql` | All SQL used (counts, scripts vs spread, robustness checks) |
| `size_metrics.py` | Step 3: size and summary statistics, vocabulary |
| `plots.py` | Step 4: distributions and plots into `my_plots/` |
| `traceability.py` | Step 5: bundled files, URLs, languages, time |
| `step*_output.txt` | Raw output of each script |
| `notes.md` | Working log of results and caveats |

Run order: `python size_metrics.py`, `python plots.py`, `python traceability.py` (needs pandas, matplotlib, langdetect), then the queries in `queries.sql`.

## Results (full data, Colab run)

- 3,797,117 skill files, 1,877,981 distinct contents, 282,200 repos. 79.3% of distinct contents appear once, 312 repos hold 36.7% of all skill files.
- 11.4% of skills bundle scripts (10.7% excluding root-level skills), 25.9% bundle reference files.
- Skills that bundle scripts are only weakly more likely to be widely spread (10+ repos): 0.81% vs 0.70% outside collection repos, odds ratio 1.15 (95% CI 1.08 to 1.23). The effect is not stable across collection-repo cutoffs.
- Collection repos (100+ skill files) hold about three quarters of the copies of widely spread skills, with or without scripts.
- An earlier sample-only run suggested an odds ratio near 2. The full data does not support that. See notes.md.

## Limitations

- The write-up and plots use the full data. The scripts in this repo run on the 13,000-skill sample, the Colab notebook runs on everything.
- Copies are exact-hash copies only, lightly edited copies are not counted.
- Folder composition (`has_scripts`, siblings) describes the representative copy's repository only.
- The `has_scripts` flag is narrower than a file-extension definition of script (71 skills in the sample differ).
- Language detection on short or mixed text is noisy.
- The collection-repo cutoff is arbitrary, and the result depends on it (see notes.md).