#Requires AutoHotkey v2.0

#include <AnimateWindow>
#include <tools>
#include <editors>
#include <notes>
#include <configui>


class Picker extends Gui {
    _disabled := false
    _currentNote := ''
    cfg := ''
    edts := ''
    notetimer := ''
    ns := ''
    ogw := 1000, ogh := 600 ; Original gui width and height

    __New(shortcuts, cfg) {
        options := '+OwnDialogs +MinSize700x500 +Resize -MinimizeBox -MaximizeBox' 
        super.__New(options, 'Trigger', this)
        this.cfg := cfg
        this.shortcuts := shortcuts
        this.edts := Editors()
        this.ns := Notes(cfg.notesDir)
        this.Build()
        this.Setup_Dimensions()
        this.Show_Preview(this.cfg.ShowPreview)
        this.Refresh_Categories()
        this.Refresh_Notes()
        try ControlChooseIndex(1, this.lbNote.Hwnd)
        w := this.ogw, h := this.ogh
        if (cfg.rememberSize) {
            w := cfg.guiWidth || w
            h := cfg.guiHeigth || h
        }
        this.Move(,,w,h)
        Hotkey(cfg.hotkey, (hk)=>this.Showup_HotKey(hk))
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

    CurrentNote {
        get => this._currentNote
        set {
            if (!value)
                this.btnDelNote.Opt('+Disabled')
            else
                this.btnDelNote.Opt('-Disabled')
            this._currentNote := value
        }
    }

; #region Methods
    Build() {
        BUTTONHEIGHT := 50
        TABSHEIGHT := 35
        MX := 5, MY := 5
        x := y := w := h := 0
        ogw := this.ogw, ogh := this.ogh
        this.Show(Format('w{} h{} hide', ogw, ogh))
        this.SetFont('s16 bold', 'Calibri')
        this.BackColor := 'BDC3CB'
        this.MarginX := MX, this.MarginY := MY

        ; Tabs
        options := Format('x0 y0 w{} h{}', ogw, ogh)
        this.tabs := this.AddTab3(options, ['Picker', 'Notes'])
        this.tabs.anchor := 'wh'
; #region TabPicker
        w := 0.80 * (ogw - 3*MX)
        hnop := ogh - TABSHEIGHT - 2*MY
        h := hp := hnop - 3*BUTTONHEIGHT - 3*MY
        options := Format('x{} y{} w{} h{} ', MX, MY + TABSHEIGHT, w, h)
        options .= Format('+LV{} -LV{} ', LVS_EX_TRACKSELECT := 0x8, LVS_EX_HEADERDRAGDROP := 0x10)
        options .= '+Grid -Multi Section'
        this.lvPicker := this.AddListView(options)
        this.lvPicker.anchor := 'wh'
        this.lvPicker.hp := hp
        this.lvPicker.hnop := hnop
        this.lvPicker.InsertCol(1, 150, 'Trigger')
        this.lvPicker.InsertCol(2,, 'Replacement')
        this.lvPicker.OnEvent('Click', 'lvPicker_OnClick')
        this.lvPicker.OnEvent('ItemSelect', 'lvPicker_OnItemSelect')
        PostMessage(LVM_SETHOVERTIME := 0x1047, 0, 1,, 'ahk_id ' this.lvPicker.Hwnd)
        hdrHwnd := SendMessage(LVM_GETHEADER := 0x101F, 0, 0, this.lvPicker)
        ControlSetStyle("+" . HDS_NOSIZING := 0x800, hdrHwnd)

        h := 3*BUTTONHEIGHT + 2*MY
        options := Format('xs w{} h{} +BackgroundWhite +0x1000', w, h)
        this.txtPreview := this.AddText(options)
        this.txtPreview.anchor := 'yw'


        w := 0.20 * (ogw - 3*MX)
        h := ogh - TABSHEIGHT - 3*BUTTONHEIGHT - 5*MY
        options := Format('ys w{} h{} {} Sort', w, h, LBS_NOINTEGRALHEIGHT := 0x100)
        this.lbCategories := this.AddListBox(options)
        this.lbCategories.anchor := 'xh'
        this.lbCategories.OnEvent('Change', 'lbCategories_OnChange')
        this.lbCategories.OnEvent('DoubleClick', 'lbCategories_OnDoubleClick')
        options := Format('xp wp h{}', BUTTONHEIGHT, LBS_NOINTEGRALHEIGHT)
        this.btnDoc := this.AddButton(options, 'Edit &Doc')
        this.btnDoc.anchor := 'xy'
        this.btnDoc.OnEvent('Click', (*)=>Run(this.cfg.document))
        options := 'xp wp hp'
        this.btnEdit := this.AddButton(options, '&Text Editor')
        this.btnEdit.anchor := 'xy'
        this.btnEdit.OnEvent('Click', (*)=>this.edts.Start())
        this.btnReload := this.AddButton(options, '&Reload')
        this.btnReload.anchor := 'xy'
        this.btnReload.OnEvent('Click', (*)=>Reload())
; #endregion TabPicker
; #region TabNotes
        this.tabs.UseTab('Notes')
        w := 0.80 * (this.ogw - 3*MX)
        h := this.ogh - TABSHEIGHT - 2*MY
        options := Format('x{} y{} w{} h{} +WantTab', MX, MY + TABSHEIGHT, w, h)
        this.edtNote := this.AddEdit(options)
        this.edtNote.anchor := 'wh'
        this.edtNote.Enabled := false
        this.edtNote.OnEvent('Change', 'edtNote_OnChange')

        w := 0.20 * (this.ogw - 3*MX)
        h := this.ogh - TABSHEIGHT - 2*MY - 3*BUTTONHEIGHT - 3*MY
        options := Format('yp w{} h{} {} +Sort Section', w, h, LBS_NOINTEGRALHEIGHT)
        this.lbNote := this.AddListBox(options)
        this.lbNote.anchor := 'xh'
        this.lbNote.OnEvent('Change', 'lbNote_OnChange')

        h := BUTTONHEIGHT
        options := Format('xs wp h{} Section', h)
        this.btnRefreshNote := this.AddButton(options, '&Refresh')
        this.btnRefreshNote.anchor := 'xy'
        this.btnRefreshNote.OnEvent('Click', (*)=>this.btnRefreshNote_OnClick())
        options := 'xp wp hp'
        this.btnNewNote := this.AddButton(options, 'New')
        this.btnNewNote.anchor := 'xy'
        this.btnNewNote.OnEvent('Click', (*)=>this.btnNewNote_OnClick())
        options .= ' +Disabled'
        this.btnDelNote := this.AddButton(options, 'Delete')
        this.btnDelNote.anchor := 'xy'
        this.btnDelNote.OnEvent('Click', (*)=>this.btnDelNote_OnClick())

; #endregion TabNotes
; #region Menu
        menuHandler := ObjBindMethod(this, 'mnuCommands_OnEvent')
        mnuCommands := Menu()
        mnuCommands.Add('Edit Document', menuHandler)
        mnuCommands.Add('Open Editor', menuHandler)
        mnuCommands.Add('Reload', menuHandler)
        mnuCommands.Add('Quit', menuHandler)
        menuHandler := ObjBindMethod(this, 'mnuOptions_OnEvent')
        mnuOptions := Menu()
        mnuOptions.Add('Config...', menuHandler)
        mnuOptions.Add()
        mnuOptions.Add('Remember size', menuHandler)
        if (this.cfg.rememberSize)
            mnuOptions.Check('Remember size')
        mnuOptions.Add('Show preview', menuHandler)
        if (this.cfg.showPreview)
            mnuOptions.Check('Show preview')
        mnuOptions.Add('Show "*" category', menuHandler)
        if (this.cfg.showCategoryAll)
            mnuOptions.Check('Show "*" category')
        this.MenuBar := MenuBar()
        this.MenuBar.Add('Commands', mnuCommands)
        this.MenuBar.Add('Options', mnuOptions)
; #endregion Menu
        OnMessage(WM_ACTIVATEAPP := 0x001C, ObjBindMethod(this, 'OnActivate'))
        this.OnEvent('Escape', (*)=>this.MakeItDisappear())
        this.OnEvent('Close', (*)=>this.Close())
        this.OnEvent('Size', 'OnSize')
    }

    Setup_Dimensions() {
        x := y := w := h := 0
        for ,ctrl in this { ; Save the original size of each controls in the gui
            ctrl.GetPos(&x, &y, &w, &h)
            ctrl.origPos := {x: x, y: y, w: w, h: h}
        }
    }

    Resize_Controls(width?, height?) {
        x := y := w := h := 0
        this.GetClientPos(,,&w, &h)
        width := width ?? w, height := height ?? h
        ; deltas of the original position/size of the gui vs the new ones
        dx := dw := width - this.ogw
        dy := dh := height - this.ogh
        for ,ctrl in this {
            ctrl.GetPos(&x, &y, &w, &h)
            if (InStr(ctrl.anchor, 'x'))
                ox := ctrl.origPos.x, x := dx + ox
            if (InStr(ctrl.anchor, 'y'))
                oy := ctrl.origPos.y, y := dy + oy
            if (InStr(ctrl.anchor, 'w'))
                ow := ctrl.origPos.w, w := dw + ow
            if (InStr(ctrl.anchor, 'h'))
                oh := ctrl.origPos.h, h := dh + oh
            ctrl.Move(x, y, w, h)
        }
    }

    Show_Preview(value) {
        x := y := w := h := 0
        txt := this.txtPreview, lv := this.lvPicker
        txt.Visible := value
        lv.origPos.h := value?lv.hp:lv.hnop
        this.Resize_Controls()
    }

    Refresh_Categories() {
        lb := this.lbCategories
        category := lb.Text
        categories := this.shortcuts.categories
        lb.Delete()
        if (this.cfg.showCategoryAll)
            lb.Add(['*'])
        lb.Add(categories)
        category := this.cfg.defaultCategory || category || 1
        try this.lbCategories.Choose(category)
        this.Refresh_Picker(category)
    }

    Refresh_Picker(category) {
        lv := this.lvPicker
        lv.Delete()
        for ,sc in this.shortcuts {
            for ,rep in sc.replacements
                if (category = "*" or rep.category = category) {
                    lv.Add(, sc.trigger, rep.replacement)
                }
        }
        lv.ModifyCol(1, 'AutoHdr')
        lv.ModifyCol(2, 'AutoHdr')
    }

    Refresh_Notes() {
        lb := this.lbNote
        n := lb.Text || 1
        lb.Delete()
        lb.Add(this.ns.Titles)
        try lb.Choose(n)
    }

    MakeItAppear() {
        x := y := w := h:= 0
        mon := Get_CurrentMonitor()
        this.GetPos(,,&w, &h)
        Find_Center(&x, &y, w, h, mon)
        if (WinActive('ahk_id ' this.Hwnd)) {
        this.Move(x, y)
        } else {
            this.Show(Format('x{} y{}', x, y))
            ; AnimateWindow(this.Hwnd, 150, AW_ACTIVATE + RandFX())
            this.Refresh_Categories()
        }
    }

    MakeItDisappear() {
        this.Hide()
        ; AnimateWindow(this.Hwnd, 150, AW_HIDE + RandFX())
    }

    Close() {
        w := h := 0
        this.GetClientPos(,,&w,&h)
        if (this.cfg.rememberSize) {
            this.cfg.guiWidth := w
            this.cfg.guiHeigth := h
        }
        ExitApp()
    }

    Showup_HotKey(hk) {
        if (KeyWait(hk, 'T1')) {
            OutputDebug('#### HotKey Short Pressed `n')
            this.MakeItAppear()
        } else {
            OutputDebug('#### HotKey Long Pressed `n')
            edts.Tile()
        }
        KeyWait(hk)
    }
; #endregion Methods
; #region Events
    OnActivate(activated, thread, msg, hwnd) {
        if (!activated and hwnd = this.Hwnd)
                this.MakeItDisappear()
    }

    OnSize(minmax, width, height) {
        this.Resize_Controls(width, height)
        this.lvPicker.ModifyCol(2, 'AutoHdr')
        this.lvPicker.Redraw()
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
                this.Close()
            }
    }

