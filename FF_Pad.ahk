; AMP is a lightweight media processing engine built in AutoHotkey for experienced users to assemble FFmpeg commands in seconds.
; It's very lightweight, easily expandable, and works directly with FFmpeg arguments. Know what you want. Build it fast.

; Glossary:
; FF_Job: Current job containing choices for input, output, and processing. (What do I want to do?)
; FF_Config: Available choices for FF_Job. (How does AMP know how to do it?)
; FF_Module: Major component of the engine.
; Jun 04 2026 12:58:59AM Switching to name AMP - AutoHotkey Media Processor.

; This engine is meant not to abstract FFmpeg i.e to a GUI, but make it faster to drive.

FF_Config := {}

FF_Config["VideoCodecList"] := []
FF_Config["VideoCodecList"].Push("-c:v libsvtav1 -map 0:v")
FF_Config["VideoCodecList"].Push("-c:v libvpx-vp9 -map 0:v")
FF_Config["VideoCodecList"].Push("-c:v libx264 -map 0:v")
FF_Config["VideoCodecList"].Push("-c:v copy -map 0:v")
FF_Config["VideoCodecList"].Push("-vn")

FF_Config["VideoCodecIndex"] := 1 ; May need to move this to FF_Job in the future should I want consistency of selection per job.

FF_Config["AudioCodecList"] := []
FF_Config["AudioCodecList"].Push("-c:a copy -map 0:a?")
FF_Config["AudioCodecList"].Push("-an")
FF_Config["AudioCodecList"].Push("-c:a copy -map 0:a:0")
FF_Config["AudioCodecList"].Push("-c:a copy -map 0:a:2")
FF_Config["AudioCodecList"].Push("-filter_complex amerge=inputs=2")
FF_Config["AudioCodecList"].Push("-map 0:a?")
FF_Config["AudioCodecList"].Push("-c:a aac -map 0:a?")

FF_Config["AudioCodecIndex"] := 1

FF_Module := {}
FF_Module["Interpolate"] := ""
FF_Queue := {} ; This should be iterated through variations of FF_Job as configured to form a queue of jobs; one export, multiple outputs.



FF_Job := {}

FF_Job["FileIn"] := ""
FF_Job["FileOut"] := ""
FF_Job["FileExist"] := "No"
FF_Job["Overwrite"] := "-n" ; Don't know yet if video, audio, and other processing will have different options for this, but for now just one global one.
FF_Job["TrimSS"] := 0
FF_Job["TrimTo"] := 0
FF_Job["TrimStart"] := ""
FF_Job["TrimEnd"] := ""
FF_Job["VideoCodec"] := FF_Config["VideoCodecList"][FF_Config["VideoCodecIndex"]]
FF_Job["VideoCodecPreset"] := 6
FF_Job["VideoCRF"] := 40
FF_Job["AudioCodec"] := FF_Config["AudioCodecList"][FF_Config["AudioCodecIndex"]]
FF_Job["WorkingDir"] := ""




FF_Layer := "Main" ; For my personal use from outside this library.

FF_FileIn := ""
FF_FileOut := ""
FF_FileExist := "No"
FF_Overwrite := "-n"

FF_Custom := ""
FF_Command := ""

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
finalFolder := ""
RIFECount := 0
outFPS := 0
inFPS := 0
FF_RIFE := 0


Chunky := 0

FF_Queue := []
FF_QueueList := ""
FF_SaveSettings := 0


FF_Active() { ; Jan 22 2026 5:23:40PM I recognize the possibility of wanting to activate/configure XX_Pad from another window, and will do that later for i.e youtube.
	return WinActive("ahk_group FileManager") and (FF_FileIn != "")
}

