@echo off

set inurl=%~1
set resolution=%~2
set format=95

if not DEFINED inurl (
  echo Usage: %~n0 [Live URL] [Resolution 144^|240^|360^|480^|720^|1080]
  echo   Example %~n0 "https://www.youtube.com/watch?v=9Auq9mYxFEE" 720
  echo   Example %~n0 "https://www.youtube.com/watch?v=9Auq9mYxFEE"
  echo   Resolution default 720
  goto end
)

set PROXY=127.0.0.1:9777
if DEFINED PROXY (
  set HTTP_PROXY=http://%PROXY%
  set HTTPS_PROXY=http://%PROXY%
  echo ffmpeg use proxy %PROXY%
)

if not DEFINED resolution (
  set format=95,300
) else (
  if "%resolution%"=="144" set format=91
  if "%resolution%"=="240" set format=92
  if "%resolution%"=="360" set format=93
  if "%resolution%"=="480" set format=94
  if "%resolution%"=="720" set format=95,300
  if "%resolution%"=="1080" set format=96,301
)

set headers="Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7 \nAccept-Language: en-us,en;q=0.5\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.112 Safari/537.36"

set t=%time::=%
set t=%t: =0%
set outf=youtube.live_%date:-=%-%t:~0,6%
set outf=%outf: =_%

REM 91           mp4        256x144    HLS  269k , avc1.4d400c, 30.0fps, mp4a.40.5@ 48k
REM 92           mp4        426x240    HLS  507k , avc1.4d4015, 30.0fps, mp4a.40.5@ 48k
REM 93           mp4        640x360    HLS  962k , avc1.4d401e, 30.0fps, mp4a.40.2@128k
REM 94           mp4        854x480    HLS 1282k , avc1.4d401f, 30.0fps, mp4a.40.2@128k
REM 95           mp4        1280x720   HLS 2447k , avc1.4d401f, 30.0fps, mp4a.40.2@256k
REM 96           mp4        1920x1080  HLS 4561k , avc1.4d4028, 30.0fps, mp4a.40.2@256k (best)

echo Fetching live stream url ...
if DEFINED PROXY (
  echo "youtube-dl.exe --proxy http://%PROXY% "%inurl%" -f %format% -g>%outf%.txt"
  youtube-dl.exe --proxy http://%PROXY% "%inurl%" -f %format% -g>%outf%.txt
) else (
  echo "youtube-dl.exe "%inurl%" -f %format% -g>%outf%.txt"
  youtube-dl.exe "%inurl%" -f %format% -g>%outf%.txt
)
call :getsize %outf%.txt
if %size% LSS 20 (
  echo [WARNING]: Failed to get live stream url
  del /Q %outf%.txt
  goto end
)
set /p url=<%outf%.txt
ffmpeg -version|grep version
ffmpeg -hide_banner -headers %headers% -i "%url%" -c copy -bsf:a aac_adtstoasc -y "%outf%.flv"

:end
exit /b
::--------------------------------------------------------------------------------------------------
:getsize
set size=%~z1
exit /b
::--------------------------------------------------------------------------------------------------
