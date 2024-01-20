Write-Host "Deploying to OneDrive"

rclone copy dist/trigger-new.exe onedrive:/Shares/ahk_Trigger_phil
rclone copy dist/trigger-new.exe onedrive:/Shares/ahk_Trigger_papa