/*
FF_Upscale(file, scale="2") {
	Tooltip ; Premature reset lest it linger during whole upscale.
	global FF_Upscaled, FF_FileIn, FF_trimSS, FF_trimTo
	FileCreateDir, %fileDir%\in
	FileCreateDir, %fileDir%\out
	upscale := "ffmpeg %FF_trimSS% %FF_trimTo% -i ""%file%"" -qscale:v 1 ""%fileDir%\in\frame_`%05d.png"" && realesrgan -i ""%fileDir%\in"" -o ""%fileDir%\out"" -n 2x-Compact-RealESRGAN -s %scale% -j 3:3:3" ; Consider having FFmpeg -vf "fps=%inFPS%" or so for extraction.
	return """" fileDir "\out\frame_`%05d.png"""
}


FF_Interpolate(RIFECount=1, outFPS=60) { ; Yes ChatGPT helped with this function, how could you tell?
	global FF_Interp_Enabled, FF_Interp_Dir_In, FF_Interp_Dir_Out, FF_FileIn, inFPS ; Not working too well. Please just use flowframes.
	If !(outFPS = inFPS*2)
		outFPS := inFPS*2
	runWait cmd /c ffmpeg -i "%FF_FileIn%" -qscale:v 1 -qmin 1 -qmax 1 -vsync=vfr %FF_Interp_Dir_In%/frame_`%05d.png ;,,min
	
	Loop, %RIFECount% {
	i := A_Index
	; At some point this should add to the front of the final command, not run any itself.
	rifeIn := (Mod(i,2) = 1) ? FF_Interp_Dir_In : FF_Interp_Dir_Out ; Alternate between regular and recycle directory
	rifeOut := (Mod(i,2) = 1) ? FF_Interp_Dir_Out : FF_Interp_Dir_In ; Record which folder was last used
		
	RunWait, cmd /c rife -i "%rifeIn%" -o "%rifeOut%" -m rife-v4.26 ;,,min
	}
	finalFolder := rifeOut
	;runWait ffmpeg -r %outFPS% -i "%finalFolder%/frame_`%05d.png" -c:v libsvtav1 -preset 8 -r %outFPS% -pix_fmt yuv420p %fileDir%\%fileNameExtless%_.mp4 ;This function should not recompile.
	return finalFolder
}
*/

FF_CycleVideo(offset=1) { ; Later support names and absolute values.
	global FF_Job, FF_Config, VideoArgs
	FF_Config["VideoCodecIndex"] += offset
	FF_Config["VideoCodecIndex"] := (FF_Config["VideoCodecIndex"] < 1 ? FF_Config["VideoCodecList"].MaxIndex() : (FF_Config["VideoCodecIndex"] > FF_Config["VideoCodecList"].MaxIndex() ? 1 : FF_Config["VideoCodecIndex"]))
	FF_Job["VideoCodec"] := FF_Config["VideoCodecList"][FF_Config["VideoCodecIndex"]] ; Gradually migrating to FF_Job.
	;FF_Job["VideoCodec"] .= (FF_Job["VideoCodec"] != "Copy" ? " -preset 6 -map 0:v" : " -map 0:v") ; Jank, pls fix. During early migration, without this video won't be processed.

}


FF_CycleAudio(offset=1) {
	global FF_Job, FF_Config
	FF_Config["AudioCodecIndex"] += offset
	FF_Config["AudioCodecIndex"] := (FF_Config["AudioCodecIndex"] < 1 ? FF_Config["AudioCodecList"].MaxIndex() : (FF_Config["AudioCodecIndex"] > FF_Config["AudioCodecList"].MaxIndex() ? 1 : FF_Config["AudioCodecIndex"]))
	FF_Job["AudioCodec"] := FF_Config["AudioCodecList"][FF_Config["AudioCodecIndex"]]
	;msgbox, % FF_Job["AudioCodec"] " | " FF_Config["AudioCodecList"][FF_Config["AudioCodecIndex"]]
}


FF_CycleCRF(offset=1) {
	global FF_Job
	FF_Job["VideoCRF"] += offset
	FF_Job["VideoCRF"] := (FF_Job["VideoCRF"] < 0 ? 63 : (FF_Job["VideoCRF"] > 63 ? 0 : FF_Job["VideoCRF"]))
}

FF_CycleVideoCodecPreset(offset=1) {
	global FF_Job
	FF_Job["VideoCodecPreset"] += offset ; Later on let this identify max preset by codec and use a max preset variable.
	FF_Job["VideoCodecPreset"] := (FF_Job["VideoCodecPreset"] < 0 ? 13 : (FF_Job["VideoCodecPreset"] > 13 ? 0 : FF_Job["VideoCodecPreset"]))
}

FF_CycleOverwrite() {
	global FF_Overwrite
	FF_Overwrite := (FF_Overwrite = "-n" ? "-y" : "-n")
}

FF_CycleFileExt() {
	global fileExt
	fileExt := (fileExt = "mkv" ? "mp4" : "mkv")
}

	

