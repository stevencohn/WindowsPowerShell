
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

# open a new command prompt in elevated mode - alias 'su'
function Invoke-SuperUser { conemu /single /cmd -cur_console:an powershell }
New-Alias su Invoke-SuperUser


# invoke the Visual Studio environment batch script - alias 'vs'
function Invoke-VsDevCmd
{
    Push-Location "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Enterprise\Common7\Tools"

    cmd /c "VsDevCmd.bat&set" | ForEach-Object `
    {
        if ($_ -match "=")
        {
            $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
        }
    }

    Pop-Location
}
New-Alias vs Invoke-VsDevCmd


# run vsdevcmd.bat if $env:vsdev is set; this is done by conemu task definition
if ($env:vsdev -eq '1')
{
    Invoke-VsDev
}

# Win-X-I and Win-X-A will open in %userprofile% and %systemrootm%\system32 respectively
# instead set location to root of current drive
Set-Location \
