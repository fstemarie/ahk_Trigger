#Requires AutoHotkey v2.0

Class Config {
    __New(cfgFile) {
        if (!FileExist(cfgFile)) {
            throw 'INI File not found'
        }
        this.cfgFile := cfgFile
        this._hotkey := ''
        this._icon := ''
        this._csvFile := ''
        this._notesDir := ''
        this._document := ''
        this._showCategoryAll := ''
        this._defaultCategory := ''
    }

    hotkey {
        get {
            if (!this._hotkey) {
                this._hotkey := IniRead(this.cfgFile, 'Configuration', 'hotkey', 'F1')
            }
            return this._hotkey
        }
    }

    icon {
        get {
            if (!this._icon) {
                this._icon := IniRead(this.cfgFile, 'Configuration', 'icon', 'trayicon.ico')
            }
            return this._icon

        }
    }

    csvFile {
        get {
            if (!this._csvFile) {
                this._csvFile := IniRead(this.cfgFile, 'Configuration', 'csvFile', 'trigger.csv')
            }
            return this._csvFile
        }
        set {
            if (FileExist(value)) {
                IniWrite(value, this.cfgFile, 'Configuration', 'csvFile')
                this._csvFile := value
            } else {
                throw 'File must exist'
            }
        }
    }

    notesDir {
        get {
            if (!this._notesDir) {
                this._notesDir := IniRead(this.cfgFile, 'Configuration', 'notesDir', 'notes')
            }
            return this._notesDir
        }
        set {
            if (value and DirExist(value)) {
                IniWrite(value, this.cfgFile, 'Configuration', 'notesDir')
                this._notesDir := value
            } else {
                throw 'Notes folder must exist'
            }
        }
    }

    document {
        get {
            if (!this._document) {
                this._document := IniRead(this.cfgFile, 'Configuration', 'document', this.csvFile)
            }
            return this._document
        }
        set {
            if (InStr(FileExist(value), 'N')) {
                IniWrite(value, this.cfgFile, 'Configuration', 'document')
                this._document := value
            } else {
                throw 'Document must exist'
            }
        }
    }

    showCategoryAll {
        get {
            if (!this._showCategoryAll) {
                this._showCategoryAll := IniRead(this.cfgFile, 'Configuration', 'showCategoryAll', '')
            }
            return this._showCategoryAll

        }
        set {
            IniWrite(value, this.cfgFile, 'Configuration', 'showCategoryAll')
            this._showCategoryAll := value
        }
    }

    defaultCategory {
        get {
            if (!this._defaultCategory) {
                this._defaultCategory := IniRead(this.cfgFile, 'Configuration', 'defaultCategory', '')
            }
            return this._defaultCategory

        }
        set {
            IniWrite(value, this.cfgFile, 'Configuration', 'defaultCategory')
            this._defaultCategory := value
        }
    }

    Pick_csvFile() {
        filename := FileSelect((1 + 2), A_MyDocuments, 'Choose your HotStrings CSV file', 'CSV File (*.csv)')
        if (filename) {
            this.csvFile := filename
        } else {
            OutputDebug('No CSV File selected')
            MsgBox('HotStrings.ahk - No CSV File', 'You MUST select a CSV File', 16)
            ExitApp(1)
        }
    }

    Pick_notesDir() {
        dirname := FileSelect('D1', A_MyDocuments, 'Choose a folder for notes')
        if (dirname) {
            this.notesDir := dirname
        } else {
            OutputDebug('No notes folder selected')
            MsgBox('HotStrings.ahk - No notes Folder', 'You MUST select a notes folder', 16)
            ExitApp(1)
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

        try {
            FileInstall("config.ini", "trigger.ini", 0)
        }
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
