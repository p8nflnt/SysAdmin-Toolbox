<#
.VERSION 
    1.2
 
.AUTHOR 
    Aaron Guilmette, Payton Flint
 
.DESCRIPTION 
    Modification of Aaron Guilmette's script to disable Teams Auto-run.

.LINK
    (v1.1) https://www.powershellgallery.com/packages/Disable-TeamsAutorun/1.1/Content/Disable-TeamsAutorun.ps1

.SYNOPSIS Disable Teams autorun
 
.NOTES
- 2023-11-29 - v1.2: Updated to stop Teams process before making modifications.
- 2020-04-20 - Updated for PowerShell Gallery.
- 2019-08-12 - Original release.
#>

# Get all processes w/ name 'Teams'
$teamsProcs = Get-Process -Name 'Teams' -EA SilentlyContinue

# If Teams autorun entry exists, remove it
$TeamsAutoRun = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -ea SilentlyContinue)."com.squirrel.Teams.Teams"
if ($TeamsAutoRun){
    # Stop all found 'Teams' processes & wait for exit
    If ($teamsProcs -ne $null) {
        $teamsProcs | Stop-Process -Force -EA SilentlyContinue
        $teamsProcs | Wait-Process -Timeout 30 -EA SilentlyContinue
    }  
    Remove-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "com.squirrel.Teams.Teams"
}

# Teams Config Data
$TeamsConfig = "$env:APPDATA\Microsoft\Teams\desktop-config.json"
$global:TeamsConfigData = Get-Content $TeamsConfig -Raw -ea SilentlyContinue | ConvertFrom-Json

# If Teams already doesn't have the autostart config, exit
If ($TeamsConfigData) {
    If ($TeamsConfigData.appPreferenceSettings.openAtLogin -eq $false) {
        # It's already configured to not startup
        exit
    } else {
        # If Teams hasn't run, then it's not going to have the openAtLogin:true value
        # Otherwise, replace openAtLogin:true with openAtLogin:false
        If ($TeamsConfigData.appPreferenceSettings.openAtLogin -eq $true) {
            $TeamsConfigData.appPreferenceSettings.openAtLogin = $false
        # If Teams has been intalled but hasn't been run yet, it won't have an autorun setting
        } else {
            $Values = ($TeamsConfigData.appPreferenceSettings | GM -MemberType NoteProperty).Name
            If ($Values -match "openAtLogin") {
                $TeamsConfigData.appPreferenceSettings.openAtLogin = $false
            } else {
                $TeamsConfigData.appPreferenceSettings | Add-Member -Name "openAtLogin" -Value $false -MemberType NoteProperty
            }
        }

        # Stop all found 'Teams' processes & wait for exit
        If ($teamsProcs -ne $null) {
            $teamsProcs | Stop-Process -Force -EA SilentlyContinue
            $teamsProcs | Wait-Process -Timeout 30 -EA SilentlyContinue
        }

        # Save
        $TeamsConfigData | ConvertTo-Json -Depth 100 | Out-File -Encoding UTF8 -FilePath $TeamsConfig -Force
    }
}
