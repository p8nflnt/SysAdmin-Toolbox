<#
.SYNOPSIS
    Return uninstall strings from the Windows registry to uninstall Win32 apps

.NOTES
    Name: Get-UninstallStringInfo
    Author: Payton Flint
    Version: 1.0
    DateCreated: 2023-Sep

.LINK
    https://paytonflint.com/
#>

function Get-UninstallStringInfo {
    param (
        [string]$regPath32 = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\",
        [string]$regPath64 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\"
    )

    # Get program information for both 32-bit and 64-bit registry paths
    $programInfo = @()

    foreach ($regPath in $regPath32, $regPath64) {
        $subkeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue

        foreach ($subkey in $subkeys) {
            $program = Get-ItemProperty -Path $subkey.PSPath -ErrorAction SilentlyContinue
                $dispName     = $program.DisplayName
                $dispVersion  = $program.DisplayVersion
                $publisher    = $program.Publisher
                $uninstall    = $program.UninstallString

            if ($dispName -ne $null -or $dispVersionion -ne $null -or $publisher -ne $null -or $uninstall -ne $null ) {
                $programInfo += [PSCustomObject]@{
                    "DisplayName"     = $dispName
                    "DisplayVersion"  = $dispVersion
                    "Publisher"       = $publisher
                    "UninstallString" = $uninstall
                }
            }
        }
    }

    # Sort the program information by DisplayName
    $programInfo = $programInfo | Sort-Object DisplayName

    # Output the sorted programInfo array
    return $programInfo
}

Get-UninstallStringInfo
