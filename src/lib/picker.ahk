#Requires AutoHotkey v2.0

#include <AnimateWindow>
#include <tools>
#include <editors>
#include <notes>
#include <configui>

WM_ACTIVATEAPP := 0x001C
LVM_SETHOVERTIME := 0x1047
LVS_EX_HEADERDRAGDROP := 0x10
LVS_EX_TRACKSELECT := 0x8
LBS_NOINTEGRALHEIGHT := 0x100
BUTTONHEIGHT := 50
MX := 5, MY := 5
TABSHEIGHT := 35

class Picker extends Gui {
    __New(shortcuts, cfg) {
        options := '+OwnDialogs +MinSize700x500 -Resize -MinimizeBox -MaximizeBox' 
        super.__New(options, 'Trigger', this)
        this._disabled := false
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

    Disabled {
        get => this._disabled
        set {
            if (value) {
                this._disabled := true
                this.Opt('+Disabled')
            } else {
                this._disabled := false
                this.Opt('-Disabled')
            }
        }
    }

    Build() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        this.Show('Hide w1000 h600')
        this.SetFont('s16 bold', 'Calibri')
        this.BackColor := 'BDC3CB'
        this.MarginX := MX, this.MarginY := MY
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
        mnuOptions.Add('Config...', menuHandler)
        mnuOptions.Add('Show "*" category', menuHandler)
        if (this.cfg.showCategoryAll)
            mnuOptions.Check('Show "*" category')
        this.MenuBar := MenuBar()
        this.MenuBar.Add('Commands', mnuCommands)
        this.MenuBar.Add('Options', mnuOptions)
        ; Tabs
        w := totalWidth, h := totalHeight
        options := Format('x0 y0 w{} h{} ', w, h)
        this.tabs := this.AddTab3(options, ['Picker', 'Notes'])
        ; lvPicker
        w := (totalWidth * 0.80) - 2*MX
        h := totalHeight - TABSHEIGHT - 2*MY - 3*BUTTONHEIGHT - 3*MY
        options := Format('w{} h{} ', w, h)
        options .= Format('+LV{} -LV{} ', LVS_EX_TRACKSELECT, LVS_EX_HEADERDRAGDROP)
        options .= '+Grid -Multi Section'
        this.lvPicker := this.AddListView(options)
        this.lvPicker.InsertCol(1, 150, 'Trigger')
        this.lvPicker.InsertCol(2,, 'Replacement')
        this.lvPicker.OnEvent('Click', 'lvPicker_OnClick')
        this.lvPicker.OnEvent('ItemSelect', 'lvPicker_OnItemSelect')
        this.lvPicker.OnEvent('ContextMenu', 'lvPicker_OnContextMenu')
        PostMessage(LVM_SETHOVERTIME, 0, 1,, 'ahk_id ' this.lvPicker.Hwnd)

        ; txtPreview
        h := 3*BUTTONHEIGHT + 2*MY
        options := Format('+Border +BackgroundWhite xs wp h{}', h)
        this.txtPreview := this.AddText(options)

        ; lbCategories
        w := (totalWidth * 0.20) - 2*MX
        h := totalHeight - TABSHEIGHT - 3*BUTTONHEIGHT - 5*MY
        options := Format('ys w{} h{} {} -Border Sort', w, h, LBS_NOINTEGRALHEIGHT)
        this.lbCategories := this.AddListBox(options)
        this.lbCategories.OnEvent('Change', 'lbCategories_OnChange')
        this.lbCategories.OnEvent('DoubleClick', 'lbCategories_OnDoubleClick')
        ; btnDoc
        h := BUTTONHEIGHT
        options := Format('xp wp h{}', h, LBS_NOINTEGRALHEIGHT)
        this.btnDoc := this.AddButton(options, 'Edit &Doc')
        this.btnDoc.OnEvent('Click', (*)=>Run(this.cfg.document))
        ; btnEdit
        options := 'xp wp hp'
        this.btnEdit := this.AddButton(options, '&Text Editor')
        this.btnEdit.OnEvent('Click', (*)=>this.edts.Start())
        ; btnReload
        this.btnReload := this.AddButton(options, '&Reload')
        this.btnReload.OnEvent('Click', (*)=>Reload())
        this.tabs.UseTab('Notes')
        ; edtNote
        w := (totalWidth * 0.80) - 2*MX
        h := totalHeight - TABSHEIGHT - 2*MY
        options := Format('w{} h{} +WantTab', w, h)
        this.edtNote := this.AddEdit(options)
        this.edtNote.Enabled := false
        this.edtNote.OnEvent('Change', 'edtNote_OnChange')
        ; lbNote
        w := (totalWidth * 0.20) - 2*MY
        h := totalHeight - TABSHEIGHT - 3*BUTTONHEIGHT - 5*MY
        options := Format('yp w{} h{} {} -Border +Sort Section', w, h, LBS_NOINTEGRALHEIGHT)
        this.lbNote := this.AddListBox(options)
        this.lbNote.OnEvent('Change', 'lbNote_OnChange')
        ; btnRefreshNote
        h := BUTTONHEIGHT
        options := Format('xs wp h{} Section', h)
        this.btnRefreshNote := this.AddButton(options, '&Refresh')
        this.btnRefreshNote.OnEvent('Click', 'btnRefreshNote_OnClick')
        ; btnNewNote
        options := 'xp wp hp'
        this.btnNewNote := this.AddButton(options, '&New')
        this.btnNewNote.OnEvent('Click', 'btnNewNote_OnClick')
        ; btnDelNote
        options := 'xp wp hp'
        this.btnDelNote := this.AddButton(options, '&Delete')
        this.btnDelNote.OnEvent('Click', 'btnDelNote_OnClick')
    }

; #region Events
    OnActivate(activated, thread, msg, hwnd) {
        if (!activated and hwnd = this.Hwnd)
            if (!WinWaitActive('ahk_id ' this.Hwnd,, 1)) {
                this.MakeItDisappear()
            }
    }

