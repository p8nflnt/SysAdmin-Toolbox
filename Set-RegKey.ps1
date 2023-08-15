<#
.SYNOPSIS
    Set registry key to your desired value & return action taken 
    (w/ silent option)

.NOTES
    Name: Set-RegKey
    Author: Payton Flint
    Version: 1.1
    DateCreated: 2023-Aug

.LINK
    https://paytonflint.com/powershell-add-modify-registry-key/
    https://github.com/p8nflnt/SysAdmin-Toolbox/blob/main/Set-RegKey.ps1
#>


$regPath  = ‘<INSERT PATH>'
$regName  = ‘<INSERT NAME>'
$regValue = ‘<INSERT VALUE>'

Function Set-RegKey {
    param(
    $regPath,
    $regName,
    $regValue,
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
                        New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType DWORD -Force | Out-Null
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
                    New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType DWORD -Force | Out-Null
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
} # End Function Set-RegKey

Set-RegKey -regPath $regPath -regName $regName -regValue $regValue -silent <BOOL>
