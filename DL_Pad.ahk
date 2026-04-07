GroupAdd, Browser, ahk_exe Opera.exe
GroupAdd, Browser, ahk_exe Firefox.exe


DL_URL := ""
DL_Dest := ""


DL_trimMinSS := 0
DL_trimSecSS := 0
DL_trimHourSS := 0
DL_trimMinTo := 0
DL_trimSecTo := 0
DL_trimHourTo := 0
DL_trimSS := 0
DL_trimTo := 0
DL_trim := ""
DL_trimMode := "-ss"

DL_Format := "mp3"


DL_Active() {
	return WinActive("ahk_group Browser") and (DL_URL != "")
}

DL_CycleFormat() {
global DL_Format
DL_Format := (DL_Format = "mp3" ? "mp4" : "mp3")
}

/*
If WinActive("ahk_exe Opera.exe") or WinActive("ahk_exe Firefox.exe") {
	clipboard := "" ; Very important to first empty clipboard to avoid faulty checks later from existing contents!
	sleep, 30
	Send ^c
	ClipWait, 0.3
	DL_FileIn := clipboard
}
*/
DL_CycleTrim(delta=5) {
	global DL_trimMode, DL_trimSecSS, DL_trimMinSS, DL_trimSecTo, DL_trimMinTo
	If (DL_trimMode = "-ss") {
		DL_trimSecSS += delta
		if (DL_trimSecSS < 0) {
			DL_trimSecSS := 55
			if (DL_trimMinSS > 0)
				DL_trimMinSS -= 1
		}
		else if (DL_trimSecSS > 59) {
			DL_trimSecSS := 0
			DL_trimMinSS ++ 1
		}
		if (DL_trimMinSS > 59) {
			DL_trimMinSS = 0
			DL_trimHourSS += 1
		}
	} else If (DL_trimMode = "-to") {
		DL_trimSecTo += delta
		if (DL_trimSecTo < 0) {
			DL_trimSecTo := 55
			if (DL_trimMinTo > 0)
				DL_trimMinTo -= 1
		}
		else if (DL_trimSecTo > 59) {
			DL_trimSecTo := 0
			DL_trimMinTo += 1
		}
		if (DL_trimMinTo > 59) {
			DL_trimMinTo = 0
			DL_trimHourTo += 1
		}
	} else {
		DL_trimHourSS += delta
		if (DL_trimHourSS < 0)
			DL_trimHourSS := 0 ; Prevent Integer Underflow.
		if (DL_trimHourTo < 0)
			DL_trimHourTo := 0
	}
}

DL_CycleTrimMode() {
	global DL_trimMode
	DL_trimMode := (DL_trimMode = "-ss" ? "-to" : "-ss")
}

DL_GetURL() {
global DL_URL
clipboard := "" ; Very important to first empty clipboard to avoid faulty checks!
DL_URL := ""
Send ^c
ClipWait, 0.2
If (clipboard = "") or !WinActive("ahk_group Browser") { ; Get URL w/o Opera active. Adaptable later if I switch browsers. https://update.greasyfork.org/scripts/500544/Copy%20URL%20Alt%2BC%20-%20hotkey.user.js My current hotkey logic forbids inactive grab, may fix later.
	ControlGet, controlN, Hwnd,,Chrome_RenderWidgetHostHWND1, Opera
    ControlFocus,,ahk_id %controlN%
    ControlSend, Chrome_RenderWidgetHostHWND1, !+d, Opera ; I rebound it.
	ClipWait, 0.2
}
Send {esc}
DL_URL := RegExReplace(clipboard, "((youtu\.be/[^?&]+)|(youtube\.com/watch\?v=[^?&]+)).*", "$1") ; Fix for timestamp in URL causing video download instead of audio.
Send {Ctrl up}{Alt up}{Shift up}
clipboard := "" ; Clear again because it won't be needed anymore.
}


DL_Update() {
global DL_Command, DL_URL, DL_Dest, DL_trimMinSS, DL_trimSecSS, DL_trimHourSS, DL_trimMinTo, DL_trimSecTo, DL_trimHourTo, DL_trimSS, DL_trimTo, DL_trim, DL_trimMode

	formatTime := (DL_trimMinSS > 0 & DL_trimSecSS != "") ? DL_trimMinSS : ; This needs to be blank if empty.
	formatTime .= (DL_trimSecSS > 9) ? ":" DL_trimSecSS : ":0" DL_trimSecSS
	DL_trimSS := formatTime
	formatTime := (DL_trimMinTo > 0 & DL_trimSecTo != "") ? DL_trimMinTo : ; This needs to be blank if empty.
	formatTime .= (DL_trimSecTo > 9) ? ":" DL_trimSecTo : ":0" DL_trimSecTo
	DL_trimTo := formatTime

	formatTime := (DL_trimMinSS > 0 & DL_trimSecSS != "") ? DL_trimMinSS : ; This needs to be blank if empty.
	formatTime .= (DL_trimSecSS > 9) ? "-" DL_trimSecSS : "-0" DL_trimSecSS
	DL_trim_Filename := formatTime
	formatTime := (DL_trimMinTo > 0 & DL_trimSecTo != "") ? DL_trimMinTo : ; This needs to be blank if empty.
	formatTime .= (DL_trimSecTo > 9) ? "-" DL_trimSecTo : "-0" DL_trimSecTo
	DL_trim_Filename .=  "_" formatTime

	;DL_trimSS := (DL_trimSecSS || DL_trimMinSS ? DL_trimSS "-" : "")
	;DL_trimTo := (DL_trimSecTo || DL_trimMinTo ? DL_trimTo : "") ; Works for display, copy and tweak for command.
	DL_trim := (DL_trimSS||DL_trimTo ? "--download-sections ""*" DL_trimSS "-" DL_trimTo """ " : "")
	DL_trim_Display := (DL_trimSS ? DL_trimSS : "") (DL_trimSS && DL_trimTo ? "-" : "") (DL_trimTo ? DL_trimTo : "")
	
	DL_Command := "yt-dlp --downloader ffmpeg --merge-output-format mp4 ""-f bestvideo+bestaudio"" -S res,codec:av1 " DL_URL " " DL_trim " --no-playlist --add-metadata -o ""`%(title)s [" DL_trim_Filename "][%(id)s].`%(ext)s"""
	
	Tooltip, %DL_URL%`n`n%DL_trim_Display%`n`n%DL_Command%
}

DL_Reset(){
	global DL_URL, DL_trimSecSS, DL_trimMinSS, DL_trimHourSS, DL_trimSecTo, DL_trimMinTo, DL_trimHourTo, DL_trimMode
	tooltip
	DL_URL := ""
	DL_trimSecSS := 0
	DL_trimMinSS := 0
	DL_trimHourSS := 0
	DL_trimSecTo := 0
	DL_trimMinTo := 0
	DL_trimHourTo := 0
	DL_trimMode := "-ss"
}

DL_Run() {
global DL_Command, DL_URL
	run cmd /c %DL_Command%,D:\Videos, min
	clipboard := DL_Command
}


