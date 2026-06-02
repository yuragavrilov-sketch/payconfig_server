@echo off
rem ============================================================================
rem  Push the local `main` branch to the corporate git as `master`.
rem  GitHub (origin/main) stays the primary source of truth; this only mirrors
rem  the current state into corp when you need it.
rem
rem  One-time setup (run on the work machine that can reach corp git):
rem      git remote add corp <corp-url>
rem    or pass the URL once to this script:
rem      push-to-corp.bat https://gitlab.corp.example/pay/payconfig_server.git
rem
rem  Then just run:  push-to-corp.bat
rem ============================================================================
setlocal
cd /d "%~dp0"

rem Optional first arg: (re)configure the `corp` remote URL.
if not "%~1"=="" (
    git remote get-url corp >nul 2>&1
    if errorlevel 1 (
        git remote add corp "%~1"
    ) else (
        git remote set-url corp "%~1"
    )
)

git remote get-url corp >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Remote "corp" is not configured.
    echo   Run once:  git remote add corp ^<corp-url^>
    echo   or:        %~nx0 ^<corp-url^>
    exit /b 1
)

echo Pushing local main -^> corp/master ...
git push corp main:master
if errorlevel 1 (
    echo [ERROR] push failed.
    exit /b 1
)

git push corp --tags
echo Done.
endlocal
