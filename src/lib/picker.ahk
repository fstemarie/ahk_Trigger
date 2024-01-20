#Requires AutoHotkey v2.0

#include <AnimateWindow>
#include <tools>
#include <editors>
#include <notes>

class Picker extends Gui {
    __New(shortcuts, cfg) {
        options := '+OwnDialogs +MinSize628x150 -Resize -MinimizeBox -MaximizeBox' 
        super.__New(options, 'Trigger', this)
        this.shortcuts := shortcuts
        this.cfg := cfg
        this.edts := Editors()
        this.ns := Notes(cfg.notesDir)
        this.currentNote := ''
        this.notetimer := ''
        this.Build()
        this.Load_Categories()
        this.Refresh_Notes()
        Hotkey(cfg.hotkey, Showup_HotKey)
        Hotkey(cfg.hotkey . ' UP', Showup_HotKey)
    }

    Build() {
        OutputDebug('-- ' A_ThisFunc '()`n')

        WM_ACTIVATEAPP := 0x001C
        LVM_SETHOVERTIME := 0x1047
        LVS_EX_HEADERDRAGDROP := 0x10
        LVS_EX_TRACKSELECT := 0x8
        LBS_NOINTEGRALHEIGHT := 0x100
    
        this.Show('Hide w1000 h600')
        this.SetFont('s16 bold', 'Calibri')
        this.BackColor := 'BDC3CB'
        mx := this.MarginX := my := this.MarginY := 5
        OnMessage(WM_ACTIVATEAPP, ObjBindMethod(this, 'OnActivate'))
        this.OnEvent('Escape', (*)=>this.MakeItDisappear())
        this.OnEvent('Close', (*)=>ExitApp())
        this.OnEvent('Size', 'OnSize')

        totalWidth := totalHeight := 0
        this.GetClientPos(,,&totalWidth, &totalHeight)

        menuHandler := ObjBindMethod(this, 'mnuCommands_OnEvent')
        mnuCommands := Menu()
        mnuCommands.Add('Edit Document', menuHandler)
        mnuCommands.Add('Open Editor', menuHandler)
        mnuCommands.Add('Reload', menuHandler)
        mnuCommands.Add('Quit', menuHandler)
        menuHandler := ObjBindMethod(this, 'mnuOptions_OnEvent')
        mnuOptions := Menu()
        mnuOptions.Add('Change HotKey', menuHandler)
        mnuOptions.Add('Change Icon', menuHandler)
        mnuOptions.Add('Change CSV File', menuHandler)
        mnuOptions.Add('Change notes folder', menuHandler)
        mnuOptions.Add('Change document to edit', menuHandler)
        mnuOptions.Add('Show "*" category', menuHandler)
        if (this.cfg.showCategoryAll)
            mnuOptions.Check('Show "*" category')
        this.MenuBar := MenuBar()
        this.MenuBar.Add('Commands', mnuCommands)
        this.MenuBar.Add('Options', mnuOptions)

        ; Tabs
        w := totalWidth, h := totalHeight, ybias := 35
        options := Format('x0 y0 w{} h{} ', w, h)
        this.tabs := this.Add('Tab3', options, ['Picker', 'Notes'])
        ; lvPicker
        w := (totalWidth * 0.80) - 2*mx, h := totalHeight - 50 - 2*my - ybias
        options := Format('w{} h{} ', w, h)
        options .= Format('+LV{} -LV{} ', LVS_EX_TRACKSELECT, LVS_EX_HEADERDRAGDROP)
        options .= '+Grid -Multi Section'
        this.lvPicker := this.Add('ListView', options)
        this.lvPicker.InsertCol(1, 150, 'Trigger')
        this.lvPicker.InsertCol(2,, 'Replacement')
        this.lvPicker.OnEvent('Click', 'lvPicker_OnClick')
        this.lvPicker.OnEvent('ItemSelect', 'lvPicker_OnItemSelect')
        this.lvPicker.OnEvent('ContextMenu', 'lvPicker_OnContextMenu')
        PostMessage(LVM_SETHOVERTIME, 0, 1,, 'ahk_id ' this.lvPicker.Hwnd)
        ; lbCategories
        w := (totalWidth * 0.20) - 2*mx
        options := Format('ys w{} hp {} -Border Sort', w, LBS_NOINTEGRALHEIGHT)
        this.lbCategories := this.Add('ListBox', options)
        this.lbCategories.OnEvent('Change', 'lbCategories_OnChange')
        this.lbCategories.OnEvent('DoubleClick', 'lbCategories_OnDoubleClick')
        ; btnDoc
        h := 50 - 2*my
        options := Format('xs w150 h{} Section', h, LBS_NOINTEGRALHEIGHT)
        this.btnDoc := this.Add('Button', options, 'Edit &Doc')
        ; this.btnDoc.OnEvent('Click', 'btnDoc_OnClick')
        this.btnDoc.OnEvent('Click', (*)=>Run(this.cfg.document))
        ; btnEdit
        options := 'ys wp hp'
        this.btnEdit := this.Add('Button', options, '&Text Editor')
        this.btnEdit.OnEvent('Click', (*)=>this.edts.Start())
        ; btnReload
        this.btnReload := this.Add('Button', options, '&Reload')
        this.btnReload.OnEvent('Click', (*)=>Reload())

        this.tabs.UseTab('Notes')
        ; edtNote
        w := (totalWidth * 0.80) - 2*mx, h := totalHeight - 50 - 2*my - ybias
        options := Format('w{} h{} +WantTab Section', w, h)
        this.edtNote := this.Add('Edit', options)
        this.edtNote.Enabled := false
        this.edtNote.OnEvent('Change', 'edtNote_OnChange')
        ; lbNote
        w := (totalWidth * 0.20) - 2*mx
        options := Format('ys w{} hp {} -Border +Sort', w, LBS_NOINTEGRALHEIGHT)
        ; options := Format('yp w{} hp -Border +Sort', w)
        this.lbNote := this.Add('ListBox', options)
        this.lbNote.OnEvent('Change', 'lbNote_OnChange')

        ; btnRefreshNote
        h := 50 - 2*my
        options := Format('xs w150 h{} Section', h)
        this.btnRefreshNote := this.Add('Button', options, '&Refresh')
        this.btnRefreshNote.OnEvent('Click', 'btnRefreshNote_OnClick')
        ; btnNewNote
        options := 'yp wp hp'
        this.btnNewNote := this.Add('Button', options, '&New')
        this.btnNewNote.OnEvent('Click', 'btnNewNote_OnClick')
        ; btnDelNote
        options := 'yp wp hp'
        this.btnDelNote := this.Add('Button', options, '&Delete')
        this.btnDelNote.OnEvent('Click', 'btnDelNote_OnClick')
    }

; #region Events
    OnActivate(Activated, thread, msg, hwnd) {
        OutputDebug('-- ' A_ThisFunc '()`n')
        thiswindow := (hwnd == this.Hwnd)
        if (Activated and thiswindow) {
            OutputDebug('-- Activated`n')
        } else if (!Activated and !thiswindow) {
            OutputDebug('-- Deactivated`n')
            if (!WinWaitActive('ahk_id ' this.Hwnd,, 0.5))
                this.MakeItDisappear()
        }
    }

