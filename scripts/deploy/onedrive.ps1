Write-Host "Deploying to OneDrive"

rclone copy dist/trigger.exe onedrive:/Shares/ahk_Trigger_phil
rclone copy dist/trigger.exe onedrive:/Shares/ahk_Trigger_papa