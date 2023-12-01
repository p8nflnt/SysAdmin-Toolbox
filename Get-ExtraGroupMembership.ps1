<#
.SYNOPSIS
    Get report of extraneous group membership for users in a specified OU for AD cleanup.
    
.NOTES
    Name: Get-ExtraGroupMembership
    Author: Payton Flint
    Version: 1.0
    DateCreated: 2023-Nov
    
.LINK
    https://
#>

$scriptPath = Split-Path ($MyInvocation.MyCommand.Path) -Parent

$ouPath = "<OU PATH>"

$expectedGroups = "<Group1>", "<Group2>", "<Group3>"

Function Get-ExtraGroupMembership {
    param (
        $user,
        $expectedGroups
    )
    $userGroups = (Get-ADPrincipalGroupMembership -Identity $user).Name | Where-Object { $_ -notin $expectedGroups }

    $results = @()

    If ($userGroups) {
        
        ForEach ($group in $userGroups) {
            $results += [PSCustomObject]@{
                'User'   = $user.Name
                'Groups' = $group
            }
        }
    }
    $results
}

$users = Get-ADUser -filter * -SearchBase "$ouPath"
 
$table = $users | ForEach-Object {
    Get-ExtraGroupMembership -user $_ -expectedGroups $expectedGroups
}

$table `
| Sort-Object -Property User `
| Export-Csv -Path "$scriptPath\extraGroupMembership.csv" -Force -NoTypeInformation
