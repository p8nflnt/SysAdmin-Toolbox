# identify location of script
$scriptPath = Split-Path ($MyInvocation.MyCommand.Path) -Parent

# common startup dir
$commonStartup = "$env:SystemDrive\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"

# exe name
$exeName = "Disable-TeamsAutorun.exe"

# exe @ script root
$rootExe = Join-Path $scriptPath $exeName

# copy exe to common startup dir
$rootExe | Copy-Item -Destination $commonStartup -Force -ErrorAction SilentlyContinue
