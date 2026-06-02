@echo off
rem ============================================================================
rem  Full sync cycle: pull latest from GitHub -> mirror to the corporate GitLab.
rem
rem    GitHub (origin/main)  --fetch + fast-forward-->  local main  --push-->  corp/master
rem
rem  GitHub stays the source of truth; corp is a downstream mirror.
rem  Branch-name mismatch is handled (local `main` -> corp `master`).
rem
rem  One-time setup (on the work machine that can reach corp git):
rem      git remote add corp <corp-url>
rem    or pass the URL once to this script:
rem      push-to-corp.bat https://git.tkbbank.ru/tkbpay/microservices/gateway/payconfig_server.git
rem
rem  Then just run:  push-to-corp.bat
rem ============================================================================
setlocal
cd /d "%~dp0"

rem --- Optional first arg: (re)configure the `corp` remote URL. ---
if not "%~1"=="" (
    git remote get-url corp >nul 2>&1
    if errorlevel 1 (
        git remote add corp "%~1"
    ) else (
        git remote set-url corp "%~1"
    )
)

rem --- Resolve the GitHub remote: pick the one whose URL contains github.com (else `origin`). ---
set "GH=origin"
for /f "delims=" %%r in ('git remote') do (
    git remote get-url %%r 2>nul | findstr /i "github.com" >nul && set "GH=%%r"
)

git remote get-url corp >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Remote "corp" is not configured.
    echo   Run once:  git remote add corp ^<corp-url^>
    echo   or:        %~nx0 ^<corp-url^>
    exit /b 1
)

echo === 1/4  Fetching from GitHub (%GH%) ===
git fetch %GH% --prune
if errorlevel 1 (
    echo [ERROR] fetch from GitHub failed.
    exit /b 1
)

echo === 2/4  Switching to local main ===
git checkout main
if errorlevel 1 (
    echo [ERROR] cannot switch to "main" (uncommitted changes? wrong repo?).
    exit /b 1
)

echo === 3/4  Fast-forwarding main to %GH%/main ===
git merge --ff-only %GH%/main
if errorlevel 1 (
    echo [ERROR] local main has diverged from GitHub - reconcile manually
    echo         ^(push local commits to GitHub first, or rebase^), then re-run.
    exit /b 1
)

echo === 4/4  Pushing local main -^> corp/master ===
git push corp main:master
if errorlevel 1 (
    echo [ERROR] push to corp failed.
    exit /b 1
)
git push corp --tags

echo.
echo Done: GitHub %GH%/main mirrored to corp/master.
endlocal
