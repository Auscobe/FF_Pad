FF_FileIn := ""
FF_FileOut := ""
FF_FileExist := "No"
FF_Overwrite := "-n"

FF_Codecs := "-c:v libsvtav1 -preset 8 -map 0:v"
FF_Audios := ["-c:a copy -map 0?", "-an", "-c:a copy -map 0:a:0", "-c:a copy -map 0:a:2", "-filter_complex amerge=inputs=2", "-map 0:a?", "-c:a aac -map 0:a?"]
FF_CRF := 34
FF_Custom := ""
FF_Command := ""

FF_AudioIndex := 1
; Audio options: Copy, no audio, track 1, track 3, merge tracks 1/2.

FF_trimMinSS := 0
FF_trimSecSS := 0
FF_trimMinTo := 0
FF_trimSecTo := 0
FF_trimHourSS := 0
FF_trimHourTo := 0
FF_trimMode := "-ss"

FF_Upscale := 0

FF_Interp_Dir_In := "F:\Work\AHK\Input\RIFE"
FF_Interp_Dir_Out := "F:\Work\AHK\Output\RIFE"
;FF_Interp := "rife -i " FF_Interp_Dir_In " -o " FF_Interp_Dir_Out " -f frame_`%05d.png -m rife-v4.24"
;FF_Interp_Recycle := "rife -i " FF_Interp_Dir_Out " -o " FF_Interp_Dir_In " -f frame_`%05d.png -m rife-v4.24" ; Reuse Input folder for additional interpolation, enabling indefinite iteration.
finalFolder := ""
RIFECount := 0
outFPS := 0
inFPS := 0
FF_RIFE := 0


Chunky := 0

FF_Queue := []
FF_QueueList := ""
FF_SaveSettings := 0


FF_Active() { ; Jan 22 2026 5:23:40PM I recognize the possibility of wanting to configure (not activate) XX_Pad from another window, and consider it an edge case.
	return WinActive("ahk_group FileManager") and (FF_FileIn != "")
}


GetTriggerKey(hk := "") {
    if (hk = "")
        hk := A_ThisHotkey

    ; Remove modifiers
    hk := RegExReplace(hk, "[#!\^\+<>]")

    ; If chord, take the last key
    if InStr(hk, "&")
        hk := Trim(StrSplit(hk, "&").Pop())

    return Trim(hk)
}


FF_Upscale(file, scale="2") {
	Tooltip ; Premature reset lest it linger during whole upscale.
	global fileDir, FF_Upscaled, FF_FileIn, FF_trimSS, FF_trimTo
	FileCreateDir, %fileDir%\in
	FileCreateDir, %fileDir%\out
	RunWait cmd /c ffmpeg %FF_trimSS% %FF_trimTo% -i "%file%" -qscale:v 1 "%fileDir%\in\frame_`%05d.png" && realesrgan -i "%fileDir%\in" -o "%fileDir%\out" -n 2x-Compact-RealESRGAN -s %scale% -j 3:3:3 ; Consider having FFmpeg -vf "fps=%inFPS%" or so for extraction.
	return """" fileDir "\out\frame_`%05d.png"""
}


