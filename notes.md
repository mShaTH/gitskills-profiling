# GitSkills Assignment 1 notes

## Step 1: Setup
- Cloned the GitSkills sample from GitHub and unzipped it into a SQLite db (277 MB).
- It has the same schema as the full dataset (about 41 GB). I build everything on the sample, then rerun on the full data at the end.
- Sanity check passed: 29,786 rows in artifacts, same as the README.

## Step 2: Schema
- 4 tables: artifacts (one row per SKILL.md file occurrence), artifact_siblings (scripts and reference files bundled with a skill), repos (repo metadata), mining_runs (how the data was collected, 7 runs).
- Only one copy of each distinct content (dedup_primary = 1) has the full text, front matter and folder info. The other copies only have location and hash.
- Commit history exists only for a subset (3,010 rows in the sample).
- Not in the data: skill domain or category, who copied from whom, whether agents ever use a skill, popularity per skill, human vs AI authorship, what the scripts actually do.
- Easy to answer: copy counts, sizes, locations, bundling. Hard to answer: causes, quality, real usage.
- Noticed: some skills have no valid front matter, and skills come in many human languages and domains (legal, crypto bots, blog writing).

## Step 3: Size metrics (sample numbers, redo on full data)
- 29,786 file occurrences, 13,000 distinct contents, 11,841 repos, 10,786 owners.
- Location: 2,365 canonical, 14,882 skills-dir, 12,539 other. Mix differs a bit from the full dataset, so don't trust the sample for this.
- 11,291 of 13,000 distinct skills (86.9%) have valid front matter.
- 1,326 skills (10.2%) bundle scripts, 3,057 (23.5%) bundle reference files.
- 39,046 bundled files, 8,783 folders, about 1.12 GB total.
- 3,010 skills have commit history, 2,434 distinct anonymised authors (includes bots).
- Body size, bundled file size, vocab, lines: (paste from step3_output.txt)
- Token = lowercased \w+ match. Vocab counted over distinct skills only.

## Things to check on the full data
- Does the location mix change?
- Is the mean file size dominated by a few huge files?

## Step 3 results
- Skill body size: mean 6,816 chars, median 4,493, max 211,535. Heavy right tail (skew 5.3), so I report the median.
- Bundled files: mean 28.6 KB but median only 3.6 KB, max 50.7 MB. A few huge files make up most of the 1.12 GB.
- Vocab: 414,477 unique tokens, 12.3M total, about 947 tokens and 184 lines per skill. Inflated by code, identifiers and non-English text.
- Checked: skills with zero-length body (what are they?) and the 50 MB file (what is it?)

## Step 4 plots (fill in after running)
- Copies per content: singletons %, max copies, top 1% share
- Body size, bundled size, stars: shape of each (long tail?)
- Stars caveat: sample repos are biased toward repos with many skills

## Step 4 results
- Copies per distinct content: 74% appear once, max 188 copies, top 1% of contents hold 22.3% of all occurrences. Long tail plus a small head of heavily copied skills.
- Body size: one hump around 3k-10k chars, a few near-empty skills. The one zero-length body is a test skill (mock-skill).
- Bundled files: median about 3.6 KB. The biggest ones are binaries (.deb, .zip, .caffemodel, .pptx, .apk), so bundled does not mean scripts only, and binaries dominate total size.
- Stars: 54.3% of repos have 0 stars. Among starred repos the median is about 3 and the tail goes to 10^5. Repos in the sample are biased toward ones holding sampled skills.
- Sample vs full: same shapes, but the sample has more duplication (2.29 vs 2.02 occurrences per content, 56.4% vs 50.5% copies, singletons 74% vs about 78% in the full). So build on the sample, report numbers from the full data.
- Not claiming a power law without fitting it.

## Step 5 results
- Bundled files: 22,278 of 39,046 have text. Half are .md reference docs. Why the rest have no text is unknown (skipped_reason is empty).
- Script files: Python 4,261, JS 1,463, TS 930, Shell 915, Go 668. 1,214 of 1,398 skills use one script language.
- has_scripts flag gives 1,326 skills, my extension count gives 1,398. Definitions differ, need to check the paper.
- URLs: 3,573 of 13,000 skills (27.5%) have a URL, 18,561 total. github.com in 1,300 skills. Many top domains are placeholders (example.com, localhost, "..."). Clean these before reporting foreign URLs.
- Language: 90.4% English, at least 9.6% non-English. Short or mixed text makes detection noisy, spot-checked N by hand.
- Over time: 2 of 2,955 first commits before Oct 2025. Monthly first commits 12 (Oct 2025) to 629 (Jun 2026). July is partial. History sample only.

