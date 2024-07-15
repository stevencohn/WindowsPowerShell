[CmdletBinding(SupportsShouldProcess = $true)]

param()

Begin
{
    $stringType = [String]::Empty.GetType()

    function Decode
    {
        param ($encoded, [Switch]$x64)
        $map = "BCDFGHJKMPQRTVWXY2346789" 
        $decoded = ""
        $key = $encoded[0x34..0x42]
        for ($i = 24; $i -ge 0; $i--) 
        { 
            $r = 0 
            for ($j = 14; $j -ge 0; $j--) 
            {
                $r = ($r * 256) -bxor $key[$j] 
                $key[$j] = [math]::Floor([double]($r / 24)) 
                $r = $r % 24 
            } 
            $decoded = $map[$r] + $decoded 
            if (($i % 5) -eq 0 -and $i -ne 0)
            { 
                $decoded = "-" + $decoded
            }
        }
        $decoded
    }

    function Report
    {
        param($path, $keys)
        Write-Host "`n$path" -ForegroundColor DarkYellow
        $keys | foreach {
            Write-Host "$_ " -NoNewline -ForegroundColor DarkGray
            $value = (Get-ItemPropertyValue $path -Name $_)
            if ($value.GetType() -ne $stringType) { $value = Decode $value }
            Write-Host $value
        }    
    }
}
Process
{
    Write-Host
    Write-Host 'WMI OS'
    Get-CimInstance -ComputerName . Win32_OperatingSystem

    Write-Host "`nWMI Method: (real?)" -ForegroundColor DarkYellow
    Write-Host ((Get-CimInstance -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey) -ForegroundColor DarkGray

    Report 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform' 'BackupProductKeyDefault'
    Report 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'DigitalProductID'
    Report 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' @('DigitalProductID', 'DigitalProductID4')
    Report 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DefaultProductKey' @('DigitalProductID', 'DigitalProductID4')
    Report 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DefaultProductKey2' @('DigitalProductID', 'DigitalProductID4')
    
    # QVNJM-KDJPR-9KDD9-K8PJ6-C9XTT
}
