# Identify location of script
$scriptPath = Split-Path ($MyInvocation.MyCommand.Path) -Parent

$userInfo = Get-ADUser -Filter * -SearchBase "dc=<DOMAIN>" -Properties Name, Enabled, UserPrincipalName `
| Where-Object {$_.Enabled -ne $False} `
| Select-Object Name, UserPrincipalName `
| Sort-Object Name

$userInfo | Export-Csv -Path "$scriptPath\Get-AllEnabledAdUsers_Output.csv" -Force -NoTypeInformation
