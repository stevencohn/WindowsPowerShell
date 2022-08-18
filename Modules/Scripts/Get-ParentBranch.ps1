<#
.DESCRIPTION
Based on Linux command:

git show-branch -a 2>nul | grep '\*' | grep -v `git rev-parse --abbrev-ref HEAD` | head -n1 | \
sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//'

PowerShell translation:

$name = git rev-parse --abbrev-ref HEAD; (git show-branch -a 2>$null | `
where { $_.startswith('*') } | where { -not $_.contains($name) } | select -first 1 | `
select-string -pattern '.*\[(.*)(?:\^\d+)\].*').matches.groups[1].value

#>

try {
    $name = git rev-parse --abbrev-ref HEAD;

    if ($name)
    {
        $m = git show-branch -a 2>$null | `
            where { $_.startswith('*') } | `
            where { -not $_.contains($name) } | `
            select -first 1 | select-string -pattern '.*\[(.*)(?:\^\d+)\].*'
            
        if ($m.Matches.Success) {
            $m.Matches.Groups[1].Value
        } else {
            Write-Host "parent branch not found; current branch is $name"
        }
    } else {
        Write-Host 'current branch cannot be determined'
    }
}
catch {
    Write-Host '*** cannot determine parent branch; is this a Git repo?'
}