    OnSize(minmax, width, height) {
        static ogw, ogh ; Original gui width and height
        x := y := w := h := 0

        ; If the original size of the gui and controls haven't been saved yet, save them
        if !IsSet(ogw) {
            ogw := width, ogh := height ; Save the original size of the gui
            ; Save the original size of each controls in the gui
            for ,ctrl in this {
                ctrl.GetPos(&x, &y, &w, &h)
                ctrl.origPos := {x: x, y: y, w: w, h: h}
            }
            return
        }

        dx := dw := width - ogw ; deltas of the original position/size of the gui vs the new ones
        dy := dh := height - ogh
        for ,ctrl in [this.tabs, this.lvPicker, this.edtNote] {
            ow := ctrl.origPos.w, w := (dw * 1) + ow
            oh := ctrl.origPos.h, h := (dh * 1) + oh
            ctrl.Move(,, w, h)
        }

        ctrl := this.txtPreview
        {
            ow := ctrl.origPos.w, w := (dw * 1) + ow
            oy := ctrl.origPos.y, y := (dy * 1) + oy
            ctrl.Move(, y, w,)
        }

        for ,ctrl in [this.lbCategories, this.lbNote] {
            ox := ctrl.origPos.x, oh := ctrl.origPos.h
            x := (dx * 1) + ox, h := (dh * 1) + oh
            ctrl.Move(x,,, h)
        }

        ; buttons
        ctrls := [this.btnDoc, this.btnEdit, this.btnReload
            , this.btnRefreshNote, this.btnNewNote, this.btnDelNote]
        for ,ctrl in ctrls {
            ox := ctrl.origPos.x
            oy := ctrl.origPos.y
            x := (dx * 1) + ox, y := (dy * 1) + oy
            ctrl.Move(x, y,,)
        }
    }

    mnuCommands_OnEvent(ItemName, *) {
        switch ItemName {
            Case 'Edit Document':
                if (!this.cfg.document)
                    this.cfg.document := this.cfg.csvFile
                Run(this.cfg.document)
            Case 'Open Editor':
                this.edts.Start()
            Case 'Reload':
                Reload()
            Case 'Quit':
                ExitApp()
            }
    }

    mnuOptions_OnEvent(ItemName, ItemPos, MyMenu) {
        switch ItemName {
            case 'Config...':
                ConfigUI.Show_ConfigUI(this.cfg, this)
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
        if (!row)
            return
        this.Hide()
        SetKeyDelay(0)
        sc := this.shortcuts[lv.GetText(row)]
        sc.Send_Replacement()
    }

    lvPicker_OnItemSelect(lv, row, selected) {
        if (selected)
            this.txtPreview.Value := lv.GetText(row, 2)
        else
            ToolTip(,,,1)
    }

    lvPicker_OnContextMenu(lv, row, isRightClick, x, y) {
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
        this.Refresh_Picker(lb.Text)
    }

    lbCategories_OnDoubleClick(lb, *) {
        if (lb.Text) {
            if (this.cfg.defaultCategory != lb.Text)
                this.cfg.defaultCategory := lb.Text
            else
                this.cfg.defaultCategory := ''
        }
    }

    edtNote_OnChange(edt, *) {
        if (this.currentNote)
            this.currentNote.Content := edt.Text
    }

    lbNote_OnChange(lb, *) {
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
        this.Refresh_Notes()
    }

    btnNewNote_OnClick(*) {
        this.ns.New()
        this.Refresh_Notes()
    }

    btnDelNote_OnClick(*) {
        if (this.currentNote.Delete()) {
            this.edtNote.Enabled := false
            this.edtNote.Value := ''
            this.currentNote := ''
            this.Refresh_Notes()
        }
    }
; #endregion Events

; #region Methods
    Refresh_Notes() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        lbn := this.lbNote
        lbn.Delete()
        lbn.Add(this.ns.Titles)
    }

    Set_Category(category?) {
        OutputDebug('-- ' A_ThisFunc '()`n')
        if (IsSet(category) and category)
            try {
                this.lbCategories.Choose(category)
                return
            }
        category := this.cfg.defaultCategory || this.lbCategories.Text || 1
        this.lbCategories.Choose(category)
    }

    Load_Categories() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        lb := this.lbCategories
        cat := lb.Text
        cats := this.shortcuts.categories
        lb.Delete()
        if (cfg.showCategoryAll)
            lb.Add(['*'])
        lb.Add(cats)
        this.Set_Category(cat)
        this.Refresh_Picker()
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
; #endregion Methods
}

; #region Functions
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
