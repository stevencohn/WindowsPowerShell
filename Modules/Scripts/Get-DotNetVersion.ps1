<#
.SYNOPSIS
Get the version of.NET Framework installations on the local computer

.DESCRIPTION
Note that when new versions are released then the lookup table needs to be updated.
#>

Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Version,Release -EA 0 |
Where { $_.PSChildName -match '^(?!S)\p{L}'} |
Select PSChildName, Version, Release, @{
  name="Product"
  expression={
      switch -regex ($_.Release) {
        "378389" { [Version]"4.5" }
        "378675|378758" { [Version]"4.5.1" }
        "379893" { [Version]"4.5.2" }
        "393295|393297" { [Version]"4.6" }
        "394254|394271" { [Version]"4.6.1" }
        "394802|394806" { [Version]"4.6.2" }
        "460798|460805" { [Version]"4.7" }
        "461308|461310" { [Version]"4.7.1" }
        "461808|461814" { [Version]"4.7.2" }
        {$_ -gt 461310} { [Version]"Undocumented version (> 4.7.2), please update script" }
      }
    }
}
