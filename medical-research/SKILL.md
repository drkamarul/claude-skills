---
name: medical-research
description: >
  Use this skill for ANY medical or health research task — especially when KIM needs to find, evaluate, synthesize, or cite scientific literature. Trigger whenever the user asks to: search for articles, papers, or references; review evidence on a health topic; find citations for a manuscript; summarise what is known about a disease, intervention, or method; conduct a literature review or scoping review; look up epidemiological data, statistics, or burden of disease; compare treatment approaches; assess methodological quality; prepare a bibliography; answer a clinical or public health question using evidence. Also trigger for questions about non-communicable diseases (NCDs), communicable diseases, epidemiology, biostatistics, public health policy, digital health, global burden of disease (GBD), and any topic where peer-reviewed evidence is needed. Always use this skill even for seemingly simple evidence queries — it ensures source prioritisation and quality filtering are applied.
---

# Medical Research Skill

A structured framework for finding, evaluating, and synthesising high-quality medical and public health literature for KIM's research, teaching, and clinical epidemiology work.

---

## Source Priority Hierarchy

Always retrieve and present sources in this order of priority:

### Tier 1 — Gold Standard Databases (search first)
| Database | Coverage | Notes |
|---|---|---|
| **PubMed / MEDLINE** | Biomedical & life sciences | Use via PubMed MCP tool when available; otherwise web_search with `site:pubmed.ncbi.nlm.nih.gov` |
| **Web of Science** | Multidisciplinary, citation metrics | Prefer for citation counts and h-index data |
| **Scopus** | Broad biomedical + social sciences | Good for ASEAN / Malaysian literature |

### Tier 2 — High-Impact Journals (prioritise results from these)
- **NEJM** (New England Journal of Medicine)
- **JAMA** and JAMA Network Open
- **The Lancet** and Lancet sub-journals (Lancet Public Health, Lancet Global Health, etc.)
- **BMJ** (British Medical Journal)
- **BMC** journals (BMC Public Health, BMC Medicine, etc.)
- **Nature Medicine**, **Nature Reviews**
- **Annals of Internal Medicine**
- **PLOS Medicine**, **PLOS ONE**
- **International Journal of Epidemiology**
- **Epidemiology & Community Health (JECH)**
- **American Journal of Public Health (AJPH)**
- **Bulletin of the World Health Organization**

### Tier 3 — Supporting Sources
- WHO, CDC, IHME, MOH Malaysia official reports
- Cochrane systematic reviews and meta-analyses
- Preprints (medRxiv, bioRxiv) — flag as not yet peer-reviewed

---

## Citation Priority Filter

When multiple sources cover the same topic, apply this ranking:

1. **Citation count ≥ 20** → Always include; mark as highly cited
2. **Systematic reviews and meta-analyses** → Highest evidence level; prioritise
3. **RCTs and cohort studies** → Strong evidence; include
4. **Recency bonus**: For rapidly evolving fields (e.g., COVID-19, AI in health), prefer articles from the last 3–5 years even if citation count is lower
5. **Regional relevance**: For KIM's work, up-weight Malaysian, ASEAN, or low-middle-income country (LMIC) studies even with lower citations

---

## Priority Research Domains

