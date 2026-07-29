#!/usr/bin/env pwsh
<#
.SYNOPSIS
Cleans up GitHub releases (assets + release + tag, local and remote) that are not
"major", "major.minor", or "major.minor.0" versions.

.DESCRIPTION
Lists all releases in a repo via `gh release list`. Any tag matching
	^\d+(?:\.\d+(?:\.0)?)?$
(i.e. "1", "1.2", or "1.2.0") is KEPT.

Everything else (e.g. "1.2.3", "1.2.15") is DELETED:
  1. All release assets (gh release delete-asset)
  2. The release AND its remote tag together (gh release delete --cleanup-tag)
  3. The local tag, if present (git tag -d)

If -Tag is supplied, this bulk classification is bypassed entirely and only the
named tag/release is deleted, regardless of the "keep" pattern or major-version
guard.

.PARAMETER Repo
GitHub repo in OWNER/NAME format. Defaults to the OneMore repo.

.PARAMETER Tag
Exactly one tag whose release should be deleted, bypassing the normal
keep/skip/delete classification and major-version guard.

.PARAMETER Force
Skip the interactive "type yes" confirmation prompt.

.PARAMETER Limit
Max number of releases to fetch from `gh release list`. Default 1000. Ignored
when -Tag is supplied.

.EXAMPLE
./cleanup-releases.ps1 -WhatIf
Dry run: shows what would be kept/deleted without changing anything.

.EXAMPLE
./cleanup-releases.ps1 -Repo myorg/myrepo -Force
Runs for real against myorg/myrepo with no interactive prompt.

.EXAMPLE
./cleanup-releases.ps1 -Tag 1.2.3 -Force
Deletes only the release/tag "1.2.3", assets included.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$Repo = 'stevencohn/OneMore',
    [string]$Tag,
    [switch]$Force,
    [int]$Limit = 1000
)

