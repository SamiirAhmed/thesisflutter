$vbsPath = "d:\xamp\htdocs\thesisflutter\Manage_App.bat"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutName = "Thesis_App_Manager.lnk"
$shortcutPath = Join-Path $startupFolder $shortcutName

# Remove any old versions to avoid conflicts
$oldLink1 = Join-Path $startupFolder "Thesis_App_SilentStart.lnk"
$oldLink2 = Join-Path $startupFolder "Thesis_App_AutoStart.lnk"
$oldLink3 = Join-Path $startupFolder "Thesis_App.lnk"
if (Test-Path $oldLink1) { Remove-Item $oldLink1 }
if (Test-Path $oldLink2) { Remove-Item $oldLink2 }
if (Test-Path $oldLink3) { Remove-Item $oldLink3 }

# Create the NEW link to the all-in-one manager
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "cmd.exe"
$Shortcut.Arguments = "/c `"$vbsPath`" 1"
$Shortcut.WorkingDirectory = "d:\xamp\htdocs\thesisflutter"
$Shortcut.WindowStyle = 7 # Minimized
$Shortcut.Save()

Write-Host "Auto-start is now correctly pointing to the new Manage_App.bat!"
