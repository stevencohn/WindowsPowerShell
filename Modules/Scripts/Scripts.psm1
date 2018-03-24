$env:PATH += ";$psScriptRoot"

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    $env:PATH = $env:PATH.Replace(";$psScriptRoot", "")
}
