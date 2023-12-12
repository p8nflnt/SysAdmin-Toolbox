# common startup dir
$commonStartup = "$env:SystemDrive\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"

# name of startup exe
$startupExe = "Disable-TeamsAutorun.exe"

# startup exe in common startup dir
$commonStartupExe = Join-Path $commonStartup $startupExe

# if startup exe present in common startup dir, return installed
if (Test-Path $commonStartupExe){
    "Installed"
}
