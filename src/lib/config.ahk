#Requires AutoHotkey v2.0

Class Config {
    __New(cfgFile) {
        if (!FileExist(cfgFile)) {
            throw 'INI File not found'
        }
        this.cfgFile := cfgFile
    }

    hotkey {
        get => IniRead(this.cfgFile, 'Configuration', 'hotkey', 'F1')
        set => IniWrite(value, this.cfgFile, 'Configuration', 'hotkey')
    }

    icon {
        get => IniRead(this.cfgFile, 'Configuration', 'icon', 'trigger.ico')
        set {
            if (value)
                if (FileExist(value))
                    IniWrite(value, this.cfgFile, 'Configuration', 'icon')
                else
                    throw 'File must exist'
        }
    }

    csvFile {
        get => IniRead(this.cfgFile, 'Configuration', 'csvFile', 'trigger.csv')
        set {
            if (value)
                if (FileExist(value))
                    IniWrite(value, this.cfgFile, 'Configuration', 'csvFile')
                else
                    throw 'File must exist'
        }
    }

    notesDir {
        get => IniRead(this.cfgFile, 'Configuration', 'notesDir', 'notes')
        set {
            if (value)
                if (DirExist(value))
                    IniWrite(value, this.cfgFile, 'Configuration', 'notesDir')
                else
                    throw 'Notes folder must exist'
        }
    }

    document {
        get => IniRead(this.cfgFile, 'Configuration', 'document', '')
        set {
            if (value)
                if (FileExist(value))
                    IniWrite(value, this.cfgFile, 'Configuration', 'document')
                else
                    throw 'Document must exist'
        }
    }

    showCategoryAll {
        get => IniRead(this.cfgFile, 'Configuration', 'showCategoryAll', false)
        set => IniWrite(value ? true : false, this.cfgFile, 'Configuration', 'showCategoryAll')
    }

    defaultCategory {
        get => IniRead(this.cfgFile, 'Configuration', 'defaultCategory', '')
        set => IniWrite(value, this.cfgFile, 'Configuration', 'defaultCategory')
    }

    Pick_hotkey() {
        answer := InputBox('Enter the desired HotKey', 'Enter HotKey')
        if (answer.Result = 'OK') {
            this.hotkey := answer.Value
            Reload()
        }
    }

    Pick_icon() {
        filename := FileSelect((1 + 2), A_ScriptDir, 'Choose your icon', 'ICO File (*.ico)',)
        if (filename) {
            this.icon := filename
        }
    }

    Pick_csvFile() {
        filename := FileSelect((1 + 2), A_MyDocuments, 'Choose your HotStrings CSV file', 'CSV File (*.csv)')
        if (filename) {
            this.csvFile := filename
            Reload()
        } else {
            if (!this.csvFile or !FileExist(this.csvFile)) {
                OutputDebug('No CSV File selected')
                MsgBox('You MUST select a CSV File', 'No CSV File', 16)
                ExitApp(1)
            }
        }
    }

    Pick_notesDir() {
        dirname := FileSelect('D1', A_MyDocuments, 'Choose a folder for notes')
        if (dirname) {
            this.notesDir := dirname
            Reload()
        } else {
            if (!this.notesDir or !DirExist(this.notesDir)) {
                OutputDebug('No notes folder selected')
                MsgBox('You MUST select a notes folder', 'No notes Folder', 16)
                ExitApp(1)
            }
        }
    }

    Pick_document() {
        filename := FileSelect((1 + 2), A_MyDocuments, 'Choose the document to edit')
        if (filename) {
            this.document := filename
        }
    }

    static Load_Config(cfgFile) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        cfg := Config(cfgFile)
        if (!cfg.csvFile or !FileExist(cfg.csvFile)) {
            cfg.Pick_csvFile()
        }
        if (!cfg.notesDir or !DirExist(cfg.notesDir)) {
            cfg.Pick_notesDir()
        }
        return cfg
    }
}