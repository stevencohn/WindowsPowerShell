
# cleanup remote left-over merged branches from local machine
Write-Host 'Cleaning remote-tracking branches that were deleted on remote' -fo Cyan
git fetch --prune

# cleanup local branches where the remotes have been deleted (gone)
Write-Host 'Cleaning local branches whose upstream remote branch is marked as "gone"' -fo Cyan
git branch -vv | where { $_ -match '\[origin/.*: gone\]' } | foreach { git branch -D $_.Trim().Split(' ')[0] }
