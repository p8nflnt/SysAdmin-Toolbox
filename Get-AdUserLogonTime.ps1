<#
.SYNOPSIS
    Retrieve last logon time information for an AD user.

.NOTES
    Name: Get-AdUserLogonTime.ps1
    Author: Payton Flint
    Version: 1.0
    DateCreated: 2023-Sep

.LINK
    https://github.com/p8nflnt/SysAdmin-Toolbox/blob/main/Get-AdUserLogonTime.ps1
#>

Function Get-AdUserLogonTime {
    param (
        $name
    )

    $info = Get-ADUser -Properties lastLogon, lastLogonTimestamp -Filter "Name -eq '$name'" `
    | Select-Object  name, userPrincipalName, lastLogon, lastLogonTimestamp

    $userPrincipalName  = $info.userPrincipalName
    $lastLogon          = [datetime]::FromFileTime($info.lastLogon)
    $lastLogonTimestamp = [datetime]::FromFileTime($info.lastLogonTimestamp)

    $userObj = [PSCustomObject]@{
        Name               = "$name"
        userPrincipalName  = "$userPrincipalName"
        lastLogon          = "$lastLogon"
        lastLogonTimestamp = "$lastLogonTimestamp"
    }

    return $userObj
}

$result = Get-AdUserLogonTime -name '<INSERT USER NAME>'
