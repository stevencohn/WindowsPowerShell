
function Test-Administrator
{
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# set the prompt to a colorized string customized by elevation
function prompt
{
    $saveCode = $LASTEXITCODE
    if (Test-Administrator)
    {
        Write-Host "PS " -NoNewline -ForegroundColor Red
        Write-Host $pwd -NoNewline -ForegroundColor Blue
    }
    else
    {
        Write-Host "PS $pwd" -NoNewline -ForegroundColor Blue
    }

    $global:LASTEXITCODE = $saveCode
    return "> "
}


# ---------------------------------------------------------------------------------------
# su
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# open a new command prompt in elevated mode - alias 'su'
function Invoke-SuperUser { conemu /single /cmd -cur_console:an powershell }
New-Alias su Invoke-SuperUser


# ---------------------------------------------------------------------------------------
# vs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# invoke the Visual Studio environment batch script - alias 'vs'
function Invoke-VsDevCmd
{
    pushd "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Enterprise\Common7\Tools"

    cmd /c "VsDevCmd.bat&set" | foreach `
    {
        if ($_ -match "=")
        {
            $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
        }
    }

    popd
}
New-Alias vs Invoke-VsDevCmd


# run vsdevcmd.bat if $env:vsdev is set; this is done by conemu task definition
if ($env:vsdev -eq '1')
{
    Invoke-VsDevCmd
}

# ---------------------------------------------------------------------------------------
# Docker
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# prune unused docker objects
function Invoke-DockerClean
{
    Write-Host
    $trash = $(docker ps -a -q)
    if ($trash -ne $null)
    {
        Write-Host ('Removing {0} stopped containers...' -f $trash.Count) -ForegroundColor DarkYellow
        docker container prune
    }
    else
    {
        Write-Host "No stopped containers" -ForegroundColor DarkYellow
    }

    Write-Host
    $trash = $(docker images --filter "dangling=true" -q --no-trunc)
    if ($trash -ne $null)
    {
        Write-Host ('Removing {0} dangling images...' -f $trash.Count) -ForegroundColor DarkYellow
        docker rmi $trash
    }
    else
    {
        Write-Host "No dangling images" -ForegroundColor DarkYellow
    }

    Write-Host
}
New-Alias doclean Invoke-DockerClean


function Invoke-DockerShow
{
    Write-Host
    Write-Host 'Containers...' -ForegroundColor DarkYellow
    docker ps -a
    Write-Host
    Write-Host 'Images...' -ForegroundColor DarkYellow
    docker images
    Write-Host
}
New-Alias doshow Invoke-DockerShow


# Win-X-I and Win-X-A will open in %userprofile% and %systemrootm%\system32 respectively
# instead set location to root of current drive
Set-Location \
