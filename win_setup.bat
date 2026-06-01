@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem setup_win.bat - Git Repository Manager for ICY (Windows 10+)
rem ============================================================================

set "INSTALL_DIR=%USERPROFILE%\icy-projects"
set "ICY_CONFIG=%USERPROFILE%\.icy"
set "REPO_FILE=%TEMP%\icy_repos_%RANDOM%.txt"
set "ICY_EXTENSIONS=%USERPROFILE%\.icy\extensions"

set VERBOSE=0
set FORCE_CLEAN=0
set UNINSTALL=0
set RESET=0
set RUN_ONLY=0
set RUN=0
set SUCCESS_COUNT=0
set FAIL_COUNT=0
set "FAILED_NAMES="

rem --- Parse arguments --------------------------------------------------------
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="-v"          ( set VERBOSE=1& shift& goto :parse_args )
if /i "%~1"=="--verbose"   ( set VERBOSE=1& shift& goto :parse_args )
if /i "%~1"=="-c"          ( set FORCE_CLEAN=1& shift& goto :parse_args )
if /i "%~1"=="--clean"     ( set FORCE_CLEAN=1& shift& goto :parse_args )
if /i "%~1"=="-u"          ( set UNINSTALL=1& shift& goto :parse_args )
if /i "%~1"=="--uninstall" ( set UNINSTALL=1& shift& goto :parse_args )
if /i "%~1"=="-r"          ( set RESET=1& shift& goto :parse_args )
if /i "%~1"=="--reset"     ( set RESET=1& shift& goto :parse_args )
if /i "%~1"=="--run-only"  ( set RUN_ONLY=1& set RUN=1& shift& goto :parse_args )
if /i "%~1"=="--run"       ( set RUN=1& shift& goto :parse_args )
if /i "%~1"=="-h"          goto :usage
if /i "%~1"=="--help"      goto :usage
echo ERROR: Unknown option: %~1
echo.
goto :usage

:args_done
if !FORCE_CLEAN! equ 1 if !UNINSTALL! equ 1 (
    echo ERROR: Cannot use both --clean and --uninstall.
    exit /b 1
)
if !UNINSTALL! equ 1 if !RUN! equ 1 (
    echo ERROR: Cannot use both --run and --uninstall.
    exit /b 1
)

echo ===========================================================
echo   ICY Repo Manager - Windows
echo ===========================================================
echo   Install dir : !INSTALL_DIR!
echo   ICY config  : !ICY_CONFIG!
echo.

rem --- Reset ------------------------------------------------------------------
if !RESET! equ 1 (
    echo ===========================================================
    echo   Reset ICY Configuration
    echo ===========================================================
    echo   WARNING: This will erase !ICY_CONFIG! including VTK.
    echo   This action cannot be undone.
    echo.
    set /p "CONFIRM=  Are you sure? (Y/N): "
    if /i "!CONFIRM!"=="Y" (
        if exist "!ICY_CONFIG!" (
            rmdir /s /q "!ICY_CONFIG!"
            echo   [OK] ICY configuration removed.
        ) else (
            echo   [INFO] Configuration directory not found.
        )
    ) else (
        echo   [INFO] Reset canceled.
    )
    echo.
)

rem --- Uninstall --------------------------------------------------------------
if !UNINSTALL! equ 1 (
    echo ===========================================================
    echo   Uninstall
    echo ===========================================================
    if exist "!INSTALL_DIR!" (
        rmdir /s /q "!INSTALL_DIR!"
        echo   [OK] Projects directory removed.
    ) else (
        echo   [INFO] Projects directory not found.
    )
    exit /b 0
)

rem --- Check requirements -----------------------------------------------------
call :check_requirements
if !ERRORLEVEL! neq 0 exit /b 1

rem --- Run only ---------------------------------------------------------------
if !RUN_ONLY! equ 1 goto :run_icy

rem --- Force clean ------------------------------------------------------------
if !FORCE_CLEAN! equ 1 (
    echo ===========================================================
    echo   Force Clean
    echo ===========================================================
    if exist "!INSTALL_DIR!" (
        rmdir /s /q "!INSTALL_DIR!"
        echo   [OK] Projects directory removed.
    )
    echo.
)

rem --- Create install directory -----------------------------------------------
if not exist "!INSTALL_DIR!" mkdir "!INSTALL_DIR!"

