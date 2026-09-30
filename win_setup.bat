@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem setup_win.bat - Installer for ICY (Windows 10+) v1.0.0 alpha 8 (SNAPSHOT)
rem ============================================================================

set "INSTALL_DIR=%USERPROFILE%\icy-projects"
set "ICY_CONFIG=%USERPROFILE%\.icy"
set "REPO_FILE=%TEMP%\icy_repos_%RANDOM%.txt"
set "ARTIFACTS_FILE=%TEMP%\icy_artifacts_%RANDOM%.txt"
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
echo   ICY Repo Manager - Windows v1.0.0 alpha 8 (SNAPSHOT)
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

rem --- Write artifact list to temp file -------------------------------------------
rem    Format per line:  GROUPID;ARTIFACTID;VERSION;PACKAGING;CLASSIFIER;REPOSITORY   (CLASSIFIER = NONE when empty)
> "!ARTIFACTS_FILE!" (
    echo fr.icy;pom-icy;3.0.0-a.8-SNAPSHOT;pom;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.maven;mojo-maven-plugin;1.0.0-a.8-SNAPSHOT;maven-plugin;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.maven;enforcer-maven-plugin;1.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.shared;logging;1.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.shared;task;1.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.shared;vtk;1.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.shared;vtk;1.0.0-a.8-SNAPSHOT;jar;natives-linux-amd64;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.shared;vtk;1.0.0-a.8-SNAPSHOT;jar;natives-windows-amd64;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.shared;vtk;1.0.0-a.8-SNAPSHOT;jar;natives-macos-arm64;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.shared;vtk;1.0.0-a.8-SNAPSHOT;jar;natives-macos-amd64;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy;icy;3.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;kernel;1.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;ezplug;4.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;protocols;4.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;scale-bar;4.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;ruler-helper;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;rotation-3d;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;elevation-map;3.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;orthoviewer;3.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;blockvars;1.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;channel-montage;3.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;montage-2d;1.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;spot-detection-utilities;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;quickhull;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;connected-components;5.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;roi-pool;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;roi-tagger;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;spot-detector;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;label-extractor;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;thresholder;4.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;track-manager;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;linear-programming;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;spot-tracking;4.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;track-processor-time-clip;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;track-motion-profiler;5.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;track-processor-roi-gate;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;track-processor-color;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;track-processor-flow;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;mesh-3d-roi;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
    echo fr.icy.extension;fill-holes-in-roi;2.0.0-a.8-SNAPSHOT;jar;NONE;https://central.sonatype.com/repository/maven-snapshots/
)

rem --- Process every artifact via a single FOR loop -------------------------------
for /f "usebackq tokens=1,2,3,4,5,6 delims=;" %%A in ("!ARTIFACTS_FILE!") do (
    call :process_artifact "%%A" "%%B" "%%C" "%%D" "%%E" "%%F"
)
del "!ARTIFACTS_FILE!" 2>nul

rem --- Write repo list to temp file -------------------------------------------
rem    Format per line:  URL;BRANCH;OPTIONS   (OPTIONS = NONE when empty)
> "!REPO_FILE!" (
    echo https://gitlab.pasteur.fr/bia/icy/icy.git;dev-3.0.0-a.8;NONE
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

rem --- Process a single artifact ----------------------------------------------
:process_artifact
set "A_GROUPID=%~1"
set "A_ARTIFACTID=%~2"
set "A_VERSION=%~3"
set "A_PACKAGING=%~4"
set "A_CLASSIFIER=%~5"
set "A_REPOSITORY=%~6"
if /i "!A_CLASSIFIER!"=="NONE" set "A_CLASSIFIER="

echo ===========================================================
echo   [!A_ARTIFACTID!]
echo ===========================================================
echo   GroupId      : !A_GROUPID!
echo   ArtifactId   : !A_ARTIFACTID!
echo   Version      : !A_VERSION!
echo   Packaging    : !A_PACKAGING!
echo   Classifier   : !A_CLASSIFIER!
echo   Repository   : !A_REPOSITORY!

if !VERBOSE! equ 1 (
    if /i "!A_CLASSIFIER!"=="" (
        mvn dependency:get -DgroupId="!A_GROUPID!" -DartifactId="!A_ARTIFACTID!" -Dversion="!A_VERSION!" -Dpackaging="!A_PACKAGING!" -DremoteRepositories="!A_REPOSITORY!"
    ) else (
        mvn dependency:get -DgroupId="!A_GROUPID!" -DartifactId="!A_ARTIFACTID!" -Dversion="!A_VERSION!" -Dpackaging="!A_PACKAGING!" -Dclassifier="!A_CLASSIFIER!" -DremoteRepositories="!A_REPOSITORY!"
    )
) else (
    if /i "!A_CLASSIFIER!"=="" (
        mvn dependency:get -DgroupId="!A_GROUPID!" -DartifactId="!A_ARTIFACTID!" -Dversion="!A_VERSION!" -Dpackaging="!A_PACKAGING!" -DremoteRepositories="!A_REPOSITORY!" >nul 2>&1
    ) else (
        mvn dependency:get -DgroupId="!A_GROUPID!" -DartifactId="!A_ARTIFACTID!" -Dversion="!A_VERSION!" -Dpackaging="!A_PACKAGING!" -Dclassifier="!A_CLASSIFIER!" -DremoteRepositories="!A_REPOSITORY!" >nul 2>&1
    )
)
echo.
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
    call mvn install -Dmaven.javadoc.skip=true -Dmaven.test.skip=true -Denforcer.skip=true !P_OPTIONS!
) else (
    call mvn install -Dmaven.javadoc.skip=true -Dmaven.test.skip=true -Denforcer.skip=true !P_OPTIONS! >nul 2>&1
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
    if not exist "!ICY_CONFIG!" mkdir "!ICY_CONFIG!"
    xcopy ".\extensions.yml" "!ICY_CONFIG!\extensions.yml"
    start "ICY" java -Xms6g -Xmx12g --enable-native-access=ALL-UNNAMED -jar "!INSTALL_DIR!\icy\build\icy\icy.jar"
    echo   [OK] ICY launched. Have a nice day!
)

exit /b 0