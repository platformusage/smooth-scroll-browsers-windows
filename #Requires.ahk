#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; =========================
; CONFIG (настройки)
; =========================

global Enabled := true

; Для каких приложений включать сглаживание (процесс активного окна)
global TargetApps := ["chrome.exe", "msedge.exe", "firefox.exe", "opera.exe", "brave.exe"]

; Сколько микрошагов на 1 щелчок колеса (6–12 обычно комфортно)
global Steps := 8

; Задержка между микрошагами (мс)
global DelayMs := 8

; Базовая дельта одного “щелчка” колеса Windows (обычно 120)
global BaseWheelDelta := 120

; Множитель "инерции" (1.0 = не увеличивать прокрутку, >1.0 = чуть больше, <1.0 = меньше)
global InertiaFactor := 1.0

; Выбор easing-кривой: "easeOutCubic" (по умолчанию) или "easeOutQuad"
global EasingMode := "easeOutCubic"

; Горячая клавиша для включить/выключить: Ctrl + Alt + S
global ToggleHotkey := "^!s"

; =========================
; TRAY MENU
; =========================

SetupTrayMenu()

; =========================
; HOTKEYS
; =========================

; Toggle enable/disable
Hotkey(ToggleHotkey, ToggleEnabled)

; Колесо мыши
$WheelUp::WheelHandler(+1)
$WheelDown::WheelHandler(-1)

; =========================
; FUNCTIONS
; =========================

SetupTrayMenu() {
    A_TrayMenu.Delete()

    A_TrayMenu.Add("Enabled", ToggleEnabled)
    if Enabled
        A_TrayMenu.Check("Enabled")

    A_TrayMenu.Add()  ; separator

    A_TrayMenu.Add("Reload", (*) => Reload())
    A_TrayMenu.Add("Exit", (*) => ExitApp())

    ; Подсказка в трее
    UpdateTrayTip()
}

UpdateTrayTip() {
    status := Enabled ? "ON" : "OFF"
    A_IconTip := "Smooth Scroll (AHK v2) [" status "]`nToggle: " ToggleHotkey
}

ToggleEnabled(*) {
    global Enabled
    Enabled := !Enabled

    if Enabled
        A_TrayMenu.Check("Enabled")
    else
        A_TrayMenu.Uncheck("Enabled")

    UpdateTrayTip()
    TrayTip("Smooth Scroll", "Enabled: " (Enabled ? "ON" : "OFF"), 1)
}

WheelHandler(dir) {
    global Enabled

    ; Если выключено — отдаём событие как есть
    if !Enabled {
        Send(dir > 0 ? "{WheelUp}" : "{WheelDown}")
        return
    }

    ; Если активное окно не из списка — отдаём событие как есть
    if !IsTargetActive() {
        Send(dir > 0 ? "{WheelUp}" : "{WheelDown}")
        return
    }

    SmoothWheel(dir)
}

IsTargetActive() {
    global TargetApps
    try proc := WinGetProcessName("A")
    catch
        return false

    proc := StrLower(proc)
    for _, name in TargetApps {
        if proc = StrLower(name)
            return true
    }
    return false
}

SmoothWheel(dir) {
    global Steps, DelayMs, BaseWheelDelta, InertiaFactor, EasingMode

    ; Сколько “итого” отправлять (в целых)
    total := Round(dir * BaseWheelDelta * InertiaFactor)
    if total = 0 {
        return
    }

    ; Распределяем total на Steps микродельт по easing кривой:
    ; weight_i = Ease(i/Steps) - Ease((i-1)/Steps), сумма весов = 1
    sent := 0
    carry := 0.0
    prev := 0.0

    Loop Steps {
        t := A_Index / Steps
        curr := Ease(t, EasingMode)
        w := curr - prev
        prev := curr

        raw := (total * w) + carry

        ; Корректное округление для отрицательных значений:
        step := (raw >= 0) ? Floor(raw) : Ceil(raw)
        carry := raw - step

        if step != 0 {
            ; mouse_event(MOUSEEVENTF_WHEEL=0x0800, dwData=step)
            DllCall("mouse_event", "UInt", 0x0800, "Int", 0, "Int", 0, "Int", step, "UPtr", 0)
            sent += step
        }

        Sleep DelayMs
    }

    ; Добиваем остаток, если из-за округления недослали/переслали
    remainder := total - sent
    if remainder != 0 {
        DllCall("mouse_event", "UInt", 0x0800, "Int", 0, "Int", 0, "Int", remainder, "UPtr", 0)
    }
}

Ease(t, mode) {
    ; t в диапазоне [0..1]
    if (t <= 0)
        return 0.0
    if (t >= 1)
        return 1.0

    if (mode = "easeOutQuad") {
        ; f(t)=1-(1-t)^2
        return 1.0 - (1.0 - t) * (1.0 - t)
    }

    ; default: easeOutCubic
    ; f(t)=1-(1-t)^3
    u := 1.0 - t
    return 1.0 - (u * u * u)
}