
git branch --merged main | where { $_ -notlike '*main' } | foreach { git branch -d $_.Trim() }

git remote prune origin

