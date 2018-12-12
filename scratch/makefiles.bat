REM this needs to be executed from command-line and not from batch
for /f "delims=" %F in (filenames.txt) do copy nul "%F"