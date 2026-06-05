param(
  [string]$HubPath = "E:\AI\wiki",
  [ValidateSet("Json", "Markdown")]
  [string]$Format = "Json"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Get-FrontmatterValue {
  param(
    [string]$Text,
    [string]$Key
  )
  $pattern = "(?m)^" + [regex]::Escape($Key) + ":\s*`"?([^`"`r`n]+)`"?\s*$"
  $match = [regex]::Match($Text, $pattern)
  if ($match.Success) { return $match.Groups[1].Value.Trim() }
  return $null
}

function Get-Subdirs {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return @() }
  return @(Get-ChildItem -LiteralPath $Path -Directory | Sort-Object Name | ForEach-Object { $_.Name })
}

function Resolve-IncomingRawPath {
  param(
    [string]$HubPath,
    [string]$BrandId
  )
  $candidates = @(
    (Join-Path (Split-Path -Parent $HubPath) ("incoming\raw\" + $BrandId)),
    (Join-Path $HubPath ("incoming\raw\" + $BrandId))
  )
  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  return $candidates[0]
}

$topicsPath = Join-Path $HubPath "topics"
if (-not (Test-Path -LiteralPath $topicsPath)) {
  throw "Topics path not found: $topicsPath"
}

$brands = @()
foreach ($topic in Get-ChildItem -LiteralPath $topicsPath -Directory -Filter "brand-*") {
  $configPath = Join-Path $topic.FullName "config.md"
  $configText = ""
  if (Test-Path -LiteralPath $configPath) {
    $configText = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
  }

  $brandId = Get-FrontmatterValue $configText "brand"
  if (-not $brandId) { $brandId = $topic.Name -replace "^brand-", "" }

  $brandName = Get-FrontmatterValue $configText "brand_name"
  if (-not $brandName) { $brandName = $brandId }

  $rulePrefix = Get-FrontmatterValue $configText "rule_id_prefix"
  if (-not $rulePrefix) { $rulePrefix = $brandId.ToUpperInvariant() }

  $rawPath = Join-Path $topic.FullName "raw"
  $wikiPath = Join-Path $topic.FullName "wiki"
  $rulesPath = Join-Path $topic.FullName "rules"
  $outputsPath = Join-Path $topic.FullName "outputs"

  $brands += [pscustomobject]@{
    topic_name = $topic.Name
    topic_path = $topic.FullName
    brand = $brandId
    brand_name = $brandName
    rule_id_prefix = $rulePrefix
    incoming_raw_path = (Resolve-IncomingRawPath -HubPath $HubPath -BrandId $brandId)
    raw_path = $rawPath
    raw_domains = Get-Subdirs $rawPath
    wiki_path = $wikiPath
    wiki_domains = Get-Subdirs $wikiPath
    source_notes_path = (Join-Path $wikiPath "source-notes")
    rules_path = $rulesPath
    rule_domains = Get-Subdirs $rulesPath
    outputs_path = $outputsPath
    check_reports_path = (Join-Path $outputsPath "check-reports")
  }
}

$commonPath = Join-Path $topicsPath "common-business-rules"
$result = [pscustomobject]@{
  hub_path = (Resolve-Path -LiteralPath $HubPath).Path
  topics_path = (Resolve-Path -LiteralPath $topicsPath).Path
  generated_at = (Get-Date).ToString("s")
  brand_count = $brands.Count
  brands = $brands
  common_business_rules = [pscustomobject]@{
    topic_path = $commonPath
    governance_path = (Join-Path $commonPath "wiki\methodology\wiki-governance.md")
    comparison_reports_path = (Join-Path $commonPath "outputs\comparison-reports")
    common_rules_path = (Join-Path $commonPath "common-rules")
  }
}

if ($Format -eq "Json") {
  $result | ConvertTo-Json -Depth 8
  exit 0
}

"# Brand Wiki Registry"
""
"Hub: $($result.hub_path)"
"Generated: $($result.generated_at)"
"Brand count: $($result.brand_count)"
""
"| Brand | Name | Topic Path | Incoming Raw | Rule Prefix | Rule Domains | Wiki Domains |"
"|---|---|---|---|---|---|---|"
foreach ($b in $brands) {
  $ruleDomains = if ($b.rule_domains.Count) { $b.rule_domains -join ", " } else { "(none)" }
  $wikiDomains = if ($b.wiki_domains.Count) { $b.wiki_domains -join ", " } else { "(none)" }
  "| $($b.brand) | $($b.brand_name) | $($b.topic_path) | $($b.incoming_raw_path) | $($b.rule_id_prefix) | $ruleDomains | $wikiDomains |"
}
""
"Common business rules:"
""
"- Governance: $($result.common_business_rules.governance_path)"
"- Comparison reports: $($result.common_business_rules.comparison_reports_path)"
"- Common rules: $($result.common_business_rules.common_rules_path)"