FF_CycleTrim(offset=5, FF_trimMode="-ss") {
	global FF_trimSecSS, FF_trimMinSS, FF_trimSecTo, FF_trimMinTo, FF_trimSS, FF_trimTo, FF_Job
	If (FF_trimMode = "-ss") {
		FF_Job["TrimSS"] := FF_Job["TrimSS"] + offset
		FF_Job["TrimSS"] := (FF_Job["TrimSS"] < 0 ? 0 : FF_Job["TrimSS"])

		total_SS := FF_Job["TrimSS"]
		hours_SS := Floor(total_SS / 3600)
		mins_SS  := Floor(Mod(total_SS, 3600) / 60)
		secs_SS  := Mod(total_SS, 60)

		FF_Job["TrimStart"] := "-ss " (hours_SS > 0 ? hours_SS ":" : "") . (mins_SS > 0 ? mins_SS ":" : "0:") . (secs_SS > 9 ? secs_SS " " : "0" secs_SS " ")
		FF_Job["TrimStart"] := (hours_SS|mins_SS|secs_SS ? FF_Job["TrimStart"] " " : " ") ; Kinda bandaid but makes trim disappear if blank.
	}

	If (FF_trimMode ~= "-t") {
		FF_Job["TrimTo"] := FF_Job["TrimTo"] + offset
		FF_Job["TrimTo"] := (FF_Job["TrimTo"] < 0 ? 0 : FF_Job["TrimTo"])

		total_To := FF_Job["TrimTo"]
		hours_To := Floor(total_To / 3600)
		mins_To := Floor(Mod(total_To, 3600) / 60)
		secs_To := Mod(total_To, 60)

		FF_Job["TrimEnd"] := (hours_To > 0 ? hours_To ":" : "") . (mins_To > 0 ? mins_To ":" : "0:") . (secs_To > 9 ? secs_To : "0" secs_To)
		FF_Job["TrimEnd"] := (FF_Job["TrimEnd"] != "" ? (FF_trimMode ~= " -t" ? FF_trimMode : " -to") " " FF_Job["TrimEnd"] " " : "") ; Hide end trim if empty.
	}
}


FF_CycleTrimMode(mode="") { ; Reminder: -to is absolute, -t is relative to -ss.
	global FF_trimMode
	FF_trimMode := (mode != "" ? mode : (FF_trimMode != "-ss" ? "-ss" : "-to")) ; If mode specified, set to that, else toggle.
}


