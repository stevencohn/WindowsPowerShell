
# cleanup remote left-over merged branches
git fetch --prune

# cleanup local branches where the remotes have been deleted (gone)
git branch -vv | where { $_ -match '\[origin/.*: gone\]' } | foreach { git branch -D $_.Trim().Split(' ')[0] }
