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
        set => IniWrite(value, this.cfgFile, 'Configuration', 'hotkey')
    }

    icon {
        get {
            if (!this._icon) {
                this._icon := IniRead(this.cfgFile, 'Configuration', 'icon', 'trigger.ico')
            }
            return this._icon

        }
        set {
            if (value) {
                if (FileExist(value)) {
                    IniWrite(value, this.cfgFile, 'Configuration', 'icon')
                    this._icon := value
                } else {
                    throw 'File must exist'
                }
            } else {
                IniWrite('', this.cfgFile, 'Configuration', 'icon')
                this._icon := ''
            }
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
            } else if (!value) {
                return
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
            } else if (!value) {
                return
            } else {
                throw 'Notes folder must exist'
            }
        }
    }

    document {
        get {
            if (!this._document) {
                this._document := IniRead(this.cfgFile, 'Configuration', 'document', '')
            }
            return this._document
        }
        set {
            if (value) {
                if (FileExist(value)) {
                    IniWrite(value, this.cfgFile, 'Configuration', 'document')
                } else {
                    throw 'Document must exist'
                }
            } else {
                IniWrite(this.cfgFile, 'Configuration', 'document', '')
            }
            this._document := value
        }
    }

    showCategoryAll {
        get {
            if (!this._showCategoryAll) {
                this._showCategoryAll := IniRead(this.cfgFile, 'Configuration', 'showCategoryAll', false)
            }
            return this._showCategoryAll
        }
        set {
            IniWrite(value?true:false, this.cfgFile, 'Configuration', 'showCategoryAll')
            this._showCategoryAll := value?true:false
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