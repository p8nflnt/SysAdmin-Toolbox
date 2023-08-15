<#
.SYNOPSIS
    Get Primary User information for a domain-joined computer
    Not to be confused w/ ConfigMan's Get-CMUserDeviceAffinity

.NOTES
    Name: Get-UserDeviceAffinity
    Author: Payton Flint
    Version: 1.0
    DateCreated: 2023-August

.LINK
    https://paytonflint.com/powershell-programmatically-determine-the-primary-user-of-a-device/
    https://github.com/p8nflnt/SysAdmin-Toolbox/blob/main/Get-UserDeviceAffinity.ps1
#>

Function Get-UserDeviceAffinity {
    # Get computer name
    $ComputerName = $env:COMPUTERNAME

    If ($ComputerName -ne $null) {
        # Get current domain name
        $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        $Domain = $Domain.Name
        # Drop domain suffix & convert to uppercase
        $Domain = (($Domain.Split('.')[0]).ToUpper())

        # Get Events w/ ID 4624 (Logon) that match Logon Types: 2
        $LogonType2 = Get-EventLog -LogName Security -ComputerName $ComputerName -ErrorAction SilentlyContinue -InstanceId 4624 -Message `
        "*`r`n	Logon Type:		2`r`n	Restricted*	Account Domain:		$Domain`r`n	Logon*	Logon GUID:		{00000000-0000-0000-0000-000000000000}`r`n*" # Message filter

        # Get Events w/ ID 4624 (Logon) that match Logon Type: 10
        $LogonType10 = Get-EventLog -LogName Security -ComputerName $ComputerName -ErrorAction SilentlyContinue -InstanceId 4624 -Message `
        "*`r`n	Logon Type:		10`r`n	Restricted*	Account Domain:		$Domain`r`n	Logon*	Logon GUID:		{00000000-0000-0000-0000-000000000000}`r`n*" # Message filter

        # Combine events w/ Types 2 & 10
        $LogonEvents = $LogonType2 + $LogonType10

        # Continue only if events matching specified profile are present
        If ($LogonEvents -ne $null) {
            # Create UserSessions array
            $UserSessions = @()

            $LogonEvents | ForEach-Object {
                # Use regex to extract AccountName from message
                $pattern = "(?<=New Logon:\s*\r?\n[\s\S]*Account Name:\s+)(\S+)"
                If ($_.Message -match $pattern) {
                    $AccountName = $matches[1]
                }
                # Use regex to extract LogonID from message
                $pattern = "(?<=New Logon:\s*\r?\n[\s\S]*Logon ID:\s+)(\S+)"
                If ($_.Message -match $pattern) {
                    $LogonID = $matches[1]
                }
                # Get computer name
                $ComputerName = ($_.MachineName.Split('.')[0])

                # Get session end
                $SessionEnd = Get-EventLog -LogName Security -ComputerName $ComputerName -ErrorAction SilentlyContinue -InstanceId 4634,4647 -Message `
                "*`r`n	Logon ID:		$LogonID`r`n*" # Message filter

                # Derive session duration
                If ($SessionEnd -ne $null) {
                    $SessionDuration = $SessionEnd.TimeGenerated - $_.TimeGenerated
                } Else {
                    $SessionDuration = 0
                }
                # Create new session object & add properties
                $SessionObject = New-Object PSObject -Property @{
                    LogonTime =           $_.TimeGenerated
                    AccountName =         $AccountName
                    LogonID =             $LogonID
                    SessionDuration =     $SessionDuration
                    ComputerName =        $ComputerName
                    LogoffTime =          $SessionEnd.TimeGenerated
                }
                # Add session objects to array
                $UserSessions += $SessionObject
            }
            # Group user sessions by account name
            $AcctSessions = $UserSessions | Group-Object -Property AccountName

            # Group user sessions by account name
            $AcctSessions | ForEach-Object {
                $_.Group | ForEach-Object {
                    $TotalDuration += $_.SessionDuration
                }
                # Add total duration of user sessions to each account name group
                $_ | Add-Member -NotePropertyName 'TotalDuration' -NotePropertyValue $TotalDuration
                $TotalDuration = $null
            }
            # Determine the value of the greatest total session duration per user account
            $GreatestDuration = ($AcctSessions | Measure-Object -Property TotalDuration -Maximum).Maximum

            # Filter the array to get the object(s) with the highest weight
            $PrimaryUser = $AcctSessions | Where-Object { $_.TotalDuration -eq $GreatestDuration }
            # Get username
            $UserName = $PrimaryUser.Name
            # Get AD User object
            $ADUser =   Get-AdUser -Filter {SamAccountName -eq $UserName} -ErrorAction SilentlyContinue
            $ADName =   $ADUser | Select-Object -ExpandProperty Name

            # Format output
            Write-Output "Username	: $UserName`r`nName	: $ADName"
        }
    }
} # End Function Get-UserDeviceAffinity

# Execute function
$PrimaryUser = Get-UserDeviceAffinity -ComputerName "$env:COMPUTERNAME"
# Return result
$PrimaryUser
