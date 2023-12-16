#Requires AutoHotkey v2.0

#include <note>

Class Notes {
    __New(path) {
        if (!DirExist(path))
            throw Error('Directory does not exist', -1)
        this.path := path
    }

    __Item[title] {
        get {
            path := this.path
            filename := path . '\' . title . '.txt'
            if (FileExist(filename))
                return Note(filename)
            else
                throw ValueError('File does not exist')
        }
    }

    Titles {
        get {
            titles := []
            if (!titles.Length) {
                loop files this.path '\*.txt' {
                    title := SubStr(A_LoopFileName, 1, -4)
                    titles.Push(title)
                }
            }
            return titles
        }
    }

    New() {
        loop {
            retrycancel := ''
            answer := InputBox("Enter the new note's title", "Note's title")
            if (answer.Result = 'Cancel' or !answer.Value)
                return
            try {
                filename := this.path '\' answer.Value '.txt'
                FileAppend('', filename)
            } catch OSError as e {
                retrycancel := MsgBox(e.Message, 'Error', 'RetryCancel Iconx')            
            }
        } until (retrycancel != 'Retry')
    }
}