Apply extra rigour and broader searches for these fields (KIM's core areas):

- **Epidemiology** — study design, causal inference, DAGs, bias, confounding
- **Biostatistics** — regression, survival analysis, mixed models, machine learning in health
- **Non-communicable diseases (NCDs)** — cardiovascular, stroke, diabetes, cancer, mental health
- **Communicable diseases** — respiratory infections, tuberculosis, dengue, emerging pathogens
- **Public health policy & health systems** — Malaysia, ASEAN, LMIC settings
- **Global Burden of Disease (GBD)** — IHME methodology, DALYs, mortality patterns
- **Digital health & mHealth** — apps, wearables, AI/ML in clinical settings
- **Precision medicine & genomics**

---

## Standard Search Workflow

### Step 1 — Clarify the Query
Before searching, identify:
- **PICO** (Population, Intervention/Exposure, Comparator, Outcome) if clinical/epidemiological
- **Date range** needed (default: all time; if current evidence needed, last 5–10 years)
- **Study design** filter if applicable (RCT, cohort, systematic review, etc.)
- **Geographic scope** (global vs. Malaysia/ASEAN)

### Step 2 — Construct Search Terms
Build a structured query:
```
("main condition/disease") AND ("exposure OR intervention") AND ("outcome") 
Filter: systematic review OR meta-analysis OR cohort study
```
Use MeSH terms where possible for PubMed.

### Step 3 — Execute Searches
Use tools in this order:
1. **PubMed MCP tool** (if available in session) — most reliable for biomedical literature
2. **web_search** with targeted queries (e.g., `"stroke prevalence" Malaysia pubmed site:pubmed.ncbi.nlm.nih.gov`)
3. **web_fetch** to retrieve full abstracts or full-text from open-access sources
4. **web_search** for grey literature (WHO reports, MOH Malaysia, IHME GBD data)

### Step 4 — Filter and Rank Results
Apply the Citation Priority Filter above. For each result note:
- Authors, year, journal
- Study design
- Citation count (if retrievable)
- Key finding relevant to the query
- Whether it meets Tier 1/2/3 source criteria

### Step 5 — Synthesise
Organise results by:
- **Evidence level** (meta-analysis > RCT > cohort > cross-sectional > case report)
- **Relevance to query** (direct vs. indirect evidence)
- **Recency**

Present a structured summary with in-text citations formatted for academic use.

---

## Output Format

### For Literature Search Results
```
## Search Summary: [Topic]

**Databases searched:** PubMed, [others]  
**Search terms:** [terms used]  
**Date range:** [range]  
**Results found:** [n] relevant articles

---

### Key Evidence

**[Author et al., Year]** — *[Journal]*  
- Study design: [type]  
- Citations: [n] | IF: [if known]  
- Finding: [1–2 sentence summary]  
- Relevance: ★★★ [High/Medium/Low]

[repeat for each article]

---

### Evidence Summary
[2–4 paragraph synthesis of what the literature shows, with citations]

### Gaps & Limitations
[Notable gaps, LMIC data paucity, methodological limitations across studies]
```

### For Quick Reference Checks
Provide: Author (Year), Journal, DOI/PMID, and one-line finding.

### Citation Format
Default to **Vancouver** (numbered) for medical journals; offer APA or Harvard on request.

---

## Quality Assessment Quick Checklist

When evaluating a study for KIM:

| Criterion | Check |
|---|---|
| Peer-reviewed journal? | ✓/✗ |
| Sample size adequate? | ✓/✗ |
| Appropriate study design for question? | ✓/✗ |
| Confounding addressed? | ✓/✗ |
| Statistical methods sound? | ✓/✗ |
| Conflict of interest declared? | ✓/✗ |
| Replicable / open data? | ✓/✗ |
| Relevant to Malaysian/ASEAN context? | ✓/✗ |

---

## Special Handling

### Systematic Reviews & Meta-analyses
- Check PROSPERO registration (if prospective)
- Look for PRISMA flow diagram
- Assess heterogeneity (I² statistic)
- Note funnel plot / publication bias assessment

### GBD / Burden of Disease Queries
- Prioritise IHME publications and GBD Collaborator papers
- Note GBD cycle year (2019, 2021, 2023, etc.)
- Look for country-specific or Malaysia-specific estimates
- Cross-reference with MOH Malaysia Health Facts / NHMS data

### Malaysian / ASEAN Literature
- Search MyScielo, MyJurnal (Malaysian journals)
- Include Medical Journal of Malaysia, Asia-Pacific Journal of Public Health
- Note that citation counts are often lower for regional journals — don't penalise unduly

### Statistical / Methodological Papers
- Prioritise Statistics in Medicine, Biometrics, American Statistician
- For applied tutorials: BMJ Statistics Notes series is excellent
- For R methodology: Journal of Statistical Software, R Journal

---

## Integration Notes

- When PubMed MCP tool is connected, use it directly for structured queries
- Combine with **web_search** for citation counts and full-text access
- Use **web_fetch** on DOI links or PubMed abstract pages to get full details
- For KIM's manuscript preparation, flag articles suitable for introduction, methods justification, or discussion sections
- Always note if an article is open-access (OA) for easy retrieval