FF_Interpolate(RIFECount=1, outFPS=60) { ; Yes ChatGPT helped with this function, how could you tell?
	global FF_Interp_Enabled, FF_Interp_Dir_In, FF_Interp_Dir_Out, FF_FileIn, inFPS ; Not working too well. Please just use flowframes.
	; No need to establish base FPS, file is already selected.
	If !(outFPS = inFPS*2) ; If outFPS not specified, x2 inFPS.
		outFPS := inFPS*2
	runWait cmd /c ffmpeg -i "%FF_FileIn%" -qscale:v 1 -qmin 1 -qmax 1 -vsync=vfr %FF_Interp_Dir_In%/frame_`%05d.png ;,,min
	
	Loop, %RIFECount% { ; Interpolation loop
	i := A_Index
	; Create two variables in the scope of this function for simplicity.
	rifeIn := (Mod(i,2) = 1) ? FF_Interp_Dir_In : FF_Interp_Dir_Out ; Alternate between regular and recycle directory
	rifeOut := (Mod(i,2) = 1) ? FF_Interp_Dir_Out : FF_Interp_Dir_In ; Record which folder was last used
		
	RunWait, cmd /c rife -i "%rifeIn%" -o "%rifeOut%" -m rife-v4.26 ;,,min
	}
	; Post-Interpolation logic
	finalFolder := rifeOut
	;runWait ffmpeg -r %outFPS% -i "%finalFolder%/frame_`%05d.png" -c:v libsvtav1 -preset 8 -r %outFPS% -pix_fmt yuv420p %fileDir%\%fileNameExtless%_.mp4 ;This function should not recompile.
	return finalFolder
}


FF_CycleVideo() {
global FF_FileIn, FFPad_Window,fileext, FF_Codecs, FFPad_Window
	;If (fileext ~= "jpg") { ; This is to be separated into its own thing, IMG_Pad? Mar 08 2026 11:40:44PM nah, just not dealing with non-videos yet.
	;	name := RegExReplace(FF_FileIn, "(.*)\.", "$1_a.")
	;	name := RegExReplace(name, "\.(jpeg|png)$", ".jpg") ; "\.(jpeg|png)$" for doing both, but some images won't be able to be jpg.
	;	run realesrgan -i "%FF_FileIn%" -o "%name%" -n 4x-Compact-RealESRGAN -s 4
	;	return
	;}
	key := GetTriggerKey()
	KeyWait, %key%, T0.2
	If Errorlevel
		FF_Codecs := "-c:v copy -map 0:v"
	else
		FF_Codecs := ((FF_Codecs = "-c:v av1_amf") ? "-c:v libsvtav1 -preset 8 -map 0:v" : "-c:v av1_amf")
}


FF_CycleAudio() {
	global FF_AudioIndex, FF_Audios
	key := GetTriggerKey()
	KeyWait, %key%, T0.2
	If Errorlevel
		FF_AudioIndex := ((FF_AudioIndex = 1) ? FF_Audios.MaxIndex() : --FF_AudioIndex) ; Quick cycle back
	else
		FF_AudioIndex := ((FF_AudioIndex = FF_Audios.MaxIndex()) ? 1 : ++FF_AudioIndex) ; A one-liner for dealing with this array.
}




FF_CycleMisc() { ; Should probably abstract these to separate functions, if not modify the vars directly by hotkey.
	global FF_CRF, FF_Overwrite, fileext, FF_trimMode
	key := GetTriggerKey()
	KeyWait, %key%, T0.2
	
	If (FF_trimMode = "-ss") {
		If Errorlevel
			FF_CRF := (FF_CRF < 1 ? 63 : --FF_CRF)
		else
			FF_CRF := (FF_CRF > 62 ? 0 : ++FF_CRF)
		
	}
	else If (FF_trimMode = "-to") {
		If Errorlevel
			FF_Overwrite := (FF_Overwrite = "-n" ? "-y" : "-n")
		else
			fileExt := (fileExt = "mkv" ? "mp4" : "mkv")
	}
}


FF_CycleTrim(delta=5) {
	global FF_trimMode, FF_trimSecSS, FF_trimMinSS, FF_trimSecTo, FF_trimMinTo
	If (FF_trimMode = "-ss") {
		FF_trimSecSS += delta
		if (FF_trimSecSS < 0) {
			FF_trimSecSS := 55
			if (FF_trimMinSS > 0)
				FF_trimMinSS -= 1
		}
		else if (FF_trimSecSS > 59) {
			FF_trimSecSS := 0
			FF_trimMinSS ++ 1
		}
	} else If (FF_trimMode ~= "-t") { ; Account for both -t and -to
		FF_trimSecTo += delta
		if (FF_trimSecTo < 0) {
			FF_trimSecTo := 55
			if (FF_trimMinTo > 0)
				FF_trimMinTo -= 1
		}
		else if (FF_trimSecTo > 59) {
			FF_trimSecTo := 0
			FF_trimMinTo += 1
		}
	}
}