    mnuOptions_OnEvent(ItemName, ItemPos, MyMenu) {
        switch ItemName {
            case 'Config...':
                ConfigUI.Show_ConfigUI(this.cfg, this)
            Case 'Remember size':
                this.cfg.rememberSize := !this.cfg.rememberSize
                if (this.cfg.rememberSize)
                    MyMenu.Check('Remember size')
                else
                    MyMenu.Uncheck('Remember size')
            Case 'Show preview':
                this.cfg.showPreview := !this.cfg.showPreview
                this.Show_Preview(this.cfg.showPreview)
                if (this.cfg.showPreview)
                    MyMenu.Check('Show preview')
                else
                    MyMenu.Uncheck('Show preview')
            Case 'Show "*" category':
                this.cfg.showCategoryAll := !this.cfg.showCategoryAll
                if (this.cfg.showCategoryAll)
                    MyMenu.Check('Show "*" category')
                else
                    MyMenu.Uncheck('Show "*" category')
                this.Refresh_Categories()
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

    btnRefreshNote_OnClick() {
        this.Refresh_Notes()
    }

    btnNewNote_OnClick() {
        this.ns.New()
        this.Refresh_Notes()
    }

    btnDelNote_OnClick() {
        if (!this.CurrentNote)
            return
        if (this.CurrentNote.Delete()) {
            this.edtNote.Enabled := false
            this.edtNote.Value := ''
            this.CurrentNote := ''
            this.Refresh_Notes()
        }
    }
; #endregion Events

}
