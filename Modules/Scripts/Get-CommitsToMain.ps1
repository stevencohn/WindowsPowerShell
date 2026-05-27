<#
.SYNOPSIS
Lists commits pushed directly to main without an associated pull request.

.DESCRIPTION
Fetches the latest origin/main and scans commits since a given date, querying
GitHub to identify any that have no associated PR (i.e. were committed directly
to main rather than merged via a pull request). Merge commits are excluded.
Results are displayed with a clickable hyperlink to each commit on GitHub.

.PARAMETER Owner
The GitHub repository owner (user or org). Defaults to 'stevencohn'.

.PARAMETER Repo
The GitHub repository name. Defaults to 'OneMore'.

.PARAMETER Since
ISO-8601 timestamp specifying how far back to scan, e.g. 2024-05-01T00:00:00Z.

.EXAMPLE
Get-CommitsToMain -Since 2024-05-01T00:00:00Z
Get-CommitsToMain -Owner myorg -Repo myrepo -Since 2025-01-01
#>
param(
    [string] $Owner = 'stevencohn',
    [string] $Repo = 'OneMore',

    [Parameter(Mandatory)]
    [string] $Since
)

# Validate timestamp
try {
    $dttm = [DateTime]::Parse($Since)
    $Since = $dttm.ToString('yyyy-MM-ddTHH:mm:ss') # Convert to ISO-8601 format
} catch {
    throw "Invalid timestamp format for -Since. Use ISO-8601, e.g. 2024-05-01T00:00:00"
}

git fetch origin main --quiet

# Get SHA + author date + subject line for non-merge commits after the timestamp
$commits = git log origin/main `
    --no-merges `
    --since="$Since" `
    --pretty=format:"%H|%ai|%s"

Write-Host "Scanning $($commits.Count) commits on origin/main since $Since..."

$directCommits = @()

foreach ($entry in $commits) {
    $parts = $entry -split '\|', 3
    $sha   = $parts[0]
    $date  = [DateTime]::Parse($parts[1])
    $msg   = $parts[2]

    # Query GitHub for PRs associated with this commit
    $prs = gh api `
        "repos/$Owner/$Repo/commits/$sha/pulls" `
        --jq '.[].number' 2>$null

    if (-not $prs) {
        # Store both SHA and message
        $directCommits += [PSCustomObject]@{
            Date    = $date.ToString('yyyy-MM-dd HH:mm')
            SHA     = $sha
            Message = $msg
        }
    }
    Write-Host '.' -NoNewline
}
Write-Host

Write-Host "`nCommits on origin/main without a PR and not a 'merge-commit' since $Since`n" -fo Cyan

$esc = [char]27
Write-Host ("Date".PadRight(18) + "SHA".PadRight(42) + "Message") -fo Yellow
Write-Host ("-" * 100) -fo DarkGray

foreach ($c in $directCommits)
{
    $url  = "https://github.com/$Owner/$Repo/commit/$($c.SHA)"
    $link = "$esc]8;;$url$esc\$($c.SHA)$esc]8;;$esc\"
    Write-Host "$($c.Date)  $link  $($c.Message)"
}