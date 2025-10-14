@echo off
REM Test runner script for Windows
REM Requires Lua 5.1 and Busted to be installed

echo ========================================
echo IWin External Test Runner
echo ========================================
echo.

REM Check if Lua is installed
where lua >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Lua not found in PATH
    echo Please install Lua 5.1: https://sourceforge.net/projects/luabinaries/
    exit /b 1
)

REM Check if Busted is installed
where busted >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Busted not found in PATH
    echo Please install: luarocks install busted
    exit /b 1
)

echo Running external unit tests...
echo.

busted --verbose tests/

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo All tests passed!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Tests failed!
    echo ========================================
    exit /b 1
)
