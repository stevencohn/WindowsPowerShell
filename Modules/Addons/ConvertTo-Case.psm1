<#
.SYNOPSIS
Convert selected text, or current character, to uppercase or lowercase.

.PARAMETER Upper
If specified then converts to uppercase; default is to convert to lowercase
#>

function ConvertTo-Case ([switch] $Upper)
{
    $editor = $psISE.CurrentFile.Editor
    if ($editor.SelectedText -and ($editor.SelectedText.Length -gt 0))
    {
        # InsertText overwrites selected text
        $converted = if ($upper) { $editor.SelectedText.ToUpper() } else { $editor.SelectedText.ToLower() }
        $editor.InsertText($converted)
        $editor.SetCaretPosition($editor.CaretLine, $editor.CaretColumn + $editor.SelectedText.Length)
    }
    else
    {
        $col = $editor.CaretColumn
        if ($col -lt $editor.CaretLineText.Length)
        {
            $editor.Select($editor.CaretLine, $col, $editor.CaretLine, $col + 1)
            $converted = if ($upper) { $editor.SelectedText.ToUpper() } else { $editor.SelectedText.ToLower() }
            $editor.InsertText($converted)
            $editor.SetCaretPosition($editor.CaretLine, $col + 1)
        }
    }
}
