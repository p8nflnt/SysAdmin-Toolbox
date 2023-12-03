<#
.SYNOPSIS
    Convert canonical name to distinguished name format or vice versa.

.NOTES
    Name: Convert-AdName
    Author: Payton Flint
    Version: 1.0
    DateCreated: 2023-Dec

.LINK
    https://github.com/p8nflnt/SysAdmin-Toolbox/edit/main/Convert-AdName.ps1
    https://paytonflint.com/powershell-active-directory-convert-ad-name-formats/
#>

Function Convert-ADName {
    param (
        $name,
        $nameType
    )
    # check name formatting
    if ($name -like '*.*' -or $name -like '*/*' -or $name -like '*=*') {

        # Check if the input is a canonical name format
        if ($name -match "(^CN=.*|^OU=.*|^DC=.*)") {

            # replace characters for reformatting
            $processedCN = $name -replace ',', '' -replace 'DC=', '.' -replace 'OU=', '/' -replace 'CN=', ''

            # drop leading '/' if present
            if ($processedCN -match "^/.*") {
                $processedCN = ($processedCN -split '\/', 2)[1]
            }

            # split canonical name in 2 parts at first '.'
            $splitCN = $processedCN -split '\.', 2

            # domain portion of canonical name
            $domain = $splitCN[1]

            # get remaining portion of canonical name if not empty
            if ($($splitCN[0]) -ne '') {

                # split remaining portion by '/' character
                $splitRemainder = $($splitCN[0]) -split '/'

                # invert order of the remaining items array
                $reversedRemainder = $splitRemainder[($splitRemainder.Length-1)..0]

                # reassemble in canonical name format for output
                $output = $domain + '/' + ($reversedRemainder -join '/')

            # if remainder is empty, list domain
            } else {
                $output = $domain 
            }
        # if input is distinguished name format
        } else {
        
            # alert user to provide input type
            if ($nameType -ne 'container' -and $nameType -ne 'object') {
                Write-Host -ForegroundColor Red "Distinguished name format detected.`r`n-inputType must be set to 'Container' or 'Object'."
            }

            # glitch in replace, had to invoke method this way
            # replace characters for reformatting
            $processedDN = $($name -replace '/', ',OU=').Replace('.', ',DC=')

            # if 'OU=' is present
            if ($processedDN -match ".*OU=.*") {

                # split in 2 parts at first ',OU='
                $splitDN = $processedDN -split '\,OU=', 2

                # domain portion of distinguished name
                $domain = $splitDN[0]

                # split remaining portion by ',OU='
                $splitRemainder = $($splitDN[1]) -split ',OU='

                # invert order of the remaining items array
                $reversedRemainder = $splitRemainder[($splitRemainder.Length-1)..0]

                # reassemble in distinguished name format for output
                $reassembledDN = ($reversedRemainder -join ',OU=') + ',DC=' + $domain

                # add appropriate prefix to distinguished name and output
                if ($nameType -eq 'object') {
                    $output = 'CN=' + $reassembledDN
                } elseif ($nameType -eq 'container' ) {
                    $output = 'OU=' + $reassembledDN
                }

            # if remainder is empty, list domain
            } else {
                $output = 'DC=' + $processedDN
            }
        }
    return $output
    # warn on invalid name format
    } else {
        Write-Host -ForegroundColor Red "Invalid name format."
    }
} # end Convert-ADName function


# variables
$distinguishedName = "entity.domain.org/Test/Computers/TEST-SYS1"

$canonicalName = "CN=TEST-SYS1,OU=Computers,OU=TEST,DC=entity,DC=domain,DC=org"

$nameType = 'object' # 'container'


# example use
$output = Convert-ADName -name $distinguishedName -nameType $nameType

$output