rem --- Write repo list to temp file -------------------------------------------
rem    Format per line:  URL;BRANCH;OPTIONS   (OPTIONS = NONE when empty)
> "!REPO_FILE!" (
    echo https://gitlab.pasteur.fr/bia/icy/pom-icy.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/maven/mojo-maven-plugin.git;main;NONE
    echo https://gitlab.pasteur.fr/bia/icy/maven/enforcer-maven-plugin.git;main;NONE
    echo https://gitlab.pasteur.fr/bia/icy/shared/task.git;main;NONE
    echo https://gitlab.pasteur.fr/bia/icy/shared/vtk.git;main;NONE
    echo https://gitlab.pasteur.fr/bia/icy/icy.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/kernel-extension.git;main;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/ezplug.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/protocols.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/scale-bar.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/ruler-helper.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/rotation-3d.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/elevation-map.git;main;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/orthoviewer.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/blockvars.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/channel-montage.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/montage-2d.git;main;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/spot-detection-utilities.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/quickhull.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/connected-components.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/roi-pool.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/roi-tagger.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/spot-detector.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/label-extractor.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/thresholder.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/filter-toolbox.git;icy-3.0.0;-Denforcer.skip=true
    echo https://gitlab.pasteur.fr/bia/icy/extensions/hk-means.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/track-manager.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/linear-programming.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/spot-tracking.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/track-processor-time-clip.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/track-motion-profiler.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/track-processor-roi-gate.git;main;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/track-processor-flow.git;main;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/mesh-3d-roi.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/fill-holes-in-roi.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/active-contours.git;icy-3.0.0;NONE
    echo https://gitlab.pasteur.fr/bia/icy/extensions/imglib2.git;icy-3.0.0;NONE
    echo https://github.com/bioimage-io/JDLL.git;main;NONE
)

rem --- Process every repo via a single FOR loop -------------------------------
for /f "usebackq tokens=1,2,* delims=;" %%A in ("!REPO_FILE!") do (
    call :process_repo "%%A" "%%B" "%%C"
)
del "!REPO_FILE!" 2>nul

goto :summary

rem ============================================================================
rem SUBROUTINES
rem ============================================================================

:usage
echo Usage: %~nx0 [OPTIONS]
echo.
echo   -v, --verbose     Show output from Git and Maven
echo   -c, --clean       Remove install directory and rebuild from scratch
echo   -u, --uninstall   Remove install directory and exit
echo   -r, --reset       Reset ICY configuration (%USERPROFILE%\.icy)
echo   --run             Run ICY after building
echo   --run-only        Run ICY without building
echo   -h, --help        Show this help message
exit /b 0

rem --- Check requirements -----------------------------------------------------
:check_requirements
echo ===========================================================
echo   Checking Requirements
echo ===========================================================
set "REQ_FAIL=0"

where git >nul 2>&1
if !ERRORLEVEL! equ 0 (
    for /f "tokens=3" %%v in ('git --version') do echo   [OK] Git %%v
) else (
    echo   [FAIL] Git not found
    set REQ_FAIL=1
)

where java >nul 2>&1
if !ERRORLEVEL! equ 0 (
    set "JAVA_VER="
    for /f "tokens=3" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do (
        if not defined JAVA_VER set "JAVA_VER=%%~v"
    )
    if defined JAVA_VER (
        for /f "tokens=1 delims=." %%m in ("!JAVA_VER!") do set "JAVA_MAJOR=%%m"
        if !JAVA_MAJOR! geq 17 (
            echo   [OK] Java !JAVA_VER!
        ) else (
            echo   [FAIL] Java 17+ required, found !JAVA_VER!
            set REQ_FAIL=1
        )
    ) else (
        echo   [FAIL] Could not determine Java version
        set REQ_FAIL=1
    )
) else (
    echo   [FAIL] Java not found
    set REQ_FAIL=1
)

where mvn >nul 2>&1
if !ERRORLEVEL! equ 0 (
    for /f "tokens=3" %%v in ('mvn --version 2^>^&1 ^| findstr /i "Apache Maven"') do echo   [OK] Maven %%v
) else (
    echo   [FAIL] Maven not found
    set REQ_FAIL=1
)

