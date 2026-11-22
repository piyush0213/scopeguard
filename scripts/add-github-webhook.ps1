# Registers the ScopeGuard webhook on a GitHub repo using the gh CLI.
# Usage: ./scripts/add-github-webhook.ps1 -Repo owner/name -PublicUrl https://xxxx.ngrok-free.app
param(
  [Parameter(Mandatory)] [string] $Repo,
  [Parameter(Mandatory)] [string] $PublicUrl
)
$envFile = Join-Path $PSScriptRoot '..\server\.env'
$secretLine = Get-Content $envFile | Where-Object { $_ -match '^GITHUB_WEBHOOK_SECRET=' }
if (-not $secretLine) { throw "GITHUB_WEBHOOK_SECRET not found in server/.env" }
$secret = $secretLine.Split('=', 2)[1].Trim()
$url = $PublicUrl.TrimEnd('/') + '/webhooks/github'

$body = @{
  name   = 'web'
  active = $true
  events = @('create', 'push', 'workflow_run', 'pull_request', 'deployment_status')
  config = @{ url = $url; content_type = 'json'; secret = $secret; insecure_ssl = '0' }
} | ConvertTo-Json -Depth 4

$tmp = New-TemporaryFile
Set-Content -Path $tmp -Value $body -Encoding utf8
gh api "repos/$Repo/hooks" --method POST --input $tmp | Out-Null
Remove-Item $tmp
Write-Host "Webhook added: $url  (events: create, push, workflow_run, pull_request, deployment_status)"
