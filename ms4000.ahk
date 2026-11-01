#Requires AutoHotkey v2.0+
#SingleInstance Force

; ============================================================
; Microsoft Natural Ergonomic Keyboard 4000
; My Favorites 1 → set default playback device to "Speaker"
; ============================================================

myGui := Gui("+ToolWindow")
myGui.Show("Hide")
hwnd := myGui.Hwnd

; Register for the special HID collection (Usage Page 0x0C, Usage 0x01)
rid := Buffer(8 + A_PtrSize, 0)
NumPut("UShort", 0x0C, rid, 0)
NumPut("UShort", 0x01, rid, 2)
NumPut("UInt",   0x00000100, rid, 4)    ; RIDEV_INPUTSINK
NumPut("Ptr",    hwnd, rid, 8)

if !DllCall("RegisterRawInputDevices", "Ptr", rid, "UInt", 1, "UInt", rid.Size) {
    MsgBox "Failed to register Raw Input.`nError: " A_LastError, "Error", 16
    ExitApp
}

OnMessage(0x00FF, OnRawInput)
Persistent

; ============================================================
OnRawInput(wParam, lParam, *) {
    static headerSize := 8 + A_PtrSize * 2

    size := 0
    DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", 0, "UInt*", &size, "UInt", headerSize)
    if (size < 1)
        return

    buf := Buffer(size, 0)
    if (DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", buf, "UInt*", size, "UInt", headerSize) = -1)
        return

    if (NumGet(buf, 0, "UInt") != 2)   ; RIM_TYPEHID
        return

    dataOffset := headerSize + 8
    if (size < dataOffset + 8)
        return

    hex := ""
    loop 8
        hex .= Format("{:02X}", NumGet(buf, dataOffset + A_Index - 1, "UChar"))

    ; My Favorites 1
    if (hex = "0100000000050000" || hex = "0100000000040000") {
        SetDefaultAudioDevice("Headphones (3- ANC918 Stereo)")
    }
    ; My Favorites 1
    if (hex = "0100000000050000" || hex = "0100000000040000") {
        SetDefaultAudioDevice("Headphones (3- ANC918 Stereo)")
    }
if (hex = "0100000000050000" || hex = "0100000000040000") {
    SetDefaultAudioDevice("Headphones (3- ANC918 Stereo)")
}
else if (hex = "0100000000090000" || hex = "0100000000080000") {
    SetDefaultAudioDevice("Speakers")
}
else if (hex = "0100000000110000" || hex = "0100000000100000") {
    ;SetDefaultAudioDevice("2 - Y27h-30(AMD High Definition Audio Device)")
    SetDefaultAudioDevice("2 - Y27h-30 (AMD High Definition Audio Device)")
}
else if (hex = "0100000000210000" || hex = "0100000000200000") {
    SetDefaultAudioDevice("YourDevice4")
}
else if (hex = "0100000000410000" || hex = "0100000000400000") {
    SetDefaultAudioDevice("YourDevice5")
}


}

; ============================================================
SetDefaultAudioDevice(DeviceName) {
    static IPolicyConfig := 0
    if !IPolicyConfig
        IPolicyConfig := ComObject("{870AF99C-171D-4F9E-AF0D-E63DF40C2BC9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")

    deviceId := GetDeviceId(DeviceName)
    if !deviceId {
        TrayTip "Device not found", '"' DeviceName '" not found among active playback devices.', 2
        return
    }

    ComCall(13, IPolicyConfig, "Str", deviceId, "UInt", 0)   ; SetDefaultEndpoint, eConsole
    TrayTip "Audio switched", "Default device → " DeviceName, 1
}

GetDeviceId(Name) {
    enumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    ComCall(3, enumerator, "UInt", 0, "UInt", 1, "Ptr*", &collection := 0)  ; eRender + ACTIVE
    ComCall(3, collection, "UInt*", &count := 0)

    ; PKEY_Device_FriendlyName
    propkey := Buffer(20, 0)
    DllCall("ole32\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "Ptr", propkey)
    NumPut("UInt", 14, propkey, 16)

    loop count {
        ComCall(4, collection, "UInt", A_Index - 1, "Ptr*", &device := 0)
        ComCall(5, device, "Ptr*", &idPtr := 0)
        id := StrGet(idPtr)
        DllCall("ole32\CoTaskMemFree", "Ptr", idPtr)

        ComCall(4, device, "UInt", 0, "Ptr*", &store := 0)   ; STGM_READ

        propvar := Buffer(24, 0)
        hr := ComCall(5, store, "Ptr", propkey, "Ptr", propvar)
        friendlyName := ""
        if (hr = 0) {
            namePtr := NumGet(propvar, 8, "Ptr")
            if namePtr {
                friendlyName := StrGet(namePtr, "UTF-16")
                DllCall("ole32\PropVariantClear", "Ptr", propvar)
            }
        }

        ObjRelease(store)
        ObjRelease(device)

        if InStr(friendlyName, Name)
            return id
    }
    return ""
}