Begin
{

    function AssertPrerequisites {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            throw "GitHub CLI ('gh') not found in PATH. Install it from https://cli.github.com/"
        }

        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw "git not found in PATH."
        }

        #$authStatus = gh auth status 2>&1
        #if ($LASTEXITCODE -ne 0) {
        #    throw "gh is not authenticated. Run 'gh auth login' first.`n$authStatus"
        #}
    }

    function ResolveOwnerRepo {
        param([string]$Repo)

        if ($Repo) {
            return $Repo
        }

        $ownerRepo = gh repo view --json nameWithOwner -q .nameWithOwner
        if ($LASTEXITCODE -ne 0 -or -not $ownerRepo) {
            throw "Could not determine repo automatically. Pass -Repo OWNER/NAME explicitly."
        }
        return $ownerRepo
    }

    function GetReleaseList {
        param(
            [string[]]$RepoArgs,
            [int]$Limit
        )

        $json = gh release list @RepoArgs --limit $Limit --json tagName,isDraft,isPrerelease
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to list releases via gh."
        }
        return $json | ConvertFrom-Json
    }

    function GroupReleasesForCleanup {
        param(
            [object[]]$Releases,
            [int]$MaxMajorVersion
        )

        $keepPattern = '^(?<major>\d+)(?:\.\d+(?:\.0)?)?$'
        $betaPattern = 'beta'  # case-insensitive match against the tag name
        $majorExtractPattern = '^(?<major>\d+)'   # leading integer of any tag, e.g. "1" from "1.2.3"

        $toKeep = @()
        $toDelete = @()
        $toSkip = @()   # would-be deletions held back by the MaxMajorVersion guard, or unparseable tags

        foreach ($release in $Releases) {
            $tag = $release.tagName

            if ($tag -match $keepPattern -and $tag -notmatch $betaPattern) {
                $toKeep += $tag
                continue
            }

            # Not a keeper -> candidate for deletion, but gate it on major version.
            $majorMatch = [regex]::Match($tag, $majorExtractPattern)
            if (-not $majorMatch.Success) {
                # Can't determine a major version at all -- be conservative, don't delete.
                $toSkip += $tag
                continue
            }

            $major = [int]$majorMatch.Groups['major'].Value
            if ($major -lt $MaxMajorVersion) {
                $toDelete += $tag
            } else {
                $toSkip += $tag
            }
        }

        return [PSCustomObject]@{
            Keep   = $toKeep
            Skip   = $toSkip
            Delete = $toDelete
        }
    }

    function WriteCleanupSummary {
        param(
            [string[]]$Keep,
            [string[]]$Skip,
            [string[]]$Delete,
            [int]$MaxMajorVersion
        )

        Write-Host "`nReleases to KEEP ($($Keep.Count)):" -ForegroundColor Green
        $Keep | Sort-Object | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }

        Write-Host "`nReleases SKIPPED - major version >= $MaxMajorVersion, or unparseable ($($Skip.Count)):" -ForegroundColor Yellow
        $Skip | Sort-Object | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }

        Write-Host "`nReleases to DELETE - major version < $MaxMajorVersion ($($Delete.Count)):" -ForegroundColor Red
        $Delete | Sort-Object | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }

    function RequestDeleteConfirmation {
        param(
            [string]$Message,
            [switch]$Force
        )

        if ($Force -or $WhatIfPreference) {
            return $true
        }

        $confirmation = Read-Host "`n$Message"
        return $confirmation -eq 'yes'
    }

    function RemoveReleaseAssets {
        param(
            [string]$Tag,
            [string[]]$RepoArgs
        )

        try {
            $viewJson = gh release view $Tag @RepoArgs --json assets 2>$null
            if ($LASTEXITCODE -eq 0 -and $viewJson) {
                $assets = ($viewJson | ConvertFrom-Json).assets
                foreach ($asset in $assets) {
                    Write-Host "  Deleting asset: $($asset.name)" -ForegroundColor DarkGray
                    gh release delete-asset $Tag $asset.name @RepoArgs --yes 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        Write-Warning "    Failed to delete asset '$($asset.name)' for $Tag"
                    }
                }
            }
        } catch {
            Write-Warning "  Could not enumerate/delete assets for ${Tag}: $_"
        }
    }

    function RemoveReleaseAndTag {
        param(
            [string]$Tag,
            [string[]]$RepoArgs
        )

        Write-Host "  Deleting release + remote tag $Tag..." -ForegroundColor DarkGray
        gh release delete $Tag @RepoArgs --yes --cleanup-tag 2>$null
        if ($LASTEXITCODE -ne 0) {
            # No release for this tag (or already gone). It may still exist as a bare
            # remote tag with no release, so try deleting the remote ref directly.
            Write-Host "  No release found for $Tag - trying remote tag ref directly..." -ForegroundColor DarkGray
            gh api "repos/{owner}/{repo}/git/refs/tags/$Tag" @RepoArgs -X DELETE 2>$null | Out-Null
        }

        # Local tag cleanup happens regardless of whether the remote side had
        # anything to delete, so purely local, un-released tags still get removed.
        $localTagExists = git tag --list $Tag
        if ($localTagExists) {
            Write-Host "  Deleting local tag $Tag..." -ForegroundColor DarkGray
            git tag -d $Tag | Out-Null
        }

        return $true
    }

    function RemoveRelease {
        param(
            [string]$Tag,
            [string[]]$RepoArgs,
            [System.Management.Automation.PSCmdlet]$Cmdlet
        )

        if (-not $Cmdlet.ShouldProcess($Tag, "Delete release assets, release, and tag (local+remote)")) {
            return
        }

        Write-Host "`nProcessing $Tag..." -ForegroundColor Cyan

        RemoveReleaseAssets -Tag $Tag -RepoArgs $RepoArgs
        $ok = RemoveReleaseAndTag -Tag $Tag -RepoArgs $RepoArgs

        if ($ok) {
            Write-Host "  Done: $Tag" -ForegroundColor Green
        }
    }

    # --- Setup ---------------------------------------------------------

    $ErrorActionPreference = 'Stop'

    AssertPrerequisites

    # Guard: only DELETE releases whose major version number is less than this value.
    # Anything with major >= this is left alone (treated as "skipped", not deleted),
    # even if it would otherwise be a delete candidate. Useful for testing on early
    # major versions before trusting the script against your whole history.
    # Set this to a very high number (e.g. 999999) to effectively disable the guard.
    # Not applied when -Tag is supplied.
    $MaxMajorVersion = 6

    $repoArgs = @()
    if ($Repo) { $repoArgs = @('--repo', $Repo) }

    # Resolve owner/repo up front (needed for the raw `gh api` tag-deletion call).
    $ownerRepo = ResolveOwnerRepo -Repo $Repo

    Write-Host "Target repo: $ownerRepo" -ForegroundColor Cyan

    $script:performedCleanup = $false
}
Process
{
    if ($Tag) {
        Write-Host "Single-tag mode: $Tag" -ForegroundColor Cyan

        $confirmed = RequestDeleteConfirmation -Force:$Force `
            -Message "Type 'yes' to permanently delete release '$Tag', its assets, and tag (local + remote)"
        if (-not $confirmed) {
            Write-Host "Aborted. No changes made." -ForegroundColor Yellow
            return
        }

        RemoveRelease -Tag $Tag -RepoArgs $repoArgs -Cmdlet $PSCmdlet
        $script:performedCleanup = $true
        return
    }

    Write-Host "Fetching releases..." -ForegroundColor Cyan
    $releases = GetReleaseList -RepoArgs $repoArgs -Limit $Limit

    if (-not $releases -or $releases.Count -eq 0) {
        Write-Host "No releases found." -ForegroundColor Yellow
        return
    }

    $groups = GroupReleasesForCleanup -Releases $releases -MaxMajorVersion $MaxMajorVersion

    WriteCleanupSummary -Keep $groups.Keep -Skip $groups.Skip -Delete $groups.Delete -MaxMajorVersion $MaxMajorVersion

    if ($groups.Delete.Count -eq 0) {
        Write-Host "`nNothing to delete. Done." -ForegroundColor Yellow
        return
    }

    $confirmed = RequestDeleteConfirmation -Force:$Force `
        -Message "Type 'yes' to permanently delete $($groups.Delete.Count) release(s), their assets, and tags (local + remote)"
    if (-not $confirmed) {
        Write-Host "Aborted. No changes made." -ForegroundColor Yellow
        return
    }

    foreach ($tag in $groups.Delete) {
        RemoveRelease -Tag $tag -RepoArgs $repoArgs -Cmdlet $PSCmdlet
    }

    $script:performedCleanup = $true
}
End
{
    if ($script:performedCleanup) {
        Write-Host "`nCleanup complete." -ForegroundColor Cyan
    }
}
