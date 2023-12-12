# common startup dir
$commonStartup = "$env:SystemDrive\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"

# exe name
$exeName = "Disable-TeamsAutorun.exe"

# startup script in common startup dir
$commonStartupExe = Join-Path $commonStartup $exeName

# if startup script present in common startup dir, remove it from common startup dir
if (Test-Path $commonStartupExe){
    Remove-Item -Path $commonStartupExe -Force -ErrorAction SilentlyContinue
}

<#
.VERSION 
    1.0
 
.AUTHOR 
    Payton Flint
 
.DESCRIPTION 
    Enable Teams Auto-run.

.LINK
    N/A

.SYNOPSIS Enable Teams autorun
 
.NOTES
- 2023-11-29 - Original release.
#>

# Define Set-RegKey params
$regPath  = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
$regName  = 'com.squirrel.Teams.Teams'
$regValue = "$env:UserProfile\AppData\Local\Microsoft\Teams\Update.exe --processStart `"Teams.exe`" --process-start-args `"--system-initiated`""
$propType = 'String'

# Set-RegKey function
Function Set-RegKey {
    param(
    $regPath,
    $regName,
    $regValue,
    $propType,
    [bool]$silent
    )
    $regFull = Join-Path $regPath $regName
        Try {
                $CurrentKeyValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
                If (Test-Path $regPath) {
                    If ($CurrentKeyValue -eq $regValue) {
                        If (!($silent)) {
                            Write-Host -ForegroundColor Green 'Registry key' $regFull 'value is set to the desired value of' $regValue'.'
                        }
                        $script:regTest = $True  
                    } Else {
                        If (!($silent)) {
                            Write-Host -ForegroundColor Red 'Registry key' $regFull 'value is not' $regValue'.'
                            Write-Host -ForegroundColor Cyan 'Setting registry key' $regFull 'value to' $regValue'.'
                        }
                        New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType $propType -Force | Out-Null
                        $CurrentKeyValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
                        If ($CurrentKeyValue -eq $regValue) {
                            If (!($silent)) {
                                Write-Host -ForegroundColor Green 'Registry key' $regFull 'value is set to the desired value of' $regValue'.'
                            }
                            $script:regTest = $True  
                        } Else {
                            If (!($silent)) {
                                Write-Host -ForegroundColor Red 'Registry key' $regFull 'value could not be set to' $regValue '.'
                            }
                        }
                    }
                } Else {
                    If (!($silent)) {
                        Write-Host -ForegroundColor Red 'Registry key' $regFull 'path does not exist.'
                        Write-Host -ForegroundColor Cyan 'Creating registry key' $regFull'.'
                    }
                    New-Item -Path $regPath -Force | Out-Null
                    If (!($silent)) {
                        Write-Host -ForegroundColor Cyan 'Setting registry key' $regFull 'value to' $regValue'.'
                    }
                    New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType $propType -Force | Out-Null
                    $CurrentKeyValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
                    If ($CurrentKeyValue -eq $regValue) {
                        If (!($silent)) {
                            Write-Host -ForegroundColor Green 'Registry key' $regFull 'value is set to the desired value of' $regValue'.'
                        }
                        $script:regTest = $True  
                    } Else {
                        If (!($silent)) {
                            Write-Host -ForegroundColor Red 'Registry key' $regFull 'value could not be set to' $regValue '.'
                        }
                    }
                }
        } Catch {
            If (!($silent)) {
                Write-Host -ForegroundColor Red 'Registry key' $regFull 'value could not be set to' $regValue '.'
            }
        }
} # End Set-RegKey Function

# Get all processes w/ name 'Teams'
$teamsProcs = Get-Process -Name 'Teams' -EA SilentlyContinue

# If Teams autorun entry exists, remove it
$TeamsAutoRun = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -ea SilentlyContinue)."com.squirrel.Teams.Teams"
if (!($TeamsAutoRun)){
    # Stop all found 'Teams' processes & wait for exit
    If ($teamsProcs -ne $null) {
        $teamsProcs | Stop-Process -Force -EA SilentlyContinue
        $teamsProcs | Wait-Process -Timeout 30 -EA SilentlyContinue
    }  
    Set-RegKey -regPath $regPath -regName $regName -regValue $regValue -propType $propType -silent $true
}

# Teams Config Data
$TeamsConfig = "$env:APPDATA\Microsoft\Teams\desktop-config.json"
$global:TeamsConfigData = Get-Content $TeamsConfig -Raw -ea SilentlyContinue | ConvertFrom-Json

# If Teams already doesn't have the autostart config, exit
If ($TeamsConfigData) {
    If ($TeamsConfigData.appPreferenceSettings.openAtLogin -eq $true) {
        # It's already configured to not startup
        exit
    } else {
        # If Teams hasn't run, then it's not going to have the openAtLogin:true value
        # Otherwise, replace openAtLogin:true with openAtLogin:false
        If ($TeamsConfigData.appPreferenceSettings.openAtLogin -eq $false) {
            $TeamsConfigData.appPreferenceSettings.openAtLogin = $true
        # If Teams has been intalled but hasn't been run yet, it won't have an autorun setting
        } else {
            $Values = ($TeamsConfigData.appPreferenceSettings | GM -MemberType NoteProperty).Name
            If ($Values -match "openAtLogin") {
                $TeamsConfigData.appPreferenceSettings.openAtLogin = $true
            } else {
                $TeamsConfigData.appPreferenceSettings | Add-Member -Name "openAtLogin" -Value $true -MemberType NoteProperty
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
