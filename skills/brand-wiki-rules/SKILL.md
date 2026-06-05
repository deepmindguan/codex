---
name: brand-wiki-rules
description: Dynamic brand LLM Wiki workflow for initializing brand knowledge bases, ingesting raw sources, inferring article topics, extracting brand rules, validating rules, comparing multiple brands, and generating common rules. Use when working on E:\AI\wiki style brand topics, channel/terminal/expense-verification rules, cross-brand rule comparison, common-business-rules outputs, or when the user wants prompts/templates that should adapt to new brands, changing themes, and non-hard-coded directories.
---

# Brand Wiki Rules

Use this skill to run the brand knowledge-base and rule workflow without hard-coding a brand, theme, or directory. Pair it with the LLM Wiki skill when available.

## First Step

Run `scripts/discover-brand-wikis.ps1` before any workflow that depends on brands, paths, rule directories, or comparison inputs.

Default command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\deepm\.codex\skills\brand-wiki-rules\scripts\discover-brand-wikis.ps1" -HubPath "E:\AI\wiki" -Format Markdown
```

Use the discovered registry as the source of truth for:

- brand id, brand name, rule ID prefix
- topic root
- incoming raw directory
- raw/wiki/rules/outputs paths
- actual rule domain directories such as `rules/channels`
- actual wiki topic directories such as `wiki/channels`

If a user provides a path that conflicts with discovery, explain the mismatch and use the existing valid path unless the user explicitly asks to create or migrate.

## Dynamic Rules

- Do not assume the topic is `expense` just because a filename or older prompt says expense. Infer the theme from source notes, knowledge articles, and rule content.
- Use `channels` only when the source content is about渠道、终端、陈列、照片、AI 检核、铺货、拜访、核销支撑 or channel execution. Otherwise choose a domain directory from the content, such as `pricing`, `products`, `operations`, `legal`, or a new kebab-case domain.
- Do not put a new brand into a static five-brand list. Discover all `topics/brand-*` folders and read each `config.md`.
- Do not rewrite raw sources. Copy or reference them only.
- Every knowledge claim and rule must cite source material. Missing or weak evidence becomes `pending_questions`.
- Common rules can only be generated from brand rules or cross-brand comparison reports, never directly from raw files or a single brand article.
- Treat `_index.md`, `config.md`, and `log.md` as operational files. Do not use them as business rules, except to discover metadata and append logs.

## Workflow Selector

1. **Initialize brand**: discover registry, create missing standard directories, write `config.md`, `_index.md`, `log.md`, and append hub registration if needed.
2. **Ingest sources**: classify incoming files into `raw/<domain>`, preserve originals, create source notes in `wiki/source-notes`.
3. **Generate article**: infer the best topic/domain from source notes and raw evidence, then write `wiki/<domain>/<topic-slug>.md`.
4. **Extract rules**: read the article, infer or confirm domain, write one rule per file under `rules/<domain>`.
5. **Validate rules**: check evidence, condition, action, role, data, conflicts, execution mode, pending questions, and confidence.
6. **Compare brands**: discover all target brand rule directories, group by actual theme, compare commonality and differences, and name the report by inferred theme.
7. **Generate common rules**: read the comparison report, create one common rule per file under `common-business-rules/common-rules/<domain>`.
8. **Package demo**: copy selected source notes, rules, comparison reports, common rules, and operation docs without changing source files.

Load `references/prompt-templates.md` when the user asks for reusable prompts or when drafting an operation guide.

## Adding a New Brand

When the user adds a new brand, only require these inputs:

- topic path or brand id from which topic path can be inferred as `topics/brand-{brand}`
- brand id
- Chinese/display name
- rule ID prefix

After initialization, all later prompts must use discovered paths from the registry. Do not copy and edit an old brand prompt manually. If a new brand has a different theme, infer a new domain and slug from the new sources.

## Theme Inference

Use the business center of gravity, not the user's last mistaken label:

- Direct expense theme: rules explicitly mention费用、核销、签约、签收、补贴、陈列费、进店费、抢点费、付款.
- Expense-verification support theme: rules produce evidence used for费用核验、奖励判断、执行评分、渠道稽核 but do not directly define payment.
- Channel execution theme: rules describe terminal photos, display, SKU, facing, freezer, price tag, stack box, visit frequency, AI recognition, audit status, or store execution.
- Perfect store / scoring theme: rules describe scoring, distribution, shelf share, checkout coverage, material execution, or store standards.

If a report contains mixed themes, title it with the broadest accurate theme, for example `渠道执行与费用核验支撑规则`, and include a section that separates direct expense rules from support rules.

## Naming

Prefer these patterns, using the discovered brand prefix:

- Brand rule ID: `{RULE_PREFIX}-{DOMAIN_UPPER}-{NNN}`, for example `JINMAILANG-CHANNELS-001`.
- Preserve existing IDs if a brand already has a different pattern; do not mass-rename without an explicit migration request.
- Common rule ID: `COMMON-{DOMAIN_UPPER}-{NNN}`.
- Knowledge article slug: kebab-case business theme, not a generic label like `expense` unless the content is actually expense.
- Comparison report: `{theme-slug}-rule-comparison-{YYYY-MM-DD}.md`. Keep older filenames when other artifacts already link to them, but update title/scope to the actual theme.

## Required Fields

Knowledge articles:

- YAML frontmatter with title, brand, type, domain, sources, confidence, tags, created/updated.
- Key conclusions with source links.
- `[[wikilink]]` connections where useful.
- Candidate rules only, not generated rule files.
- Pending questions for missing evidence.

Brand rules:

- YAML frontmatter with title, brand, rule_id, rule_type, status, sources, evidence, confidence.
- Sections: rule content, applicable conditions, action, responsible role, required data, evidence chain, pending questions.

Comparison reports:

- Scope, actual brand dirs used, theme definition, rule inventory.
- A rule ID to concrete rule detail table for every compared rule.
- Common rules by coverage count, unique rules, differences, conflicts, suggestions, pending questions.

Common rules:

- common_rule_id, status, domain, covered brands, brand rule links, common condition/action, brand differences, confidence, confidence reason, pending questions.

## Confidence

Use `high`, `medium`, `low`, or `unknown`.

- `high`: source text directly states the fact/rule or multiple sources corroborate it.
- `medium`: source supports it but interpretation is needed.
- `low`: indirect evidence or incomplete rule wording.
- `unknown`: cannot be determined from current materials.

Do not mark a rule `active` if the evidence is `low` or `unknown`.

## Logging

Append to the relevant `log.md` after every write. Keep entries short:

```markdown
## [YYYY-MM-DD] action | Summary of changed artifact path
```

Do not rewrite prior log entries.
