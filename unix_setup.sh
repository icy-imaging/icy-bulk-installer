#!/bin/bash
# =============================================================================
# unix_setup.sh — Installer for ICY - Unix (MacOS & Linux) 1.0.0 alpha 8 (SNAPSHOT)
# =============================================================================
# Usage: ./unix_setup.sh [OPTIONS]
#   -v, --verbose       Show logs from Git and Maven
#   -c, --clean         Remove the icy-projects directory and start from scratch
#   -r, --reset         Reset Icy's configuration directory (located at: $HOME/.icy)
#   --run               Run Icy at the end
#   --run-only          Run Icy without compiling it, replace the --run option
#   -h, --help          Show this help message
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
INSTALL_DIR="$HOME/icy-projects"
ICY_DIR="$HOME/.icy/"

# Format: "REPO_URL|BRANCH|MAVEN_OPTIONS"
#   BRANCH        – optional; leave empty to stay on the repo's default branch
#   MAVEN_OPTIONS – optional
REPOS=(
    "https://gitlab.pasteur.fr/bia/icy/icy.git|dev|"
)

# -- Colours ------------------------------------------------------------------
# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

BOLD='\033[1m'
UNDER='\033[4m'
BLINK='\033[5m'
INVERT='\033[7m'

NC='\033[0m'

# -- Arguments ----------------------------------------------------------------
VERBOSE=false
FORCE_CLEAN=false
RESET=false
RUN_ONLY=false
RUN=false

# -- Logging helpers ----------------------------------------------------------
print_banner() {
    printf "\r${CYAN}${BOLD}══════════════════════════════════════════════════════════${NC}\n"
    printf "\r${CYAN}${BOLD}  $*${NC}\n"
    printf "\r${CYAN}${BOLD}══════════════════════════════════════════════════════════${NC}\n"
}

ok()   { printf "\r${GREEN}  [✓] $*${NC}\n"; }
err()  { printf "\r${RED}${BLINK}  [✗]${NC}${RED} $*${NC}\n"; }
warn() { printf "\r${YELLOW}  [!] $*${NC}\n"; }
info() { printf "\r${NC}  [·] $*${NC}\n"; }

# -- Wheel --------------------------------------------------------------------
wheel() {
    str_len=$(( ${#2} + 6 ))
    spin='⠋⠙⠚⠞⠖⠦⠴⠲⠳⠓'
    spin_len=${#spin}
    i=0
    while kill -0 $1 2>/dev/null
    do
      i=$(( (i+1) %$spin_len ))
      printf "\r${PURPLE}  [${spin:$i:1}] $2${NC}"
      sleep .1
    done
    printf "\r%${str_len}s"
}

# -- Usage --------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: ./$(basename "$0") [OPTIONS]

Options:
  -v, --verbose     Show logs from Git and Maven
  -c, --clean       Remove the icy-projects directory and start from scratch
  -r, --reset       Reset ICY's configuration directory (located at: $HOME/.icy)
  --run             Run ICY at the end (cannot be used with --uninstall)
  --run-only        Run Icy without compiling it, replace the --run option
  -h, --help        Show this help message

EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)   VERBOSE=true ;;
            -c|--clean)     FORCE_CLEAN=true ;;
            -r|--reset)     RESET=true ;;
            --run-only)     RUN_ONLY=true; RUN=true ;;
            --run)          RUN=true ;;
            -h|--help)      usage ;;
            *) printf "${RED}Unknown option: $1${NC}\r\n"; echo; usage ;;
        esac
        shift
    done

    if $FORCE_CLEAN && $RUN_ONLY; then
        printf "${RED}Cannot use both --run-only and -c/--clean${NC}\r\n"
        echo
        usage
    fi
}

# -- Requirements check -------------------------------------------------------
check_requirements() {
    print_banner "Checking Requirements"
    local failed=false

    # git
    if command -v git &>/dev/null; then
        ok "Git  $(git --version | awk '{print $3}')"
    else
        err "Git not found"
        failed=true
    fi

    # java >= 17
    if command -v java &>/dev/null; then
        local full major
        full=$(java -version 2>&1 | awk -F '"' 'NR==1{print $2}')
        major=$(echo "$full" | awk -F'.' '{print ($1 == "1") ? $2 : $1}')
        if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 17 )); then
            ok "Java $full"
        else
            err "Java 17+ required — found \"$full\""
            failed=true
        fi
    else
        err "Java not found"
        failed=true
    fi

    # maven
    if command -v mvn &>/dev/null; then
        ok "Maven  $(mvn --version 2>&1 | head -1 | awk '{print $3}')"
    else
        err "Maven not found"
        failed=true
    fi

    if $failed; then
        echo
        err "Resolve the issues above, then re-run the script."
        exit 1
    fi

}

