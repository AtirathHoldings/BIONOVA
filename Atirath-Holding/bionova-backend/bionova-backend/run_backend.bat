@echo off
setlocal enabledelayedexpansion
for /f "usebackq tokens=1,2 delims==" %%i in (.env) do (
    set "%%i=%%j"
)
call .\mvnw.cmd spring-boot:run