FF_CycleCrop(mode=""){ ; Will fix this jank later when I expand upon it.
	global FF_Crop
	FF_Crop := (mode != "" ? mode : (FF_Crop = " -vf crop=2560:1440:0:0 " ? " -vf scale=3840x2160:flags=lanczos " : " -vf crop=2560:1440:0:0 "))
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
	global FF_FileIn, FF_FileOut, fileName, fileExt, fileNameExtless, outFPS, inFPS, SelectedFile, VideoArgs, FF_Job

	If WinActive("ahk_exe Dopus.exe") or WinActive("ahk_exe Everything.exe") {
		clipboard := "" ; Very important to first empty clipboard to avoid faulty checks later from existing contents!
		sleep, 30
		Send ^+c
		ClipWait, 0.3
		filePath := (WinActive("ahk_class EVERYTHING") ? Trim(FF_FileIn, """") : clipboard) ; Everything.exe adds quotes anyway.
	}

	If (filePath = SelectedFile)
		return ; If file already selected, end here.

	SelectedFile := filePath
	If !(filePath ~= "youtube.com") {
		SplitPath, filePath, FF_Job["FileIn"], FF_Job["WorkingDir"], fileExt, fileNameExtless ; Prepare directory and name for later

		If (fileExt in jpg,jpeg,png) {
			;run realesrgan -i "%FF_FileIn%" -o "%fileDir%\%fileNameExtless%_p.%fileExt%" -n 2x-Compact-RealESRGAN -s 2
			;FF_Reset()
			;tooltip
			;return
		}

		RunWait cmd /c ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate "%filePath%" | clip,, hide
		ClipWait, 0.3
		
		p := StrSplit(clipboard, "/")
		inFPS := Round((p[1] + 0) / RegExReplace(p[2], "`r`n", "")) ; I love using as little code/few lines as possible. May be noob programmer thing, so be it.
		outFPS := inFPS ; Can format input/output framerate (in event of interpolating) as input>output, e.g 30>60.
		}
}


FF_Display(Type=""){ ; Jan 22 2026 6:03:55PM Formerly FF_Assemble, "Update" reflects that it updates definitions AND the display.
	global FF_trimMinSS, FF_trimSecSS, FF_trimMinTo, FF_trimSecTo, FF_trimSS, FF_trimTo, FF_trimMode, FF_Interp, FF_Interp_Recycle, FF_Command, FPS, outFPS, FF_Upscale, FF_FileOut, RIFECount, fileExt, fileNameExtless, newName, FF_Queue, FF_FileExist, FF_SaveSettings, FF_Custom, FF_Upscale, FF_Crop, FF_RIFE, FF_trimSS, FF_trimTo, FF_Job, FF_Layer, FF_Config

	If !(FF_Job["FileIn"] ~= "youtube.com") { ; Refactor this function later so only necessary code is run per situation (file or URL).
		FF_Job["FileOut"] := fileNameExtless . "_p." . fileExt

		;FF_Resolution := (FF_Upscale ? " -vf scale=3840:2160 " : "") ; I don't intend to upscale except to 4K for now.
;		FPS := (FF_RIFE ? "-r " inFPS*2 : "") ; Little hack so I get FPS to actually double. Seems as if outFPS is local in FF_Interpolate()?
	;FF_Job["MapVideo"] := (FF_Job["VideoCodec"] != "vn" ? "-map 0:v" : "")
	;VideoArgs := (FF_Job["VideoCodec"] != "vn" ? " -c:v " FF_Job["VideoCodec"] " " : " ") FF_Job["MapVideo"]
;		FF_Crop := ""
		If (Type = "bat") { ; Put these two, plus clipboard, into new function FF_Export() (maybe)
			FileDelete, %FileDir%\%FileNameExtless%.bat
			FileAppend, % "ffmpeg " FF_TrimSS "-i " FF_Job["FileIn"] " " FF_Job["VideoCodec"] " -crf " FF_Job["VideoCRF"] " " FF_Config["AudioCodec"] " " FF_TrimTo """"FileNameExtless "_p." fileExt " FF_Overwrite, %FileDir%\%FileNameExtless%.bat
		}
		else If !(Type = "DisplayOnly") ; Move this into Export function. Don't remake the command constantly.
			FF_Command := "-hide_banner " FF_Job["TrimStart"] "-i """ fileDir "\" FF_Job["FileIn"] """ " FF_Job["VideoCodec"] " -preset " FF_Job["VideoCodecPreset"] FF_Custom " " FF_Resolution FF_Crop " -crf " FF_Job["VideoCRF"] " " FF_Job["AudioCodec"] (FF_Upscale && FF_Job["TrimEnd"] != "-ss" ? "" : FF_Job["TrimEnd"]) " """ FF_FileOut """ " FF_Overwrite

		; Experiment with a for loop to build command, iterating through FF_Job.


		FF_FileExist := (FileExist(FF_FileOut) ? "*" : "")
		Display_RIFE := (FF_RIFE ? "RIFEs: " FF_RIFE "," : "")
		Display_Save := (FF_SaveSettings ? "$" : "") ; Compact save status.



		If !(Type = "NoDisplay")
		Tooltip, % FF_Job["FileIn"] . "`n" . FF_Job["VideoCodec"] " -preset " FF_Job["VideoCodecPreset"] " " FF_Job["AudioCodec"] " " FF_Job["TrimStart"] FF_Job["TrimEnd"] "`n(-crf " FF_Job["VideoCRF"] " " FF_Overwrite FF_FileExist " " FileExt ")`nLayer: " FF_Layer " | " FF_trimMode " | " Display_Save " " Display_Upscale " " Display_Crop " " Display_RIFE
		}
}


FF_Export() {
	global FF_Command, Chunky, c, FF_SaveSettings, FF_FileIn, FF_trimMinSS, FF_trimSecSS, FF_trimMinTo, FF_trimSecTo, FF_TrimMode, FF_Upscale, FF_RIFE, FF_Job
	If (FF_Upscale)
		FF_FileIn := FF_Upscale(FF_FileIn, 2) ; This automatically extracts and interpolates frames, and returns output folder.
	If (FF_RIFE)
		FF_FileIn := FF_Interpolate() ; Not working too well. Please just use flowframes.

	FF_Display("NoDisplay")
	Tooltip
	
	
	; Build command, have CMD do cd %workingdir%, get started on a more flexible setup this way to send to a node etc.
		Run cmd /c cd %FF_Job["WorkingDir"]% && ffmpeg %FF_Command%
}


FF_Reset() {
	global FF_FileIn, FF_TrimMode, FF_SaveSettings, FF_trimMinSS, FF_trimSecSS, FF_trimMinTo, FF_trimSecTo, FF_Overwrite, FF_Upscale, fileExt, FF_Config, FF_trimSS, FF_trimTo, FF_Job, FF_Layer

	FF_FileIn := "" ; Always reset this, lest selection break after confirming.
	FF_TrimMode := "-ss" ; Resetting this feels better for me.
	If !(FF_SaveSettings) {
		FF_trimMinSS := 0 ; Reset trim upon confirm.
		FF_trimSecSS := 0
		FF_trimMinTo := 0
		FF_trimSecTo := 0
		FF_Job["TrimSS"] := ""
		FF_Job["TrimTo"] := ""
		FF_Job["TrimStart"] := ""
		FF_Job["TrimEnd"] := ""
		FF_Job["CRF"] := 40 ; I'm just concerned about forgetting I changed this and making recordings lower quality than they need to be.
		FF_Overwrite := "-n"
		FF_Upscale := 0
		FF_Job["VideoCodec"] := FF_Config["VideoCodecList"][1]
		FF_Job["AudioCodec"] := FF_Config["AudioCodecList"][1]
		FF_Config["VideoCodecIndex"] := 1
		FF_Config["AudioCodecIndex"] := 1
		FF_Layer := "Main"
	}
}

/*
; Roadmap for v2 (some in library itself, some in hotkeys):
; Split code into internal modes: Input Mode (yt-dlp, image, video, audio), Proc Mode (video, audio, else), Output Mode (direct, bat, clipboard, etc) if beneficial.
; If folder is selected, first decide among compatible file types what will be processed by cycling and confirming through a tooltip list. Then decide per type what will be done to all.
; Merge all export options (Direct, .Bat, Clipboard, Custom Args/Command, Enqueue, Merge/Concatenate) into new function Export(), press to cycle and hold to execute.
; Dedicate layer to trimming, including decimal trim, trim time in filename, optionally set seek trim independently (no toggling between -ss/-to).
; Set Working Directory to wherever the file is for cleaner code, resetting after. (Is this really necessary?)
; Implement optional inclusion of trim times into output file name.
; Implement Queuing multiple files, with separate operations per file.
; Implement selection of multiple files for concatenating, which will "merge" into one action in the queue.
; Implement URL support through yt-dlp: Would allow for more flexible Youtube video downloading.
; Implement Chunking, outputting in chunks before merging into one (useful in case of interrupt).
; Implement the above IN SEPARATE LAYER TO BASIC FUNCTIONS, toggleable by NumpadMult for me.
; Let all the above work independently, and be able to string into each other with minimal intermediate encoding. Let all commands be in one CMD. Warn user of any failure?
; Add preset capability, either as functions within the base file or .inis next to it, or both.
; Add ability to string together filters with ease, selecting which ones and confirming one by one.
; Add toggleable ability to interpret "flags" in input filename as instructions, i.e "2026_av1.mp4" would be automatically set to AV1 for output.
; Implement (as framework?) in AHKv2. In doing so, ensure ALL variables start with FF_ (Jul 05 2026 12:10:42AM or AMP_ ?)



; I want to structure this better, and have a vague idea what I should do (decoupling things in functions, i.e not hardcoding how to increase/decrease values).

Mar 13 2026 7:31:40PM
Development has been inactive for a few weeks now. I have a few ideas for how I could proceed;
1: Refactor this codebase some (put all variables into an object or array, whatever more compact form will work, and fix the scope of the functions.) so that v2 conversion is pure translation, meaning less mental overhead.
2: Put it into AHKv2 without further developing this version.

Right now I've decided to: Moving the bulk of the logic for command assembly from the single function FF_Display() to their respective functions that deal with that stuff to start with anyway. Then FF_Display is cleaner and the overall codebase more readable and maintainable.
(Mar 16 2026 9:34:12PM But I still can't make up my mind confidently without feedback from more experienced devs.)

No need for ternary statements in the command variable, do that prior.