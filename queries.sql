-- GitSkills sample profiling: all SQL used so far.
-- Run one query at a time, e.g.  sqlite3 -header -column agent_skills_sample.db
-- Written against the sample; the full dataset has the same schema.

------------------------------------------------------------
-- Step 1-3: counts and size metrics
------------------------------------------------------------

-- Q1. Rows per table, and number of distinct skill contents
SELECT 'artifacts' AS tbl, COUNT(*) AS n FROM artifacts
UNION ALL SELECT 'artifact_siblings', COUNT(*) FROM artifact_siblings
UNION ALL SELECT 'repos', COUNT(*) FROM repos
UNION ALL SELECT 'mining_runs', COUNT(*) FROM mining_runs
UNION ALL SELECT 'distinct contents', COUNT(*) FROM artifacts WHERE dedup_primary=1;

-- Q2. Repos, owners, location classes, front matter, bundling, siblings, history, authors
SELECT COUNT(DISTINCT repo_full_name) AS repos_with_skills FROM artifacts;
SELECT COUNT(DISTINCT owner) AS owners FROM repos;
SELECT location_class, COUNT(*) AS n FROM artifacts GROUP BY location_class;
SELECT frontmatter_valid, COUNT(*) AS n FROM artifacts WHERE dedup_primary=1 GROUP BY frontmatter_valid;
SELECT SUM(has_scripts) AS with_scripts, SUM(has_references) AS with_refs, COUNT(*) AS skills
FROM artifacts WHERE dedup_primary=1;
SELECT entry_type, COUNT(*) AS n, SUM(entry_size) AS bytes FROM artifact_siblings GROUP BY entry_type;
SELECT SUM(history_fetched) AS with_history FROM artifacts;
SELECT COUNT(*) AS distinct_authors
FROM (SELECT first_commit_author AS a FROM artifacts UNION SELECT last_commit_author FROM artifacts)
WHERE a IS NOT NULL AND a <> '';

-- Q3. Oddities: zero-length skill bodies, largest bundled files
SELECT repo_full_name, path, frontmatter_valid, substr(content,1,80) AS start
FROM artifacts WHERE dedup_primary=1 AND body_chars=0 LIMIT 5;
SELECT repo_full_name, entry_name, entry_size FROM artifact_siblings ORDER BY entry_size DESC LIMIT 5;

------------------------------------------------------------
-- Step 6: scripts and how widely skills are copied
------------------------------------------------------------

-- Q4. has_scripts flag vs a file-extension based definition of "script"
WITH s AS (
  SELECT DISTINCT repo_full_name, artifact_path FROM artifact_siblings
  WHERE entry_type='file' AND (entry_name LIKE '%.py' OR entry_name LIKE '%.sh' OR entry_name LIKE '%.bash'
    OR entry_name LIKE '%.js' OR entry_name LIKE '%.mjs' OR entry_name LIKE '%.cjs' OR entry_name LIKE '%.ts'
    OR entry_name LIKE '%.rb' OR entry_name LIKE '%.go' OR entry_name LIKE '%.rs' OR entry_name LIKE '%.ps1'
    OR entry_name LIKE '%.bat' OR entry_name LIKE '%.java' OR entry_name LIKE '%.php' OR entry_name LIKE '%.pl'
    OR entry_name LIKE '%.lua'))
SELECT a.has_scripts, a.composition_truncated, COUNT(*) AS skills
FROM s JOIN artifacts a ON a.repo_full_name=s.repo_full_name AND a.path=s.artifact_path
GROUP BY 1,2;

-- Q5. Skills with script-like files but has_scripts = 0 (what does the flag miss?)
SELECT s.repo_full_name, s.entry_name FROM artifact_siblings s
JOIN artifacts a ON a.repo_full_name=s.repo_full_name AND a.path=s.artifact_path
WHERE a.dedup_primary=1 AND a.has_scripts=0 AND s.entry_type='file'
AND (s.entry_name LIKE '%.py' OR s.entry_name LIKE '%.sh' OR s.entry_name LIKE '%.js' OR s.entry_name LIKE '%.ts'
  OR s.entry_name LIKE '%.go' OR s.entry_name LIKE '%.rb' OR s.entry_name LIKE '%.php' OR s.entry_name LIKE '%.pl'
  OR s.entry_name LIKE '%.lua' OR s.entry_name LIKE '%.bat' OR s.entry_name LIKE '%.ps1' OR s.entry_name LIKE '%.java'
  OR s.entry_name LIKE '%.rs' OR s.entry_name LIKE '%.mjs' OR s.entry_name LIKE '%.cjs' OR s.entry_name LIKE '%.bash')