# -- Per-repo processing ------------------------------------------------------
process_repo() {
    local url="$1" branch="$2" options="${3}"
    local name dir
    name=$(basename "$url" .git)
    dir="$INSTALL_DIR/$name"
    updated=false

    print_banner "[$name]"
    info "URL       : $url"
    info "Branch    : ${branch:-<default>}"
    info "Options   : $options"
    info "Directory : $dir"

    # -- Clone or update ------------------------------------------------------
    if [[ -d "$dir/.git" ]]; then
        ok "Repository already exists"
        pushd "$dir" > /dev/null || { err "Cannot enter $dir"; return 1; }
        if $VERBOSE; then
            git fetch --all && git pull
        else
            git fetch --all >> /dev/null 2>&1 || { warn "Cannot fetch update"; return 1; } &
            pid=$!
            wheel $pid "Searching for updates"
            git pull >> /dev/null 2>&1 || { warn "Cannot pull from remote"; return 1; } &
            pid=$!
            wheel "Downloading update…"
            ok "Updated successfully"
        fi
    else
        if $VERBOSE; then
            if ! git clone "$url" "$dir"; then
                err "Clone failed for $url"
                return 1
            fi
        else
            git clone "$url" "$dir" >> /dev/null 2>&1 || {
                err "Clone failed for $url"
                return 1
            } &
            pid=$!
            wheel $pid "Cloning repository…"
        fi
        ok "Cloned successfully"
        pushd "$dir" > /dev/null || { err "Cannot enter $dir"; return 1; }
        git fetch --all >> /dev/null 2>&1 || { err "Cannot fetch repository"; return 1; } &
        pid=$!
        wheel $pid "Fetching repository…"
        ok "Fetched successfully"
    fi

    # -- Branch checkout ------------------------------------------------------
    if [[ -n "$branch" ]]; then
        if git show-ref --verify -q "refs/heads/$branch"; then
            if $VERBOSE; then
                git checkout "$branch" && git pull
            else
                git checkout "$branch" >> /dev/null 2>&1 && git pull >> /dev/null 2>&1 &
                pid=$!
                wheel $pid "Checking out local branch: $branch"
            fi
            ok "Branch $branch successfully checked out"
        elif git show-ref --verify -q "refs/remotes/origin/$branch"; then
            if $VERBOSE; then
                git checkout "$branch" && git pull
            else
                git checkout "$branch" >> /dev/null 2>&1 && git pull >> /dev/null 2>&1 &
                pid=$!
                wheel $pid "Tracking remote branch: $branch"
            fi
            ok "Branch $branch successfully checked out"
        else
            warn "Branch '$branch' not found — staying on: $(git rev-parse --abbrev-ref HEAD)"
        fi
    else
        warn "No branch specified — current: $(git rev-parse --abbrev-ref HEAD)"
    fi

    # -- Maven build ----------------------------------------------------------
    local rc=0
    if $VERBOSE; then
        mvn -Dmaven.javadoc.skip=true -Dmaven.test.skip=true -Denforcer.skip=true $options & rc=$?
    else
        mvn -Dmaven.javadoc.skip=true -Dmaven.test.skip=true -Denforcer.skip=true $options >> /dev/null &
        pid=$!
        wheel $pid "Building project…"
        wait $pid
        rc=$?
    fi

    if (( rc == 0 )); then
        ok "Build succeeded — $name"
    else
        err "Build failed — $name (exit code: $rc)"
    fi

    popd > /dev/null
    return $rc
}

# -- Main ---------------------------------------------------------------------
parse_args "$@"

print_banner "Icy Installer — Unix (MacOS & Linux) v1.0.0 alpha 8 (SNAPSHOT)"
info "Install dir : $INSTALL_DIR"
info "Icy config  : $ICY_DIR"
if $RESET; then warn "Reset Icy   : true"; fi
if $FORCE_CLEAN; then warn "Force clean : $FORCE_CLEAN"; fi

if $RESET; then
    print_banner "Reset Icy (removing $ICY_DIR)"
    printf "${RED}  Are you sure you want to reset your Icy configuration?${NC}\r\n"
    printf "${RED}  It will also erase VTK.${NC}\r\n"
    printf "${RED}${BOLD}  This action cannot be undone!${NC}\r\n"
    read -p "  (Y|N)? " confirm
    str=$(echo "$confirm"| tr '[:lower:]' '[:upper:]')
    if [[ $str = 'Y' ]]; then
        rm -rf "$ICY_DIR" || { err "Failed to remove $ICY_DIR"; exit 1; } &
        pid=$1
        wheel $pid "Removing ICY directory…"
        ok "Icy directory removed successfully"
    else
        info "Reset canceled"
    fi
fi

check_requirements

if ! $RUN_ONLY; then

    if $FORCE_CLEAN; then
        print_banner "Force Clean"
        rm -rf "$INSTALL_DIR" || { err "Failed to remove $INSTALL_DIR"; exit 1; } &
        pid=$!
        wheel $pid "Removing projects directory…"
        ok "Projects directory removed successfully"
    fi

    mkdir -p "$INSTALL_DIR" || { err "Cannot create directory: $INSTALL_DIR"; exit 1; }

    success_list=()
    failed_list=()

    for entry in "${REPOS[@]}"; do
        IFS='|' read -r url branch options <<< "$entry"
        name=$(basename "$url" .git)
        if process_repo "$url" "$branch" "$options"; then
            success_list+=("git: $name ($branch)")
        else
            failed_list+=("git: $name ($branch)")
        fi
    done

    # -- Summary ------------------------------------------------------------------
    print_banner "Summary"

    printf "${GREEN}${BOLD}  Passed (${#success_list[@]})${NC}\r\n"
    for n in "${success_list[@]}"; do ok $n; done

    if (( ${#failed_list[@]} > 0 )); then
        printf "\n${RED}${BOLD}  Failed (${#failed_list[@]})${NC}\r\n"
        for n in "${failed_list[@]}"; do err $n; done
        echo
        err "Some builds failed — check the output above."
        exit 1
    fi

    echo
    ok "All projects were built successfully!"

fi

if $RUN; then
    mkdir -p "$ICY_DIR" || { err "Cannot create directory: $ICY_DIR"; exit 1; }
    cp "./extensions.yaml" "$ICY_DIR/extensions.yaml"
    echo
    java -Xms6g -Xmx12g --enable-native-access=ALL-UNNAMED -jar "$INSTALL_DIR/icy/target/icy/icy.jar" > $INSTALL_DIR/icy.log 2>&1 || {
        err "Something went wrong while ICY was running."
        exit 1
    } &
    pid=$!
    wheel $pid "ICY is running. Please wait while Icy downloads and loads extensions."
    ok "Have a nice day!"
fi