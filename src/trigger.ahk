;@Ahk2Exe-SetName Trigger
;@Ahk2Exe-SetVersion 2.5
;@Ahk2Exe-SetMainIcon assets/trigger.ico

#Requires AutoHotkey v2.0
#SingleInstance Off

#include <config>
#include <shortcuts>
#include <picker>
#include <editors>
#include <password>
#include <corrections>

Self_Update()
SetTimer(Self_Update, 10000)
Setup_Config()
Setup_Icon(cfg.icon)
Setup_TrayMenu()
Setup_CSV()
edts := Editors()
view := Picker(shorts, cfg)
return

Self_Update() {
    static NEW := 'trigger-new.exe'
    static UPD := 'trigger-update.exe'
    if (!A_IsCompiled)
        return
    if (FileExist(NEW) and !FileExist(UPD)) {
        FileInstall('../dist/trigger-update.exe', UPD)
        Run(UPD)
        ExitApp()
    }
    if (!FileExist(NEW) and FileExist(UPD)) {
        WinWaitClose('ahk_exe ' UPD)
        FileDelete(UPD)
    }
}

Setup_Config() {
    global cfg
    try FileInstall('assets/trigger.ini', 'trigger.ini')
    cfgFile := SubStr(A_ScriptName, 1, -4) . '.ini'
    cfg := Config.Load_Config(cfgFile)
    if (cfg.csvFile = 'trigger.csv')
        try FileInstall('assets/trigger.csv', 'trigger.csv')
    if (cfg.notesDir = 'notes')
        try DirCreate('notes')
}

Setup_Icon(icon) {
    if (cfg.icon = 'trigger.ico')
        try FileInstall('assets/trigger.ico', 'trigger.ico')
    try TraySetIcon(icon, 1, true)
}

Setup_TrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add('Reload', (*) => Reload())
    A_TrayMenu.Add('Quit', (*) => ExitApp())
}

Setup_CSV() {
    global shorts
    shorts := Shortcuts.Load_CSV(cfg.csvFile) ; Loads the data from the CSV file
    shorts.Setup_HotStrings()
}