FF_CycleTrimMode() {
	global FF_trimMode
	key := GetTriggerKey()
	KeyWait, %key%, T0.3
	If Errorlevel {
		FF_trimMode = "-t"
		KeyWait, %key%, T0.1
		sleep, 100
	}
	else
		FF_trimMode := (FF_trimMode != "-ss") ? "-ss" : "-to" ; Clean way to account for -ss and -t.
}


FF_CycleCrop(){
	global FF_Crop
	key := GetTriggerKey()
	KeyWait, %key%, T0.3
	If Errorlevel {
		FF_Crop := ""
	} else
		FF_Crop := (FF_Crop = " -vf crop=2560:1440:0:0 " ? " -vf scale=3840x2160:flags=lanczos " : " -vf crop=2560:1440:0:0 ")
}


FF_CycleRIFE() { ; Just to get started on it here.
	global FF_RIFE
	FF_RIFE := !FF_RIFE		
}


FF_CycleUpscale() {
	global FF_Upscale
	FF_Upscale := !FF_Upscale
}


FF_ToggleSave() {
	global FF_SaveSettings
	FF_SaveSettings := !FF_SaveSettings
}


FF_SelectFile(){
global FF_FileIn, FF_FileOut, fileName, fileDir, fileExt, fileNameExtless, outFPS, inFPS, SelectedFile

If WinActive("ahk_class CabinetWClass")
	FF_FileIn := Explorer_GetSelected()
	
else If WinActive("ahk_exe Dopus.exe") or WinActive("ahk_exe Everything.exe") {
	clipboard := "" ; Very important to first empty clipboard to avoid faulty checks later from existing contents!
	sleep, 30
	Send ^+c
	ClipWait, 0.3
	FF_FileIn := (WinActive("ahk_class EVERYTHING") ? Trim(FF_FileIn, """") : clipboard) ; Everything.exe adds quotes anyway.
}

If (FF_FileIn = SelectedFile)
	return ; If file already selected, end here.

SelectedFile := FF_FileIn
If !(FF_FileIn ~= "youtube.com") {
	SplitPath, FF_FileIn, fileName, fileDir, fileExt, fileNameExtless ; Prepare directory and name for later

	;If (fileExt in jpg,jpeg,png) {
;		run realesrgan -i "%FF_FileIn%" -o "%fileDir%\%fileNameExtless%_p.%fileExt%" -n 2x-Compact-RealESRGAN -s 2
;		FF_Reset()
;		tooltip
;		return
;	}

	RunWait cmd /c ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate "%FF_FileIn%" | clip,, hide
	ClipWait, 0.3
	
	p := StrSplit(clipboard, "/")
	inFPS := Round((p[1] + 0) / RegExReplace(p[2], "`r`n", "")) ; I love using as little code/few lines as possible. May be noob programmer thing, so be it.
	outFPS := inFPS ; Can format input/output framerate (in event of interpolating) as input>output, e.g 30>60.
	}
}


FF_Update(Type=""){ ; Jan 22 2026 6:03:55PM Formerly FF_Assemble, "Update" reflects that it updates definitions AND the display.
global FF_Audios, FF_AudioIndex, FF_Codecs, FF_trimMinSS, FF_trimSecSS, FF_trimMinTo, FF_trimSecTo, FF_trimSS, FF_trimTo, FF_trimMode, FF_Interp, FF_Interp_Recycle, FF_Command, FPS, outFPS, FF_Upscale, FF_FileIn, FF_FileOut, fileName, RIFECount, fileExt, fileNameExtless, fileDir, newName, FF_Queue, FF_FileExist, FF_CRF, FF_SaveSettings, FF_Custom, FF_Upscale, FF_Crop, FF_RIFE

;If !(fileExt = "mp4" || fileExt = "mkv" || fileExt = "webm") and !WinActive("ahk_group Browser") ; This will be obsolete when I integrate more filetype handling.
;	return

formatTime := (FF_trimMinSS > 0 & FF_trimSecSS != "") ? FF_trimMinSS : ; This needs to be blank if empty.
formatTime .= (FF_trimSecSS > 9) ? ":" FF_trimSecSS : ":0" FF_trimSecSS
FF_trimSS := formatTime
formatTime := (FF_trimMinTo > 0 & FF_trimSecTo != "") ? FF_trimMinTo : ; This needs to be blank if empty.
formatTime .= (FF_trimSecTo > 9) ? ":" FF_trimSecTo : ":0" FF_trimSecTo
FF_trimTo := formatTime


;FF_Command := FF_Codecs . " " . FF_Audio . " " . (FF_trimSecSS != 0||FF_trimMinSS != 0 ? " -ss " FF_trim : "")


If !(FF_FileIn ~= "youtube.com") { ; Refactor this function later so only necessary code is run per situation (file or URL).
	FF_Interp_Mode := "RIFE " . FPS . "x" . outFPS . "FPS"
	; FF_Interp
	FF_FileOut := fileDir . "\" . fileNameExtless . "_p." . fileExt

	FF_Audio := FF_Audios[FF_AudioIndex]

	FF_trimSS := (FF_trimSecSS||FF_trimMinSS ? " -ss " FF_trimSS : "")
	FF_trimTo := (FF_trimSecTo||FF_trimMinTo ? " " FF_trimMode " " FF_trimTo : "") ; Needs user to finish updating with -to or -t active.
	
	FF_Resolution := (FF_Upscale ? " -vf scale=3840:2160 " : "") ; I don't intend to upscale except to 4K for now.
	FPS := (FF_RIFE ? "-r " inFPS*2 : "") ; Little hack so I get FPS to actually double. Seems as if outFPS is local in FF_Interpolate()?

	If (Type = "bat") { ; Put these two, plus clipboard, into new function FF_Export() (maybe)
		FileDelete, %FileDir%\%FileNameExtless%.bat
		FileAppend, ffmpeg %FF_TrimSS% -i "%fileName%" %FF_Codecs% %FF_Audio% %FF_TrimTo% "%FileNameExtless%_p.%fileExt%" %FF_Overwrite%, %FileDir%\%FileNameExtless%.bat
	}
	else If !(Type = "DisplayOnly") ; I made this before realizing another way for my issue, keeping anyway.
		FF_Command := " -hide_banner " . (FF_Upscale ? "" : FF_trimSS) . FPS . " -i """ . fileDir . "\" . fileName . """ " . FF_Codecs . " " . FF_Custom . " " . FF_Resolution . FF_Crop . " -crf " . FF_CRF . " " . FF_Audio . (FF_Upscale && FF_trimTo != "-ss" ? "" : FF_trimTo) . " """ . FF_FileOut . """ " . FF_Overwrite



	FF_FileExist := (FileExist(FF_FileOut) ? "*" : "")
	Display_RIFE := (FF_RIFE ? " RIFEs: " FF_RIFE "," : "")
	Display_Save := (FF_SaveSettings ? " Save: On" : " Save: Off")
	Display_Upscale := (FF_Upscale ? " Upscale: 4K" : " Upscale: Off")
	Display_Crop := (FF_Crop ~= "1440" ? "Crop: 1440p" : "") (FF_Crop ~= "1080" ? "Crop: 1080p" : "")

	If !(Type = "NoDisplay")
	Tooltip, % FileName . "`n" . FF_Codecs . " " . FF_Audio . FF_trimSS . FF_trimTo . "`n(-crf " . FF_CRF . " " . FF_Custom . " " FF_Overwrite . FF_FileExist ")`nMode: " . FF_trimMode . "|" . Display_RIFE . "FPS: " . inFPS . "|" . fileExt . "|" . Display_Save . Display_Upscale . "|" . Display_Crop . "`n`n " . FF_Queue ; FF_Interp_Mode ; . " " . FF_Upscale
	;Chunky := 
	}
}


FF_Run() {
global FF_Command, Chunky, c, FF_SaveSettings, FF_FileIn, FF_trimMinSS, FF_trimSecSS, FF_trimMinTo, FF_trimSecTo, FF_TrimMode, FF_CRF, FF_Upscale, FF_RIFE, fileDir, FF_Interp_Dir_In, FF_Interp_Dir_Out
	If (FF_Upscale)
		FF_FileIn := FF_Upscale(FF_FileIn, 2) ; This automatically extracts and interpolates frames, and returns output folder.
	If (FF_RIFE)
		FF_FileIn := FF_Interpolate() ; Not working too well. Please just use flowframes.

	FF_Update("NoDisplay")
	Tooltip
	RunWait cmd /c ffmpeg %FF_Command% ; In v2, add upscale/interpolation commands in front of this to do it in one CMD.
	;clipboard := FF_Command
	If (FF_Upscale) {
		FileRemoveDir, %fileDir%\in, 1
		FileRemoveDir, %fileDir%\out, 1
	}
	If (FF_RIFE) {
		FileRemoveDir, %FF_Interp_Dir_In%\*.png
		FileRemoveDir, %FF_Interp_Dir_Out%\*.png
	}
}


FF_Reset() {
	global FF_FileIn, FF_TrimMode, FF_SaveSettings, FF_trimMinSS, FF_trimSecSS, FF_trimMinTo, FF_trimSecTo, FF_CRF, FF_Overwrite, FF_Upscale

	FF_FileIn := "" ; Always reset this, lest selection break after confirming.
	FF_TrimMode := "-ss" ; Resetting this feels better for me.
	If !(FF_SaveSettings) {
	FF_trimMinSS := 0 ; Reset trim upon confirm.
	FF_trimSecSS := 0
	FF_trimMinTo := 0
	FF_trimSecTo := 0
	FF_CRF := 34 ; I'm just concerned about forgetting I changed this and making recordings lower quality than they need to be.
	FF_Overwrite := "-n"
	FF_Upscale := 0
	}
}

/*
; Roadmap for v2 (some in library itself, some in hotkeys):
; Split code into modes: Input Mode (yt-dlp, image, video, audio), Proc Mode (video, audio, else), Output Mode (direct, bat, clipboard, etc)
; Merge all export options (Direct, .Bat, Clipboard, Custom Args/Command) into new function Export(), press to cycle and hold to execute.
; Dedicate layer to trimming, including decimal trim, trim time in filename, optionally set seek trim independently (no toggling between -ss/-to).
; Set Working Directory to wherever the file is for cleaner code, resetting after. (Is this really necessary?)
; Implement optional inclusion of trim times into output file name.
; Implement Queuing multiple files, with separate operations per file.
; Implement selection of multiple files for concatenating, which will "merge" into one action in the queue.
; Implement URL support through yt-dlp: Would allow for more flexible Youtube video downloading.
; Implement Chunking, outputting in chunks before merging into one (useful in case of interrupt).
; Implement the above IN SEPARATE LAYER TO BASIC FUNCTIONS, toggleable by NumpadMult for me.
; Let all the above work independently, and be able to string into each other with minimal intermediate encoding.
; Add preset capability, either as functions within the base file or .inis next to it, or both.
; Add ability to string together filters with ease, selecting which ones and confirming one by one.
; Add ability to interpret "flags" in input filename as instructions, i.e "2026_av1.mp4" would be automatically set to AV1 for output.
; Implement (as framework?) in AHKv2. In doing so, ensure ALL variables start with FF_

; I want to structure this better, and have a vague idea what I should do (decoupling things in functions, i.e not hardcoding how to increase/decrease values).

No need for ternary statements in the command variable, do that prior.