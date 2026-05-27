param(
    [string] $Owner = 'stevencohn',

    [string] $Repo = 'OneMore',

    [Parameter(Mandatory)]
    [string] $Since
)

# Validate timestamp
try {
    $null = [DateTime]::Parse($Since)
} catch {
    throw "Invalid timestamp format for -Since. Use ISO-8601, e.g. 2024-05-01T00:00:00Z"
}

git fetch origin main --quiet

# Get SHA + subject line for non-merge commits after the timestamp
$commits = git log origin/main `
    --no-merges `
    --since="$Since" `
    --pretty=format:"%H|%s"

Write-Host "Scanning $($commits.Count) commits on origin/main since $Since..."

$directCommits = @()

foreach ($entry in $commits) {
    $parts = $entry -split '\|', 2
    $sha   = $parts[0]
    $msg   = $parts[1]

    # Query GitHub for PRs associated with this commit
    $prs = gh api `
        "repos/$Owner/$Repo/commits/$sha/pulls" `
        --jq '.[].number' 2>$null

    if (-not $prs) {
        # Store both SHA and message
        $directCommits += [PSCustomObject]@{
            SHA     = $sha
            Message = $msg
        }
    }
    Write-Host '.' -NoNewline
}
Write-Host

Write-Host "`nCommits on origin/main without a PR and not a 'merge-commit' since $Since`n" -fo Cyan
$directCommits | Format-Table -AutoSize