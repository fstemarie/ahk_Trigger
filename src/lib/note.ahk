#Requires AutoHotkey v2.0

Class Note {
    __New(fullPath) {
        if (FileExist(fullPath)) {
            this.fullPath := fullPath
            this._content := ''
            this._savetimer := ObjBindMethod(this, 'Save')
        }
        else
            throw ValueError('File does not exist')
    }

    Title {
        get {
            fullPath := this.fullPath
            fileNameNoExt := ''
            SplitPath(fullPath,,,,&fileNameNoExt)
            return fileNameNoExt
        }
    }

    Directory {
        get {
            fullPath := this.fullPath
            OutDir := ''
            SplitPath(fullPath,,&OutDir)
            return OutDir
        }
    }

    Content {
        get {
            if (!this._content)
                this._content := FileRead(this.fullpath)
            return this._content
        }
        set {
            if (value != this._content) {
                this._content := value
                SetTimer(this._savetimer, -2000)
            }
        }
    }

    Rename(newTitle) {
        dest := this.Directory "\" newTitle ".txt"
        FileMove(this.fullPath, dest)
    }

    Save() {
        content := this._content
        SetTimer(this._savetimer, 0)
        file := FileOpen(this.fullpath, 'w')
        file.Write(content)
        file.Close()
    }

    Delete() {
        answer := MsgBox(Format('Do you really want to delete {} ?', this.fullPath), 'Warning', 'YesNo Default2 Icon!')
        if (answer = 'Yes')
            FileDelete(this.fullPath)
        return (answer = 'Yes')
    }
}