LIMIT 20;

-- Q6. Copies (occurrences) of a skill, by has_scripts
WITH c AS (SELECT file_sha, COUNT(*) AS copies FROM artifacts GROUP BY file_sha)
SELECT a.has_scripts, COUNT(*) AS skills,
       ROUND(AVG(c.copies),2) AS mean_copies,
       ROUND(100.0*SUM(c.copies>1)/COUNT(*),1) AS pct_copied,
       SUM(c.copies>=10) AS copied_10plus
FROM artifacts a JOIN c USING(file_sha)
WHERE a.dedup_primary=1 GROUP BY a.has_scripts;

-- Q7. Spread across distinct repos, by has_scripts (all repos)
WITH c AS (SELECT file_sha, COUNT(DISTINCT repo_full_name) AS repos FROM artifacts GROUP BY file_sha)
SELECT a.has_scripts, COUNT(*) AS skills,
       ROUND(100.0*SUM(c.repos>1)/COUNT(*),1) AS pct_in_2plus_repos,
       SUM(c.repos>=10) AS in_10plus_repos
FROM artifacts a JOIN c USING(file_sha)
WHERE a.dedup_primary=1 AND a.has_scripts IS NOT NULL GROUP BY a.has_scripts;

-- Q8. The skills that bundle scripts and appear in 10+ repos
WITH c AS (SELECT file_sha, COUNT(DISTINCT repo_full_name) AS repos FROM artifacts GROUP BY file_sha)
SELECT c.repos, a.name, a.location_class, a.sibling_count, substr(a.description,1,70) AS descr
FROM artifacts a JOIN c USING(file_sha)
WHERE a.dedup_primary=1 AND a.has_scripts=1 AND c.repos>=10 ORDER BY c.repos DESC;

-- Q9. Which repos hold those skills (collection / mirror repos?)
WITH c AS (SELECT file_sha, COUNT(DISTINCT repo_full_name) AS repos FROM artifacts GROUP BY file_sha),
top AS (SELECT a.file_sha FROM artifacts a JOIN c USING(file_sha)
        WHERE a.dedup_primary=1 AND a.has_scripts=1 AND c.repos>=10)
SELECT repo_full_name, COUNT(DISTINCT file_sha) AS n_of_the_top
FROM artifacts WHERE file_sha IN (SELECT file_sha FROM top)
GROUP BY repo_full_name ORDER BY n_of_the_top DESC LIMIT 15;

-- Q10. Root-level SKILL.md (folder is probably the whole repo) vs nested
SELECT (path='SKILL.md') AS root_level, has_scripts, COUNT(*) AS skills, ROUND(AVG(sibling_count),1) AS avg_siblings
FROM artifacts WHERE dedup_primary=1 AND has_scripts IS NOT NULL GROUP BY 1,2;

-- Q11. How many skills sit in repos of each size (sample counts are thinned)
SELECT CASE WHEN n=1 THEN '1' WHEN n<=5 THEN '2-5' WHEN n<=10 THEN '6-10' WHEN n<=20 THEN '11-20' ELSE '21+' END AS skills_in_repo,
       COUNT(*) AS repos, SUM(n) AS occurrences
FROM (SELECT repo_full_name, COUNT(*) AS n FROM artifacts GROUP BY repo_full_name)
GROUP BY 1 ORDER BY MIN(n);

-- Q12. MAIN ROBUSTNESS CHECK: spread across SMALL repos only, nested skills only.
-- "big" = repos with more than 10 sampled occurrences. Change 10 to 5 or 20 for the sensitivity check.
WITH big AS (SELECT repo_full_name FROM artifacts GROUP BY repo_full_name HAVING COUNT(*)>10),
c AS (SELECT file_sha, COUNT(DISTINCT repo_full_name) AS repos FROM artifacts
      WHERE repo_full_name NOT IN (SELECT repo_full_name FROM big) GROUP BY file_sha)
SELECT a.has_scripts, COUNT(*) AS skills,
       ROUND(100.0*SUM(c.repos>1)/COUNT(*),1) AS pct_in_2plus_small_repos,
       SUM(c.repos>=10) AS in_10plus_small_repos
FROM artifacts a JOIN c USING(file_sha)
WHERE a.dedup_primary=1 AND a.has_scripts IS NOT NULL AND a.path<>'SKILL.md'
GROUP BY a.has_scripts;
