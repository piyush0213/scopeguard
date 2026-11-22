# Live demo helper: copies a demo-kit step into your repo, commits it on the order branch and pushes.
# ScopeGuard picks up the push within ~8 s and runs the Proof-of-Delivery audit.
#   .\push-step.ps1 -Repo C:\Users\Piyush\Dental -Branch order/CD-1049 -Step 1   # landing page only
#   .\push-step.ps1 -Repo C:\Users\Piyush\Dental -Branch order/CD-1049 -Step 2   # + auth module
param(
  [Parameter(Mandatory)] [string] $Repo,
  [Parameter(Mandatory)] [string] $Branch,
  [Parameter(Mandatory)] [ValidateSet(1, 2)] [int] $Step
)
$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot

Push-Location $Repo
try {
  git fetch origin 2>$null
  $exists = git branch --list $Branch
  if ($exists) { git checkout $Branch } else { git checkout -b $Branch }

  # Steps are cumulative: step 2 = step 1 + auth.
  Copy-Item -Recurse -Force "$kit\step-1-landing\*" .
  New-Item -ItemType Directory -Force .github\workflows | Out-Null
  Copy-Item -Force "$kit\..\demo-repo-template\.github\workflows\ci.yml" .github\workflows\ci.yml
  if ($Step -ge 2) { Copy-Item -Recurse -Force "$kit\step-2-auth\*" . }

  git add -A
  $msg = if ($Step -eq 1) { 'feat: landing page with hero, features, pricing and contact form' } else { 'feat: patient accounts - email/password, Google sign-in, password reset, protected routes' }
  git commit -m $msg
  git push -u origin $Branch
  Write-Host "`nPushed step $Step to $Branch. Watch the Proof Vault in ScopeGuard." -ForegroundColor Green
} finally {
  Pop-Location
}
