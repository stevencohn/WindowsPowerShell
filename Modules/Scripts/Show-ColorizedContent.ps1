param(
    $filename = $(throw "Please specify a filename."),
    $highlightRanges = @(),
    [System.Management.Automation.SwitchParameter] $excludeLineNumbers)

# [Enum]::GetValues($host.UI.RawUI.ForegroundColor.GetType()) | % { Write-Host -Fore $_ "$_" }
$replacementColours = @{ 
    "Command"="Yellow";
    "CommandParameter"="DarkGray";
    "Variable"="Gray" ;
    "Operator"="DarkGray";
    "Grouper"="DarkGray";
    "StatementSeparator"="DarkGray";
    "String"="Magenta";
    "Number"="DarkCyan";
    "CommandArgument"="DarkBlue";
    "Keyword"="Blue";
    "Attribute"="DarkBlue";
    "Property"="DarkBlue";
    "Member"="DarkBlue";
    "Type"="DarkYellow";
    "Comment"="DarkGreen";
}
$highlightColor = "Green"
$highlightCharacter = ">"

## Read the text of the file, and parse it
$file = (Resolve-Path $filename).Path
$content = [IO.File]::ReadAllText($file)
$parsed = [System.Management.Automation.PsParser]::Tokenize($content, [ref] $null) | 
    Sort StartLine,StartColumn

function WriteFormattedLine($formatString, [int] $line)
{
    if($excludeLineNumbers) { return }
    
    $hColor = "DarkGray"
    $separator = "|"
    if($highlightRanges -contains $line) { $hColor = $highlightColor; $separator = $highlightCharacter }
    Write-Host -NoNewLine -Fore $hColor ($formatString -f $line,$separator)
}

Write-Host

WriteFormattedLine "{0:D3} {1} " 1

$column = 1
foreach($token in $parsed)
{
    $color = "Gray"

    ## Determine the highlighting colour
    $color = $replacementColours[[string]$token.Type]
    if(-not $color) { $color = "Gray" }

    ## Now output the token
    if(($token.Type -eq "NewLine") -or ($token.Type -eq "LineContinuation"))
    {
        $column = 1
        Write-Host

	WriteFormattedLine "{0:D3} {1} " ($token.StartLine + 1)
    }
    else
    {
        ## Do any indenting
        if($column -lt $token.StartColumn)
        {
            Write-Host -NoNewLine (" " * ($token.StartColumn - $column))
        }

        ## See where the token ends
        $tokenEnd = $token.Start + $token.Length - 1

        ## Handle the line numbering for multi-line strings
        if(($token.Type -eq "String") -and ($token.EndLine -gt $token.StartLine))
        {
            $lineCounter = $token.StartLine
            $stringLines = $(-join $content[$token.Start..$tokenEnd] -split "`r`n")
            foreach($stringLine in $stringLines)
            {
                if($lineCounter -gt $token.StartLine)
                {
                    WriteFormattedLine "`n{0:D3} {1}" $lineCounter
                }
                Write-Host -NoNewLine -Fore $color $stringLine
                $lineCounter++
            }
        }
        ## Write out a regular token
        else
        {
            Write-Host -NoNewLine -Fore $color (-join $content[$token.Start..$tokenEnd])
        }

        ## Update our position in the column
        $column = $token.EndColumn
    }
}

Write-Host "`n"