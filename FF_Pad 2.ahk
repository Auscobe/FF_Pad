#Requires AutoHotkey v2.0


/*
Queueing as suggested by ChatGPT:

; Run all queued jobs
NumpadMult::
for job in Queue {
    RunJob(job)
}
Queue := []  ; clear queue after running
Tooltip("All jobs processed!", 2000)
return

; --- 4. Function to execute a job ---
RunJob(job) {
    MsgBox("Running job:" 
        "`nInput: " job.input 
        "`nTrim Start: " job.trim.start.m ":" job.trim.start.s 
        "`nCodec: " job.video.codec)
    ; Here you would call FFmpeg or other processing functions using the job data
}
*/

; Default command
FF_CMD := {
    Input: "",
    Output: "",
    Overwrite: "-n",
    Codec: FF_V_Codec.AV1,
    Container: "mp4"
}

; Options per argument
FF_V_Codec := {
    AV1: "-c:v libsvtav1",
    VP9: "-c:v libvpx-vp9",
    Copy: "-c:v copy"
}


FF_A_Codec := {
    Opus: "-c:a libopus",
    AAC: "-c:a aac"
}


FF_RenderUI() {


    Codec_V := {
        FF_CMD.Input
    }
}