    OnSize(minmax, width, height) {
        OutputDebug('-- ' A_ThisFunc '()`n')
        static ogw, ogh ; Original gui width and height
        x := y := w := h := 0

        if !IsSet(ogw) {
            ogw := width, ogh := height
            for ,ctrl in this {
                ctrl.GetPos(&x, &y, &w, &h)
                ctrl.origPos := {x: x, y: y, w: w, h: h}
            }
            return
        }

        dx := dw := width - ogw
        dy := dh := height - ogh
        for ,ctrl in [this.tabs, this.lvPicker, this.edtNote] {
            ow := ctrl.origPos.w, oh := ctrl.origPos.h
            w := (dw * 1) + ow, h := (dh * 1) + oh
            ctrl.Move(,, w, h)
        }

        for ,ctrl in [this.lbCategories, this.lbNote] {
            ox := ctrl.origPos.x
            oh := ctrl.origPos.h
            x := (dx * 1) + ox, h := (dh * 1) + oh
            ctrl.Move(x,,, h)
        }

        ; buttons
        ctrls := [this.btnDoc, this.btnEdit, this.btnReload
            ,this.btnQuit, this.btnNewNote, this.btnDelNote, this.btnSaveNote]
        for ,ctrl in ctrls {
            oy := ctrl.origPos.y
            y := (dy * 1) + oy
            ctrl.Move(, y,,)
        }
    }