echo.
if !REQ_FAIL! equ 1 (
    echo   Resolve the issues above, then re-run the script.
    exit /b 1
)
exit /b 0

rem --- Process a single repository --------------------------------------------
:process_repo
set "P_URL=%~1"
set "P_BRANCH=%~2"
set "P_OPTIONS=%~3"
if /i "!P_OPTIONS!"=="NONE" set "P_OPTIONS="

rem -- Extract repo name (last segment of URL, minus .git) --
set "P_NAME="
for %%i in ("!P_URL:/=" "!") do set "P_NAME=%%~i"
set "P_NAME=!P_NAME:.git=!"
set "P_DIR=!INSTALL_DIR!\!P_NAME!"
set "P_SAVEDIR=!CD!"

echo ===========================================================
echo   [!P_NAME!]
echo ===========================================================
echo   URL     : !P_URL!
echo   Branch  : !P_BRANCH!
if defined P_OPTIONS echo   Options : !P_OPTIONS!
echo   Dir     : !P_DIR!

rem --- Clone or pull ----------------------------------------------------------
if exist "!P_DIR!\.git" (
    echo   Repository already exists, pulling updates...
    cd /d "!P_DIR!"
    if !VERBOSE! equ 1 (
        git fetch --all
        git pull
    ) else (
        git fetch --all >nul 2>&1
        git pull >nul 2>&1
    )
    echo   [OK] Updated
) else (
    echo   Cloning...
    if !VERBOSE! equ 1 (
        git clone "!P_URL!" "!P_DIR!"
    ) else (
        git clone "!P_URL!" "!P_DIR!" >nul 2>&1
    )
    if !ERRORLEVEL! neq 0 (
        echo   [FAIL] Clone failed
        set /a FAIL_COUNT+=1
        set "FAILED_NAMES=!FAILED_NAMES! !P_NAME!"
        cd /d "!P_SAVEDIR!"
        echo.
        exit /b 1
    )
    echo   [OK] Cloned
    cd /d "!P_DIR!"
)

rem --- Branch -----------------------------------------------------------------
if not "!P_BRANCH!"=="" (
    if !VERBOSE! equ 1 (
        git checkout "!P_BRANCH!" 2>nul || git checkout -b "!P_BRANCH!" "origin/!P_BRANCH!" 2>nul
        git pull
    ) else (
        git checkout "!P_BRANCH!" >nul 2>&1 || git checkout -b "!P_BRANCH!" "origin/!P_BRANCH!" >nul 2>&1
        git pull >nul 2>&1
    )
    echo   [OK] Branch: !P_BRANCH!
)

rem --- Maven build ------------------------------------------------------------
echo   Building...
if !VERBOSE! equ 1 (
    call mvn install -Dmaven.javadoc.skip=true -Dmaven.test.skip=true !P_OPTIONS!
) else (
    call mvn install -Dmaven.javadoc.skip=true -Dmaven.test.skip=true !P_OPTIONS! >nul 2>&1
)
if !ERRORLEVEL! equ 0 (
    echo   [OK] Build succeeded
    set /a SUCCESS_COUNT+=1
) else (
    echo   [FAIL] Build failed
    set /a FAIL_COUNT+=1
    set "FAILED_NAMES=!FAILED_NAMES! !P_NAME!"
)

cd /d "!P_SAVEDIR!"
echo.
exit /b 0

rem --- Summary ----------------------------------------------------------------
:summary
echo ===========================================================
echo   Summary
echo ===========================================================
echo   Succeeded : !SUCCESS_COUNT!
echo   Failed    : !FAIL_COUNT!

if !FAIL_COUNT! gtr 0 (
    echo.
    echo   Failed projects:!FAILED_NAMES!
    echo.
    echo   Some builds failed. Check the output above.
    if !RUN! equ 0 exit /b 1
)

if !FAIL_COUNT! equ 0 (
    echo.
    echo   All projects built successfully!
)
echo.

:run_icy
if !RUN! equ 1 (
    echo ===========================================================
    echo   Running ICY
    echo ===========================================================
    if not exist "!ICY_EXTENSIONS!" mkdir "!ICY_EXTENSIONS!"
    start "ICY" java --enable-native-access=ALL-UNNAMED -jar "!INSTALL_DIR!\icy\build\icy\icy.jar"
    echo   [OK] ICY launched. Have a nice day!
)

exit /b 0