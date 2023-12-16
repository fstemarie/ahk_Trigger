#Requires AutoHotkey v2.0

Class Controller {
    __New(cfg, model, view) {
        this.cfg := cfg
        this.model := model
        this.view := view

        view.Set_Controller(this)
    }
}