## Step 6: scripts vs copying (sample)
- has_scripts: 11,664 no, 1,326 yes, 10 NULL (excluded).
- Mean copies same (2.29 vs 2.28), driven by a few skills with up to 188 copies.
- Copied at least once: 26.7% (no scripts) vs 19.5% (scripts). 10+ copies: 3.1% vs 3.6% (only 48 skills).
- Association only, no causal claim. Folder info describes the representative's repo, other copies may differ.
- To do: distinct-repo version, chi-square test, mismatch check on the has_scripts definition, rerun on the full data.

## Step 6b
- has_scripts flag vs my extension list: 1,327 flagged skills have script files in my list, 71 have script files but flag 0. My list is broader. Truncated folders (91) have incomplete listings. Definition from the paper: (fill in).
- Distinct repos: 2+ repos 22.5% (no scripts) vs 16.9% (scripts), chi-square p about 4e-6 (approximate, rerun exactly).
- 10+ repos: 155 of 11,664 (1.3%) vs 35 of 1,326 (2.6%), Fisher p about 0.0006, odds ratio about 0.5.
- Reading: scripts are less likely to spread at all but overrepresented among widely spread skills.
- Caveats: association only, sample only, exact-hash copies only, folder info is from the representative's repo, the 35 may cluster in few families.
- To do: read the 35 by hand, check what their scripts do, rerun on the full data.

## Step 6c
- The 71 unflagged skills with script files are mostly .mjs and whole Go projects. Flag seems narrower than my list, check the paper's definition.
- Caveat: root-level SKILL.md means the folder can be the whole repo, which inflates sibling and script counts. Checked root vs nested: (fill in).
- The 35 skills in 10+ repos that bundle scripts: about 10 cybersecurity, about 7 scientific/bio, 3 look like Anthropic example skills (verify). 26 of 35 are in the canonical location (compare to base rate). 1 has no name.
- Hypothesis: spread happens through collections or catalogs. Test: do a few repos hold many of the 35?
- Next: read what their scripts do (network calls, shell execution), rerun on the full data.

## Step 6d
- Root-level SKILL.md: 156 skills (1.2%), avg 70-79 siblings, folder is probably the whole repo. 109 of the 1,326 flagged skills (8.2%). Nested skills: 9.5% bundle scripts (1,217 of 12,834). Report both.
- The 35 skills in 10+ repos with scripts: one repo holds 17, others 13 and 12, many hold exactly 8. Repo names suggest mirrors, registries and collections (verify by opening them). mukul975/Anthropic-Cybersecurity-Skills looks like a source, others look like copies.
- Hypothesis: widely spread script skills move via collections, not independent picking.
- Circularity: aggregator repos help push skills past 10 repos. Robustness check excluding big repos and root-level: (fill in).
- Caveat: sample repo sizes are thinned (about 0.7% of distinct contents), recompute repo sizes on the full data.

## Step 6e: robustness
- 181 repos (1.5%) hold 45% of occurrences, 102 repos with 21+ skills hold 41.2%. Single-skill repos: 78.8% of repos, 31.3% of occurrences. (Sample repo sizes are thinned.)
- 2+ repos, all repos: 22.5% (no scripts) vs 16.9% (scripts). Small repos only, no root-level skills: 8.0% vs 11.6%. The direction flips, so the first result was driven by collection repos.
- 10+ repos: 1.3% vs 2.6% (all), 1.0% vs 2.5% (small only). Consistent, about 2x. p roughly 6e-5 for the small-repo version.
- Caveats: association only, sample only, exact-hash copies only, folder info from the representative's repo, big-repo cutoff (>10) is arbitrary, denominators differ in the first small-repo query (fixed in the second).
- To do: cutoffs 5 and 20, rerun everything on the full data, open the top repos to confirm they are mirrors or collections, read what the scripts do.

## Step 6f
- Cleaned small-repo comparison (nested skills, at least one small-repo occurrence): 2+ small repos 11.0% (no scripts, 8,495) vs 13.3% (scripts, 1,059), p about 0.03, borderline. 10+ small repos: 119 vs 30, 1.4% vs 2.8%, Fisher p about 0.001.
- Defensible claim: widely spread skills are about 2x as likely to bundle scripts, with or without collection repos. The broader direction depends on the repo set, so it's exploratory.
- Report one main comparison, label the rest secondary. Cutoff sensitivity (5, 20) still to do.
- To do before the walkthrough: start the full-data download, open the top collection repos.