    mnuCommands_OnEvent(ItemName, *) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        switch ItemName {
            Case 'Edit Document':
                if (!this.cfg.document)
                    this.cfg.document := this.cfg.csvFile
                Run(this.cfg.document)
            Case 'Open Editor':
                this.edts.Start()
            Case 'Reload':
                Reload
            Case 'Quit':
                ExitApp
            }
    }

    mnuOptions_OnEvent(ItemName, ItemPos, MyMenu) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        switch ItemName {
            Case 'Change HotKey':
                this.cfg.Pick_hotkey()
            Case 'Change Icon':
                this.cfg.Pick_icon()
            Case 'Change CSV File':
                csvFile := this.cfg.csvFile
                this.cfg.Pick_csvFile()
                if (csvFile != this.cfg.csvFile) {
                    answer := MsgBox('Do you wish to reload the application?', 'Reload', '0x4 0x20 Owner' . this.Hwnd)
                    if (answer = 'yes')
                        Reload()
                }
            Case 'Change notes folder':
                notesDir := this.cfg.notesDir
                this.cfg.Pick_notesDir()
                if (notesDir != this.cfg.notesDir) {
                    answer := MsgBox('Do you wish to reload the application?', 'Reload', '0x4 0x20 Owner' . this.Hwnd)
                    if (answer = 'yes')
                        Reload()
                }
            Case 'Change document to edit':
                this.cfg.Pick_document()
            Case 'Show "*" category':
                this.cfg.showCategoryAll := !this.cfg.showCategoryAll
                if (this.cfg.showCategoryAll)
                    MyMenu.Check('Show "*" category')
                else
                    MyMenu.Uncheck('Show "*" category')
                this.Load_Categories()
        }
    }

    lvPicker_OnClick(lv, row) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        if (!row)
            return
        this.Hide()
        SetKeyDelay(0)
        sc := this.shortcuts[lv.GetText(row)]
        sc.Send_Replacement()
    }

    lvPicker_OnItemSelect(lv, row, selected) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        ToolTip(,,,1)
    }

    lvPicker_OnContextMenu(lv, row, isRightClick, x, y) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        static tooltipshowing := false
        if (!row)
            return
        if (!tooltipshowing) {
            rep := lv.GetText(row, 2)
            ToolTip(rep, x, y, 1)
            tooltipshowing := true
            SetTimer(TurnOffToolTip, -2000)
        } else {
            TurnOffToolTip()
        }

        TurnOffToolTip() {
            ToolTip(,,,1)
            tooltipshowing := false
            SetTimer(TurnOffToolTip, 0)
        }
    }

    lbCategories_OnChange(lb, *) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        this.Refresh_Picker(lb.Text)
    }

    lbCategories_OnDoubleClick(lb, *) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        if (lb.Text)
            this.cfg.defaultCategory := lb.Text
    }

    btnDoc_OnClick(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        if (!cfg.document)
            cfg.document := cfg.csvFile
        Run(cfg.document)
    }

    btnEdit_OnClick(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        this.edts.Start()
    }

    btnReload_OnClick(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        Reload()
    }

    edtNote_OnChange(edt, *) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        if (this.currentNote)
            this.currentNote.Content := edt.Text
    }

    lbNote_OnChange(lb, *) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        if (!lb.Text)
            return
        if (this.currentNote) {
            this.currentNote.Save()
            this.currentNote := ''
        }
        title := lb.Text
        this.currentNote := this.ns[lb.Text]
        this.edtNote.Value := this.currentNote.Content
        this.edtNote.Enabled := true
    }

    btnRefreshNote_OnClick(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        this.Refresh_Notes()
    }

    btnNewNote_OnClick(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        this.ns.New()
        this.Refresh_Notes()
    }

    btnDelNote_OnClick(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        if (this.currentNote.Delete()) {
            this.edtNote.Enabled := false
            this.edtNote.Value := ''
            this.currentNote := ''
            this.Refresh_Notes()
        }
    }
