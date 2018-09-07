# quick command line to pull latest source of this repo from Github

git -c diff.mnemonicprefix=false -c core.quotepath=false fetch origin
git -c diff.mnemonicprefix=false -c core.quotepath=false pull --no-commit origin master
