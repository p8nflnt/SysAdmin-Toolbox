# Clear variables for repeatability
Get-Variable -Exclude PWD,*Preference | Remove-Variable -EA 0

# specify device on other side of tunnel (NetBIOS name recommended)
$endpoint = "<INSERT NAME>"

# specify ping frequency (in # of seconds)
$seconds = 300

# specify email notification frequency (in # of seconds)
$notifyFreq = 1800

# specify number attempts before notification
$attempts = 3

# Email notification parameters
$failParams = @{
    SmtpServer                 = '<INSERT SMTP SERVER>'
    Port                       = '25'
    UseSSL                     = $true   
    From                       = '<INSERT ADDRESS>'
    To                         = '<INSERT ADDRESS>'
    Subject                    = "FAILURE - VPN TEST - $(Get-Date -Format g)"
    Body                       = "VPN connection test from $env:COMPUTERNAME to $endpoint unsuccessful $(Get-Date -Format g)"
    DeliveryNotificationOption = 'OnFailure'#, 'OnSuccess'
    ErrorAction                = 'SilentlyContinue'
}

$restoredParams = @{
    SmtpServer                 = '<INSERT SMTP SERVER>'
    Port                       = '25'
    UseSSL                     = $true   
    From                       = '<INSERT ADDRESS>'
    To                         = '<INSERT ADDRESS>'
    Subject                    = "RESTORED - VPN TEST - $(Get-Date -Format g)"
    Body                       = "VPN connection from $env:COMPUTERNAME to $endpoint restored $(Get-Date -Format g)"
    DeliveryNotificationOption = 'OnFailure'#, 'OnSuccess'
    ErrorAction                = 'SilentlyContinue'
}

# infinite loop
While ($true) {
    # perform single, small, quiet ping of endpoint
    $Response = Test-Connection -ComputerName $endpoint -Count 1 -BufferSize 1 -Quiet

    # if pinging the endpoint is successful...
    If ($Response -eq $true) {
        Write-Host -ForegroundColor Green "Connection from $env:COMPUTERNAME to $endpoint successful   $(Get-Date -Format g)"

        # if in failure status, indicating connectivity restoration...
        If ($failure -eq $true) {
            Write-Host -ForegroundColor Green "Connection from $env:COMPUTERNAME to $endpoint restored     $(Get-Date -Format g)"
            # send email notification w/ above params
            Send-MailMessage @restoredParams
            Write-Host -ForegroundColor Green "Email notification sent"
            # get unix timestamp for email being sent
            $emailSent = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            # determine time of next email notification
            $nextMail = $emailSent + $notifyFreq
            # reset failure status
            $failure = $null
        }

    # if not...
    } Else {
        # count up
        $count++
        Write-Host -ForegroundColor Red "Connection from $env:COMPUTERNAME to $endpoint unsuccessful $(Get-Date -Format g)"
        # if current unix time is ≥ the next mail notification time and attempt threshold has been reached...
        if (([DateTimeOffset]::Now.ToUnixTimeSeconds()) -ge $nextMail -and $count -ge $attempts) {
            # set failure status
            $failure = $true
            # send email notification w/ above params
            Send-MailMessage @failParams
            Write-Host -ForegroundColor Red "Email notification sent"
            # get unix timestamp for email being sent
            $emailSent = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            # determine time of next email notification
            $nextMail = $emailSent + $notifyFreq
            # reset count
            $count = $null
        }
    }

    # wait number of seconds specified above
    Start-Sleep -Seconds $seconds
}