; #endregion Events

    Refresh_Notes() {
        OutputDebug('-- ' A_ThisFunc '()`n')

        lbn := this.lbNote
        lbn.Delete()
        lbn.Add(this.ns.Titles)
    }

    Set_Category(category?) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        category := category ?? this.cfg.defaultCategory || this.lbCategories.Text
        this.lbCategories.Choose(category)
    }

    Load_Categories() {
        OutputDebug('-- ' A_ThisFunc '()`n')

        lb := this.lbCategories
        cat := lb.Text || 1
        cats := this.shortcuts.categories
        lb.Delete()
        if (cfg.showCategoryAll)
            lb.Add(['*'])
        lb.Add(cats)
        try
            lb.Choose(cat)
        catch
            lb.Choose(1)
        this.Refresh_Picker(lb.Text)
    }

    Refresh_Picker(category?) {
        OutputDebug('-- ' A_ThisFunc '()`n')

        lv := this.lvPicker
        category := category ?? this.lbCategories.Text
        lv.Delete()
        for ,sc in this.shortcuts {
            if (category = "*" or sc.category = category) {
                for ,rep in sc.replacements {
                    rep := StrReplace(rep, '{Raw}')
                    lv.Add(, sc.trigger, rep)
                }
            }
        }
    }

    MakeItAppear() {
        OutputDebug('-- ' A_ThisFunc '()`n')

        x := y := w := h:= 0
        this.GetPos(,,&w, &h)
        mon := Get_CurrentMonitor()
        Find_Center(&x, &y, w, h, mon)
        this.Set_Category()
        this.Refresh_Picker()
        this.Show(Format('hide x{} y{}', x, y))
        AnimateWindow(this.Hwnd, 150, AW_ACTIVATE + RandFX())
        this.Show()
    }
    
    MakeItDisappear() {
        OutputDebug('-- ' A_ThisFunc '()`n')

        AnimateWindow(this.Hwnd, 150, AW_HIDE + RandFX())
        this.Hide()
    }
    
    FollowMouse() {
        OutputDebug('-- ' A_ThisFunc '()`n')

        x := y := w := h:= 0
        this.GetPos(,,&w, &h)
        mon := Get_CurrentMonitor()
        Find_Center(&x, &y, w, h, mon)
        this.Move(x, y)
        WinActivate(this.Hwnd)
    }
}

Showup_HotKey(hk) {
    static skipUP := false
    ui := view
    isUP := RegExMatch(hk, ' UP$')
    if (!isUP) {
        skipUP := false
        SetTimer(longpress, -500)
        KeyWait(hk, 'D T1')
    }
    if (isUP and !skipUP) {
        SetTimer(longpress, 0)
        OutputDebug('#### HotKey Pressed `n')
        if (WinExist('ahk_id' view.Hwnd)) 
            view.FollowMouse()
        else
            view.MakeItAppear()
    }

    longpress() {
        OutputDebug('#### HotKey Long Pressed `n')
        skipUP := true
        edts.Tile()
    }
}
