
<pre>
Param(  [Parameter(Mandatory=$True)] [string]$path, [string]$dest)
    

$results = @()
#copies files from dialer to local directory for conversion to mp3
try {
    # Copy files from source to destination
    Copy-Item -Path "$Path" -Destination "$Dest" -Recurse -Force -ErrorAction Stop
    Write-Verbose "Files copied from '$Path' to '$Dest'"
}
catch {
    Write-Error "Error copying files: $($_.Exception.Message)"
    return  # Terminate the script if copying fails
}

Get-ChildItem -Path "$Dest" -Include "*.wav" -Recurse | ForEach-Object {
    $file_name_without_extension = $_.Name.Replace($_.Extension, '')
    $mp3_file_name = "$file_name_without_extension.mp3"
    $input_file = $_.FullName
    $output_directory = $_.DirectoryName
    $output_file = Join-Path $output_directory $mp3_file_name
    $ffmpeg_arguments = "-i `"$input_file`" -f mp3 `"$output_file`" -y"

    try {
        #  Execute ffmpeg
        Write-Verbose "Converting '$input_file' to '$output_file'"
        Invoke-Expression "$ffmpeg_path $ffmpeg_arguments 2>&1"  # Capture both stdout and stderr
        if ($LastExitCode -ne 0) {
            Write-Warning "ffmpeg returned a non-zero exit code ($LastExitCode) for '$input_file'"
            #  Consider logging the ffmpeg output (captured by 2>&1) for more detailed error info
        }

        #  Execute RecordingDBTool
        Write-Verbose "Processing '$output_file' with RecordingDBTool"
        & $recordingdbtool_path "$output_file"
        if ($LastExitCode -ne 0) {
            Write-Warning "RecordingDBTool returned a non-zero exit code ($LastExitCode) for '$output_file'"
        }

        #  Delete the original WAV file
        try {
            Remove-Item -Path $input_file -Force -ErrorAction Stop
            Write-Verbose "Deleted '$input_file'"
        }
        catch {
            Write-Warning "Error deleting '$input_file': $($_.Exception.Message)"
            #  Non-critical error, continue processing
        }
    }
    catch {
        Write-Warning "Error processing file '$input_file': $($_.Exception.Message)"
        #Skip file
    }
}

</pre>