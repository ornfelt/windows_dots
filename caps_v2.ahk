#Requires AutoHotkey v2.0
#SingleInstance Force

; Define hotkeys with conditional statements
;#HotIf !WinActive("ahk_class Notepad")
#HotIf !WinActive("ahk_class TscShellContainerClass")
Capslock::Esc
;Esc::Capslock
Esc::Return
; Ctrl+Esc for caps
^Esc::Capslock
; Shift+Esc for caps
;+Esc::Capslock
#HotIf
