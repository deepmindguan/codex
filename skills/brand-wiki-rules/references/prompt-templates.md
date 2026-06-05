# Prompt Templates

Use these templates after running `scripts/discover-brand-wikis.ps1`. Replace placeholders from the discovered registry and from actual source analysis.

## Initialize Brand Wiki

```text
请基于统一规范 wiki-governance.md，为【{brand_name}知识库】初始化 LLM Wiki 目录与基础文件。

知识库路径：
{topic_path}

品牌标识：{brand}
中文名称：{brand_name}知识库
规则 ID 前缀：{rule_id_prefix}

请创建：
config.md、_index.md、log.md、raw/、wiki/、rules/、outputs/ 及其子目录。

要求：
- 目录按实际业务域动态创建，默认至少包含 raw/、wiki/source-notes/、rules/、outputs/check-reports/
- 不要把其他品牌资料写入本品牌知识库
- config.md 写明知识置信度口径 high / medium / low / unknown
- log.md 记录初始化动作
```

## Ingest New Sources

```text
请处理以下新资料，并归档到{brand_name}知识库。

资料路径：
{incoming_raw_path} 下的所有文件

目标知识库：
{topic_path}

请完成：
1. 判断资料类型和业务主题
2. 建议放入哪个 raw 子目录；子目录按实际主题动态判断
3. 保留原始资料，不改写原文
4. 生成资料摘要 md
5. 提取核心事实
6. 提取涉及角色
7. 提取涉及流程
8. 提取潜在业务规则
9. 标记来源位置
10. 标记知识置信度及理由
11. 标记待确认问题

资料摘要输出到：
{topic_path}\wiki\source-notes\

要求：
- 不要先假设主题为 expense/channels；从资料内容判断
- 每条核心事实、流程和潜在规则必须标记 confidence
- 缺少依据或口径不清的内容写入待确认问题
```

## Generate Knowledge Article

```text
请基于{brand_name}知识库中已入库资料，生成知识文章。

知识库路径：
{topic_path}

主题：
请你根据已入库资料判断最合适的主题，并输出主题判断理由

输出路径：
{topic_path}\wiki\{inferred_domain}\{theme_slug}.md

要求：
1. 只使用{brand_name}知识库已有资料
2. 所有关键结论标注来源
3. 不确定内容写入待确认问题
4. 使用 YAML frontmatter
5. 在 frontmatter 和关键结论处标记 confidence
6. 使用 [[wikilink]] 关联相关主题
7. 只列出可提炼业务规则，不直接生成规则
8. 不要引用其他品牌资料
```

## Extract Brand Rules

```text
请从{brand_name}知识库的以下知识文章中提炼业务规则。

知识文章：
{article_path}

输出目录：
{topic_path}\rules\{inferred_domain}\

要求：
1. 每条规则单独生成一个 Markdown 文件
2. 规则 ID 使用 {rule_id_prefix}-{domain_upper}-001 格式；若该品牌已有既定 ID 格式，则沿用既有格式
3. 每条规则必须有来源依据
4. 不确定规则标记为 draft
5. 缺少来源的内容写入待确认问题
6. 不要生成知识文章中没有依据的规则
7. 每条规则标记 confidence 和 confidence_reason

每条规则至少包含：
- rule_id
- status
- title
- scope
- condition
- action
- responsible_role
- required_data
- sources
- evidence
- confidence
- confidence_reason
- pending_questions
```

## Validate Brand Rules

```text
请校验{brand_name}知识库中的规则。

规则目录：
{topic_path}\rules\{inferred_domain}\

输出检查报告：
{topic_path}\outputs\check-reports\{inferred_domain}-rule-check-{date}.md

请检查：
1. 是否有来源依据
2. 判断条件是否清楚
3. 执行动作是否明确
4. 责任角色是否明确
5. 所需数据是否明确
6. 是否存在规则冲突
7. 是否可以人工执行或系统执行
8. 是否存在待确认问题
9. 规则置信度是否与来源依据匹配
```

## Compare Brands

```text
请对比以下品牌知识库中【{actual_theme}】相关业务规则。

请先动态读取每个品牌的规则目录，不要假设所有品牌都有同名目录：
{brand_rule_dirs}

输出：
1. 主题定义和判断理由
2. 直接规则与支撑规则的分类口径
3. 五品牌或多品牌共同规则
4. 部分品牌共同规则
5. 品牌独有规则
6. 规则差异点
7. 规则冲突点
8. 可沉淀为共同规则的建议
9. 待确认问题
10. 对应规则编码与具体规则明细

输出文件：
{common_topic_path}\outputs\comparison-reports\{theme_slug}-rule-comparison-{date}.md

要求：
- 只能读取品牌 rules 目录中已有规则
- 不要把主题强行命名为 expense；按实际规则内容判断
- 每个共同点、差异点和冲突点都要标记 confidence
- 共同规则建议必须标记覆盖品牌并链接对应品牌规则
```

## Generate Common Rules

```text
请根据以下跨品牌对比报告，生成共同规则 Markdown 文件。

对比报告：
{comparison_report_path}

输出目录：
{common_topic_path}\common-rules\{inferred_domain}\

要求：
1. 每条共同规则单独成文
2. 共同规则 ID 使用 COMMON-{domain_upper}-001 格式
3. 标记覆盖品牌
4. 链接对应品牌规则
5. 保留品牌差异
6. 标记 confidence 和 confidence_reason
7. 标记待确认问题
8. 不允许生成品牌规则中不存在的内容
```
