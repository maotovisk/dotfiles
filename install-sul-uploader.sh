#!/usr/bin/env bash
#
# Standalone installer for sul-uploader (screenshot uploader for s-ul.eu).
#
# This file is fully self-contained: the sul-uploader script is embedded
# below, so this installer can be hosted anywhere (gist, pastebin, any repo)
# with no dependency on the dotfiles repo it came from.
#
# Usage:
#   curl -fsSL <url-to-this-file> | bash
#   bash -s -- <opts>                (when piping, append options this way)
#
# Options:
#   -f, --force        Overwrite existing config.ini (otherwise it is kept/merged)
#   -y, --yes          Assume "yes" when asked to install missing dependencies
#       --no-deps      Skip dependency installation entirely
#       --backend <id> Skip the backend menu (hyprland-satty|grim-slurp|spectacle|flameshot|gnome)
#       --keybind <kb> Set the KDE keybind non-interactively (implies setup, e.g. "Meta+Shift+S")
#       --no-keybind   Skip the KDE keybind setup entirely
#   -h, --help         Show this help
#
# The installer:
#   1. Detects usable screenshot backends, suggests one based on your desktop,
#      and lets you pick which one sul-uploader should use
#   2. Installs runtime dependencies via the system package manager (with confirmation)
#   3. Installs the embedded sul-uploader to ~/.local/bin
#   4. Creates ~/.config/sul-uploader/config.ini (API key + backend choice)
#   5. On KDE Plasma: optionally binds a global keybind (default Meta+Shift+S)
#
# Get your API key from: https://s-ul.eu/account/preferences

set -u

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_RESET='\033[0m'

print_info()  { printf "${COLOR_GREEN}[INFO]${COLOR_RESET} %s\n" "$1"; }
print_warn()  { printf "${COLOR_YELLOW}[WARN]${COLOR_RESET} %s\n" "$1"; }
print_error() { printf "${COLOR_RED}[ERROR]${COLOR_RESET} %s\n" "$1"; }

INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/sul-uploader"
CONFIG_DIR="$HOME/.config/sul-uploader"
CONFIG_FILE="$CONFIG_DIR/config.ini"

BACKENDS="hyprland-satty grim-slurp spectacle flameshot gnome"
DEFAULT_KEYBIND="Meta+Shift+S"

FORCE=false
ASSUME_YES=false
SKIP_DEPS=false
BACKEND_FLAG=""
KEYBIND_FLAG=""
NO_KEYBIND=false

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)   FORCE=true; shift ;;
        -y|--yes)     ASSUME_YES=true; shift ;;
        --no-deps)    SKIP_DEPS=true; shift ;;
        --backend)
            [ $# -ge 2 ] || { print_error "--backend needs an id. Valid: $BACKENDS"; exit 1; }
            BACKEND_FLAG="$2"; shift 2 ;;
        --backend=*)  BACKEND_FLAG="${1#--backend=}"; shift ;;
        --keybind)
            [ $# -ge 2 ] || { print_error "--keybind needs a key (e.g. Meta+Shift+S)"; exit 1; }
            KEYBIND_FLAG="$2"; shift 2 ;;
        --keybind=*)  KEYBIND_FLAG="${1#--keybind=}"; shift ;;
        --no-keybind) NO_KEYBIND=true; shift ;;
        -h|--help)    usage; exit 0 ;;
        *)            print_error "Unknown option: $1 (see --help)"; exit 1 ;;
    esac
done

command_exists() { command -v "$1" >/dev/null 2>&1; }

# NOTE: we probe /dev/tty with a real write inside a redirect group, not
# [ -r/-w ], because the device node can exist yet be unusable (ENXIO)
# with no controlling terminal (e.g. `curl ... | bash` from a GUI launcher).
# The group form `{ ...; } 2>/dev/null` is required: on a bare
# `: > /dev/tty 2>/dev/null` the failed open is reported by the shell
# before 2>/dev/null takes effect.
tty_usable() { { : > /dev/tty; } 2>/dev/null; }

interactive() {
    # True when we can actually converse with the user.
    tty_usable || [ -t 0 ]
}

# Print a prompt to wherever the user can see it (tty preferred, else stderr).
prompt_to_user() {
    if tty_usable; then
        printf '%s' "$1" > /dev/tty
    else
        printf '%s' "$1" >&2
    fi
}

# Read one line from the user (tty preferred, else stdin).
read_from_user() {
    if tty_usable; then
        IFS= read -r "$1" < /dev/tty || return 1
    else
        IFS= read -r "$1" || return 1
    fi
}

# Usage: ask "Question? (Y/n)" -> 0 for yes, 1 for no.
# Non-interactive defaults to "no" and never touches stdin (under
# `curl | bash`, stdin is the script itself). Automation: pass --yes.
ask() {
    local prompt="$1" answer=""
    if ! interactive; then
        return 1
    fi
    prompt_to_user "$prompt "
    read_from_user answer || answer=""
    case "$answer" in
        ""|[Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# Same as ask(), but empty input means "no". Use for destructive questions.
ask_default_no() {
    local prompt="$1" answer=""
    if ! interactive; then
        return 1
    fi
    prompt_to_user "$prompt "
    read_from_user answer || answer=""
    case "$answer" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}
# Usage: val="$(prompt_line "Label" "default")" — value goes to stdout,
# prompt goes to tty/stderr. Returns 1 when non-interactive (prints default).
prompt_line() {
    local label="$1" def="${2:-}" answer=""
    if ! interactive; then
        printf '%s' "$def"
        return 1
    fi
    if [ -n "$def" ]; then
        prompt_to_user "$label [$def]: "
    else
        prompt_to_user "$label: "
    fi
    read_from_user answer || answer=""
    # Trim surrounding whitespace (also strips trailing \r).
    answer="$(printf '%s' "$answer" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [ -z "$answer" ]; then
        answer="$def"
    fi
    printf '%s' "$answer"
    return 0
}

prompt_api_key() {
    local key=""
    prompt_to_user "Get your key from https://s-ul.eu/account/preferences
"
    if ! interactive; then
        return 1
    fi
    prompt_to_user "Enter the key for sul-uploader: "
    read_from_user key || key=""
    # API keys contain no whitespace; strip it (also removes trailing \r).
    printf '%s' "$key" | tr -d '[:space:]'
}

# ---------------------------------------------------------------- backend meta

backend_label() {
    case "$1" in
        hyprland-satty) echo "Hyprland focused monitor + satty annotation" ;;
        grim-slurp)     echo "Wayland region select (grim + slurp)" ;;
        spectacle)      echo "KDE Spectacle region capture" ;;
        flameshot)      echo "Flameshot GUI" ;;
        gnome)          echo "GNOME Screenshot area capture" ;;
        *)              echo "$1" ;;
    esac
}

# Required commands per backend.
backend_commands() {
    case "$1" in
        hyprland-satty) echo "hyprctl grim satty" ;;
        grim-slurp)     echo "grim slurp" ;;
        spectacle)      echo "spectacle" ;;
        flameshot)      echo "flameshot" ;;
        gnome)          echo "gnome-screenshot" ;;
        *)              echo "" ;;
    esac
}

backend_valid() {
    case " $BACKENDS " in
        *" $1 "*) return 0 ;;
        *) return 1 ;;
    esac
}

backend_available() {
    local cmd
    for cmd in $(backend_commands "$1"); do
        command_exists "$cmd" || return 1
    done
    return 0
}

backend_missing_cmds() {
    local cmd out=""
    for cmd in $(backend_commands "$1"); do
        command_exists "$cmd" || out="$out $cmd"
    done
    printf '%s' "$out"
}

# Extra packages (on top of common) needed per backend, per package manager.
backend_packages() {
    local backend="$1" pm="$2"
    case "$backend" in
        hyprland-satty)
            case "$pm" in apt-get) echo "grim" ;; *) echo "grim satty" ;; esac ;;
        grim-slurp)
            case "$pm" in apt-get) echo "grim slurp" ;; *) echo "grim slurp satty" ;; esac ;;
        spectacle)  echo "spectacle" ;;
        flameshot)  echo "flameshot" ;;
        gnome)      echo "gnome-screenshot" ;;
    esac
}

# ------------------------------------------------------------- environment

detect_de() {
    local d="${XDG_CURRENT_DESKTOP:-}"
    local dl
    dl="$(printf '%s' "$d" | tr '[:upper:]' '[:lower:]')"
    case "$dl" in
        *kde*|*plasma*) echo "kde"; return 0 ;;
        *gnome*)        echo "gnome"; return 0 ;;
        *hyprland*)     echo "hyprland"; return 0 ;;
        *sway*)         echo "sway"; return 0 ;;
    esac
    if [ -n "${KDE_SESSION_VERSION:-}" ]; then echo "kde"; return 0; fi
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then echo "hyprland"; return 0; fi
    if [ -n "${SWAYSOCK:-}" ]; then echo "sway"; return 0; fi
    if command_exists plasmashell; then echo "kde"; return 0; fi
    if command_exists pgrep && pgrep -x plasmashell >/dev/null 2>&1; then echo "kde"; return 0; fi
    case "${XDG_SESSION_TYPE:-}" in
        wayland) echo "wayland" ;;
        x11)     echo "x11" ;;
        *)       echo "unknown" ;;
    esac
    return 0
}

plasma_version() {
    # Prints 5, 6, or unknown.
    if [ -n "${KDE_SESSION_VERSION:-}" ]; then
        printf '%s' "$KDE_SESSION_VERSION"
        return 0
    fi
    local v=""
    if command_exists plasmashell; then
        v="$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+' | head -n1)"
    fi
    if [ -n "$v" ]; then
        printf '%s' "$v"
    else
        printf 'unknown'
    fi
}

detect_package_manager() {
    if command_exists pacman; then
        echo "pacman"
    elif command_exists apt-get; then
        echo "apt-get"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists zypper; then
        echo "zypper"
    elif command_exists apk; then
        echo "apk"
    else
        echo "none"
    fi
}

# ------------------------------------------------------------- backend choice

preselect_backend() {
    # $1 = desktop. Prints the suggested backend id.
    case "$1" in
        kde)      echo "spectacle" ;;
        hyprland) echo "hyprland-satty" ;;
        gnome)    echo "gnome" ;;
        sway|wayland) echo "grim-slurp" ;;
        x11)      echo "flameshot" ;;
        *)        echo "grim-slurp" ;;
    esac
}

choose_backend() {
    # Prints the chosen backend id. Uses --backend flag, else an interactive
    # menu with a DE-based suggestion, else the suggestion/first-available.
    local de="$1" suggestion="$2" id choice n=0
    if [ -n "$BACKEND_FLAG" ]; then
        if ! backend_valid "$BACKEND_FLAG"; then
            # NOTE: stderr — stdout is captured by the caller ($(...)).
            print_error "Unknown backend '$BACKEND_FLAG'. Valid: $BACKENDS" >&2
            return 1
        fi
        printf '%s' "$BACKEND_FLAG"
        return 0
    fi

    if interactive; then
        prompt_to_user "Detected desktop: $de — suggested backend: $suggestion ($(backend_label "$suggestion"))
Available screenshot backends:
"
        for id in $BACKENDS; do
            n=$((n + 1))
            if backend_available "$id"; then
                if [ "$id" = "$suggestion" ]; then
                    prompt_to_user "  $n) $id — $(backend_label "$id") [installed] (suggested)
"
                else
                    prompt_to_user "  $n) $id — $(backend_label "$id") [installed]
"
                fi
            else
                if [ "$id" = "$suggestion" ]; then
                    prompt_to_user "  $n) $id — $(backend_label "$id") [needs:$(backend_missing_cmds "$id") ] (suggested)
"
                else
                    prompt_to_user "  $n) $id — $(backend_label "$id") [needs:$(backend_missing_cmds "$id") ]
"
                fi
            fi
        done
        choice="$(prompt_line "Choose backend (1-$n, id, or Enter for suggestion)" "$suggestion")"
        case "$choice" in
            1|2|3|4|5)
                n=0
                for id in $BACKENDS; do
                    n=$((n + 1))
                    if [ "$n" = "$choice" ]; then
                        printf '%s' "$id"
                        return 0
                    fi
                done ;;
        esac
        if backend_valid "$choice"; then
            printf '%s' "$choice"
            return 0
        fi
        # NOTE: stderr — stdout is captured by the caller ($(...)).
        print_error "Invalid choice '$choice'. Valid: 1-5 or: $BACKENDS" >&2
        return 1
    fi

    # Non-interactive: suggestion if usable, else first installed backend,
    # else the suggestion anyway (deps step / runtime fallback will cope).
    if backend_available "$suggestion"; then
        printf '%s' "$suggestion"
        return 0
    fi
    for id in $BACKENDS; do
        if backend_available "$id"; then
            printf '%s' "$id"
            return 0
        fi
    done
    printf '%s' "$suggestion"
    return 0
}

# ------------------------------------------------------------- dependencies

install_dependencies() {
    local backend="$1"
    if [ "$SKIP_DEPS" = true ]; then
        print_warn "Skipping dependency installation (--no-deps)."
        return 0
    fi

    local pm
    pm="$(detect_package_manager)"

    # Common runtime needs: uploader core + notification + clipboard +
    # one dialog tool (zenity preferred, kdialog accepted).
    local need_dialog=true
    if command_exists zenity || command_exists kdialog; then
        need_dialog=false
    fi

    local missing=""
    local cmd
    for cmd in curl jq file notify-send $(backend_commands "$backend"); do
        command_exists "$cmd" || missing="$missing $cmd"
    done
    if ! command_exists wl-copy && ! command_exists xclip; then
        missing="$missing wl-copy/xclip"
    fi
    if [ "$need_dialog" = true ]; then
        missing="$missing zenity"
    fi

    if [ -z "$missing" ]; then
        print_info "All dependencies are already installed."
        return 0
    fi
    print_warn "Missing dependencies:$missing"

    if [ "$pm" = "none" ]; then
        print_error "No supported package manager found (pacman/apt-get/dnf/zypper/apk)."
        print_error "Please install manually:$missing"
        return 1
    fi

    local notify_pkg="libnotify"
    if [ "$pm" = "apt-get" ]; then
        notify_pkg="libnotify-bin"
    fi
    local packages="curl jq file $notify_pkg wl-clipboard xclip"
    if [ "$need_dialog" = true ]; then
        packages="$packages zenity"
    fi
    packages="$packages $(backend_packages "$backend" "$pm")"
    # NOTE: we never install Hyprland itself (provides hyprctl).

    if [ "$ASSUME_YES" = true ]; then
        print_info "Installing dependencies via $pm..."
    else
        print_info "The installer can run the system package manager to install them."
        if ! ask "Install missing dependencies with $pm? (Y/n)"; then
            print_warn "Skipping dependency installation. Install manually:$missing"
            return 0
        fi
    fi

    local sudo_cmd=""
    if [ "$(id -u)" -ne 0 ]; then
        if command_exists sudo; then
            sudo_cmd="sudo"
        else
            print_error "sudo not found and not running as root. Install manually:$missing"
            return 1
        fi
    fi

    case "$pm" in
        pacman)  $sudo_cmd pacman -S --noconfirm --needed $packages ;;
        apt-get) $sudo_cmd apt-get update && $sudo_cmd apt-get install -y $packages ;;
        dnf)     $sudo_cmd dnf install -y $packages ;;
        zypper)  $sudo_cmd zypper install -y $packages ;;
        apk)     $sudo_cmd apk add $packages ;;
    esac

    # Re-check after install; report anything still missing with hints.
    local still_missing=""
    for cmd in curl jq file notify-send $(backend_commands "$backend"); do
        command_exists "$cmd" || still_missing="$still_missing $cmd"
    done
    if ! command_exists wl-copy && ! command_exists xclip; then
        still_missing="$still_missing wl-copy/xclip"
    fi
    if ! command_exists zenity && ! command_exists kdialog; then
        still_missing="$still_missing zenity"
    fi
    if [ -n "$still_missing" ]; then
        print_warn "Still missing after install:$still_missing"
        if printf '%s' "$still_missing" | grep -q "satty"; then
            print_warn "satty is not packaged on all distros. Alternatives:"
            print_warn "  - Arch/Fedora/SUSE: reinstall via your package manager"
            print_warn "  - Debian/Ubuntu: cargo install satty  (or grab a .deb from github.com/gabm/satty/releases)"
        fi
        if printf '%s' "$still_missing" | grep -q "hyprctl"; then
            print_warn "hyprctl comes with Hyprland itself, which this installer never installs."
        fi
        print_warn "sul-uploader was still installed, but '$backend' may not work until these are present."
        return 1
    fi
    print_info "Dependencies installed successfully."
}

# ------------------------------------------------------------- install files

write_uploader() {
    print_info "Installing sul-uploader to $INSTALL_PATH ..."
    mkdir -p "$INSTALL_DIR"
    cat > "$INSTALL_PATH" <<'SUL_UPLOADER_EOF'
#!/usr/bin/env bash
#
# sul-uploader — take a screenshot and upload it to s-ul.eu
#
# The screenshot backend is read from ~/.config/sul-uploader/config.ini
# (backend=<id>). If unset or unavailable, the first installed backend
# from the list below is used automatically.
#
# Supported backends (--list-backends):
#   hyprland-satty   Hyprland focused monitor (grim) + satty annotation
#   grim-slurp       Wayland region select (grim + slurp, satty if present)
#   spectacle        KDE Spectacle region capture
#   flameshot        Flameshot GUI (annotate, saves on accept)
#   gnome            GNOME Screenshot area capture
#
# Usage:
#   sul-uploader [--backend <id>] [--list-backends] [--help]
#
# Config (~/.config/sul-uploader/config.ini):
#   [DEFAULT]
#   key=YOUR_S_UL_API_KEY
#   backend=hyprland-satty
#
# Dependencies (common): curl, jq, file, notify-send, zenity (or kdialog),
#   wl-copy (or xclip) — plus whichever backend tools you use.

set -u

APP_NAME="Screenshot Uploader"
CONFIG_FILE="$HOME/.config/sul-uploader/config.ini"
STORE_DIR="$HOME/s-ul"

BACKENDS="hyprland-satty grim-slurp spectacle flameshot gnome"

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

backend_label() {
    case "$1" in
        hyprland-satty) echo "Hyprland (grim + satty)" ;;
        grim-slurp)     echo "Wayland region (grim + slurp)" ;;
        spectacle)      echo "KDE Spectacle" ;;
        flameshot)      echo "Flameshot" ;;
        gnome)          echo "GNOME Screenshot" ;;
        *)              echo "$1" ;;
    esac
}

# Required commands per backend (satty is optional for grim-slurp:
# used for annotation when present, skipped otherwise).
backend_commands() {
    case "$1" in
        hyprland-satty) echo "hyprctl grim satty" ;;
        grim-slurp)     echo "grim slurp" ;;
        spectacle)      echo "spectacle" ;;
        flameshot)      echo "flameshot" ;;
        gnome)          echo "gnome-screenshot" ;;
        *)              echo "" ;;
    esac
}

backend_valid() {
    case " $BACKENDS " in
        *" $1 "*) return 0 ;;
        *) return 1 ;;
    esac
}

backend_available() {
    local cmd
    for cmd in $(backend_commands "$1"); do
        command_exists "$cmd" || return 1
    done
    return 0
}

list_backends() {
    local id marker=""
    for id in $BACKENDS; do
        if backend_available "$id"; then
            marker=" [installed]"
        else
            marker=" [missing: $(backend_commands "$id")]"
        fi
        printf '%-15s %s%s\n' "$id" "$(backend_label "$id")" "$marker"
    done
}

config_value() {
    # $1 = key name; prints value with surrounding whitespace stripped.
    [ -f "$CONFIG_FILE" ] || return 0
    awk -F= -v k="$1" '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*\[/ { next }
        {
            key = $1
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
            if (key == k) {
                $1 = ""
                val = substr($0, 2)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
                print val
                exit
            }
        }
    ' "$CONFIG_FILE"
}

resolve_backend() {
    local requested="$1" id
    if [ -n "$requested" ]; then
        if ! backend_valid "$requested"; then
            echo "Error: unknown backend '$requested'. Valid: $BACKENDS" >&2
            return 1
        fi
        if ! backend_available "$requested"; then
            echo "Error: backend '$requested' needs missing tools: $(backend_commands "$requested")" >&2
            return 1
        fi
        printf '%s' "$requested"
        return 0
    fi
    requested="$(config_value backend)"
    if [ -n "$requested" ] && backend_valid "$requested" && backend_available "$requested"; then
        printf '%s' "$requested"
        return 0
    fi
    for id in $BACKENDS; do
        if backend_available "$id"; then
            printf '%s' "$id"
            return 0
        fi
    done
    echo "Error: no screenshot backend installed. Need one of:" >&2
    list_backends >&2
    return 1
}

_notify() {
    command_exists notify-send || return 0
    notify-send --expire-time 1000 \
        --app-name "$APP_NAME" \
        --icon 'screengrab' \
        "$1" "${2:-}"
}

_confirm() {
    # $1 = question text. True when user accepts upload.
    if command_exists zenity; then
        zenity --question --title="$APP_NAME" --text="$1"
    elif command_exists kdialog; then
        kdialog --yesno "$1" --title "$APP_NAME"
    else
        # No dialog tool: assume yes (headless/scripted use).
        return 0
    fi
}

_copy_url() {
    if command_exists wl-copy; then
        wl-copy "$1"
    elif command_exists xclip; then
        printf '%s' "$1" | xclip -selection clipboard
    else
        _notify "No clipboard tool (wl-copy/xclip)" "$1"
    fi
}

capture_hyprland_satty() {
    local file="$1" monitor=""
    monitor="$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')"
    grim -o "$monitor" "$file" || return 1
    satty --filename "$file" \
        --initial-tool "crop" \
        --early-exit \
        --fullscreen \
        --output-filename "$file" \
        --actions-on-enter save-to-clipboard \
        --save-after-copy \
        --disable-notifications \
        --copy-command 'wl-copy'
}

capture_grim_slurp() {
    local file="$1" region=""
    region="$(slurp)" || return 1
    [ -n "$region" ] || return 1
    grim -g "$region" "$file" || return 1
    if command_exists satty; then
        satty --filename "$file" \
            --initial-tool "crop" \
            --early-exit \
            --fullscreen \
            --output-filename "$file" \
            --actions-on-enter save-to-clipboard \
            --save-after-copy \
            --disable-notifications \
            --copy-command 'wl-copy'
    fi
}

capture_spectacle() {
    spectacle --background --nonotify --region --output "$1"
}

capture_flameshot() {
    flameshot gui --path "$1"
}

capture_gnome() {
    gnome-screenshot --area --file="$1"
}

BACKEND_OVERRIDE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --backend)
            [ $# -ge 2 ] || { echo "Error: --backend needs an id. Valid: $BACKENDS" >&2; exit 1; }
            BACKEND_OVERRIDE="$2"; shift 2 ;;
        --backend=*) BACKEND_OVERRIDE="${1#--backend=}"; shift ;;
        --list-backends) list_backends; exit 0 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Error: unknown option: $1 (see --help)" >&2; exit 1 ;;
    esac
done

BACKEND="$(resolve_backend "$BACKEND_OVERRIDE")" || exit 1

mkdir -p "$STORE_DIR"

current_date="$(date +"%Y-%m-%d %H-%M-%S")"
filename="Screenshot_$current_date.png"
complete_path="${STORE_DIR}/${filename}"

case "$BACKEND" in
    hyprland-satty) capture_hyprland_satty "$complete_path" || true ;;
    grim-slurp)     capture_grim_slurp "$complete_path" || true ;;
    spectacle)      capture_spectacle "$complete_path" || true ;;
    flameshot)      capture_flameshot "$complete_path" || true ;;
    gnome)          capture_gnome "$complete_path" || true ;;
esac

# If user cancels or file is not valid after capture, exit quietly.
if [ ! -f "$complete_path" ] || [ "$(file --mime-type -b "$complete_path")" != "image/png" ]; then
    _notify "Screenshot canceled or not saved"
    exit 0
fi

# Ask user if they want to upload
if ! _confirm "Upload the screenshot to s-ul.eu?"; then
    _notify "Upload canceled by user"
    exit 0
fi

key="$(config_value key)"
if [ -z "$key" ]; then
    _notify "Error: API key not found in config.ini"
    exit 1
fi

method=POST
postURL=https://s-ul.eu/api/v1/upload
wizard=true
file="$complete_path"

actualsize=$(wc -c <"$file")
maxsize=209714177

if [ "$actualsize" -ge "$maxsize" ]; then
    _notify "\nSorry, your file is too large to be uploaded. Please try a smaller file.\n"
fi

_notify 'Uploading screenshot...'

response=$(curl -s -X "$method" "$postURL?key=$key&wizard=$wizard" -F "file=@$file")
url=$(printf '%s' "$response" | jq -r '.url')

if [ -z "$url" ] || [ "$url" = "null" ]; then
    error_msg=$(printf '%s' "$response" | jq -r '.error // "Unknown error"')
    printf '%s\n' "$response"
    _notify "Error: Upload failed" "$error_msg"
else
    _copy_url "$url"
    _notify 'Success! Screenshot uploaded to:' "$url"
fi
SUL_UPLOADER_EOF
    chmod +x "$INSTALL_PATH"
    print_info "Installed $INSTALL_PATH"
}

config_current_value() {
    # $1 = key name from the installer's CONFIG_FILE (same format as uploader).
    [ -f "$CONFIG_FILE" ] || return 0
    awk -F= -v k="$1" '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*\[/ { next }
        {
            key = $1
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
            if (key == k) {
                $1 = ""
                val = substr($0, 2)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
                print val
                exit
            }
        }
    ' "$CONFIG_FILE"
}

setup_config() {
    local backend="$1"
    mkdir -p "$CONFIG_DIR"

    local existing_key="" existing_backend=""
    if [ -f "$CONFIG_FILE" ]; then
        existing_key="$(config_current_value key)"
        existing_backend="$(config_current_value backend)"
    fi

    if [ "$FORCE" = false ] && [ -n "$existing_key" ] && [ -n "$existing_backend" ]; then
        if [ "$existing_backend" = "$backend" ]; then
            print_info "$CONFIG_FILE already configured (backend=$backend), keeping it (use --force to overwrite)."
        else
            print_warn "$CONFIG_FILE already configured with backend=$existing_backend, keeping it (chosen now: $backend; use --force to switch)."
        fi
        return 0
    fi

    # Merge: keep whatever already exists, fill in the gaps.
    if [ -z "$existing_backend" ]; then
        existing_backend="$backend"
    elif [ "$FORCE" = true ]; then
        existing_backend="$backend"
    fi

    if [ -z "$existing_key" ]; then
        print_info "Creating $CONFIG_FILE (backend=$existing_backend)"
        if ! existing_key="$(prompt_api_key)" || [ -z "$existing_key" ]; then
            # Still write the backend so a later key-only run only asks for the key.
            printf '[DEFAULT]\nkey=\nbackend=%s\n' "$existing_backend" > "$CONFIG_FILE"
            chmod 600 "$CONFIG_FILE"
            print_error "No API key configured (non-interactive shell, or empty input)."
            print_error "Get one from https://s-ul.eu/account/preferences, then set it:"
            print_error "  sul-uploader will tell you, or edit $CONFIG_FILE"
            return 1
        fi
    else
        print_info "Updating $CONFIG_FILE (backend=$existing_backend)"
    fi

    printf '[DEFAULT]\nkey=%s\nbackend=%s\n' "$existing_key" "$existing_backend" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    print_info "Wrote $CONFIG_FILE"
}

# ------------------------------------------------------------- KDE keybind

kde_desktop_file="$HOME/.local/share/applications/sul-uploader.desktop"
kde_sc_group1="services"
kde_sc_group2="sul-uploader.desktop"
kde_sc_key="_launch"

kde_current_keybind() {
    # Prints the currently registered keybind, if any.
    if command_exists kreadconfig6; then
        kreadconfig6 --file kglobalshortcutsrc --group "$kde_sc_group1" --group "$kde_sc_group2" --key "$kde_sc_key" 2>/dev/null
    elif command_exists kreadconfig5; then
        kreadconfig5 --file kglobalshortcutsrc --group "$kde_sc_group1" --group "$kde_sc_group2" --key "$kde_sc_key" 2>/dev/null
    else
        awk -v header="[$kde_sc_group1][$kde_sc_group2]" -v key="$kde_sc_key" '
            /^\[.*\]/ { in_g = ($0 == header); next }
            in_g && $0 ~ "^" key "[[:space:]]*=" {
                sub("^" key "[[:space:]]*=[[:space:]]*", "")
                print; exit
            }
        ' "$HOME/.config/kglobalshortcutsrc" 2>/dev/null
    fi
}

kde_write_keybind() {
    # $1 = keybind (e.g. Meta+Shift+S).
    if command_exists kwriteconfig6; then
        kwriteconfig6 --file kglobalshortcutsrc \
            --group "$kde_sc_group1" --group "$kde_sc_group2" \
            --key "$kde_sc_key" "$1"
    elif command_exists kwriteconfig5; then
        kwriteconfig5 --file kglobalshortcutsrc \
            --group "$kde_sc_group1" --group "$kde_sc_group2" \
            --key "$kde_sc_key" "$1"
    else
        local src="$HOME/.config/kglobalshortcutsrc" tmp=""
        tmp="$(mktemp)" || return 1
        touch "$src"
        awk -v header="[$kde_sc_group1][$kde_sc_group2]" -v key="$kde_sc_key" -v val="$1" '
            BEGIN { seen = 0; in_g = 0; wrote = 0 }
            /^\[.*\]/ {
                if (in_g && !wrote) { print key"="val; wrote = 1 }
                in_g = ($0 == header)
                if (in_g) seen = 1
                print; next
            }
            {
                if (in_g && !wrote && $0 ~ "^" key "[[:space:]]*=") {
                    print key"="val; wrote = 1; next
                }
                print
            }
            END {
                if (!seen) { print header; print key"="val }
                else if (in_g && !wrote) { print key"="val }
            }
        ' "$src" > "$tmp" && cat "$tmp" > "$src"
        rm -f "$tmp"
    fi
}

kde_keybind_conflicts() {
    # $1 = keybind. Prints offending kglobalshortcutsrc lines (excluding ours).
    local kb="$1" src="$HOME/.config/kglobalshortcutsrc"
    [ -f "$src" ] || return 1
    grep -F -n "$kb" "$src" | grep -v -F "[$kde_sc_group1][$kde_sc_group2]" | grep -v -F "$kde_sc_key=$kb" || return 1
}

kde_activate_keybind() {
    # Best effort: Plasma 5 can reload in-session, Plasma 6 usually needs re-login.
    local v="$1"
    if [ "$v" = "5" ]; then
        if command_exists qdbus; then
            qdbus org.kde.keyboard /modules/khotkeys reread_configuration >/dev/null 2>&1 || true
        fi
        if command_exists kquitapp5; then
            kquitapp5 kglobalaccel >/dev/null 2>&1 || true
            sleep 1
        fi
        print_info "KDE (Plasma 5): shortcut service asked to reload. If the key does nothing, log out and back in."
    else
        if command_exists qdbus6; then
            qdbus6 org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfiguration >/dev/null 2>&1 || true
        elif command_exists qdbus; then
            qdbus org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfiguration >/dev/null 2>&1 || true
        fi
        print_warn "Plasma 6 does not reliably pick up scripted shortcuts in a running session."
        print_warn "If $DEFAULT_KEYBIND (or your choice) does nothing yet, log out and back in once."
    fi
}

setup_kde_keybind() {
    # Only ever called on KDE. Honors --no-keybind / --keybind.
    if [ "$NO_KEYBIND" = true ]; then
        print_warn "Skipping KDE keybind setup (--no-keybind)."
        return 0
    fi

    local keybind="$KEYBIND_FLAG"
    if [ -z "$keybind" ] && ! interactive; then
        print_warn "Skipping KDE keybind setup (non-interactive; pass --keybind \"<keys>\" to set one)."
        return 0
    fi

    if [ -z "$keybind" ]; then
        if ! ask "Set up a KDE global keybind for sul-uploader? (Y/n)"; then
            print_warn "Skipping KDE keybind setup."
            return 0
        fi
    fi

    local current=""
    current="$(kde_current_keybind)"

    local attempts=0
    while [ "$attempts" -lt 3 ]; do
        if [ -z "$keybind" ]; then
            keybind="$(prompt_line "Keybind for sul-uploader" "$DEFAULT_KEYBIND")"
        fi
        if [ -z "$keybind" ]; then
            print_warn "Empty keybind, skipping keybind setup."
            return 0
        fi
        if [ -n "$current" ] && [ "$current" = "$keybind" ]; then
            print_info "KDE keybind already set to $keybind."
            return 0
        fi
        local conflicts=""
        if conflicts="$(kde_keybind_conflicts "$keybind")" && [ -n "$conflicts" ]; then
            print_warn "'$keybind' looks taken already:"
            printf '%s\n' "$conflicts" | head -n 5 >&2
            if [ -n "$KEYBIND_FLAG" ]; then
                print_error "Refusing to steal '$keybind' in non-interactive mode. Pick another via --keybind."
                return 1
            fi
            if ask_default_no "Use '$keybind' anyway? (y/N)"; then
                break
            fi
            keybind=""
            attempts=$((attempts + 1))
            continue
        fi
        break
    done
    if [ "$attempts" -ge 3 ]; then
        print_warn "Giving up on keybind setup after 3 tries."
        return 1
    fi

    print_info "Binding '$keybind' to $INSTALL_PATH ..."

    mkdir -p "$HOME/.local/share/applications"
    cat > "$kde_desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=Screenshot Uploader
Comment=Take a screenshot and upload it to s-ul.eu
Exec=$INSTALL_PATH
Icon=screengrab
StartupNotify=false
X-KDE-GlobalAccel-CommandShortcut=true
EOF

    kde_write_keybind "$keybind" || {
        print_error "Failed to write kglobalshortcutsrc."
        return 1
    }

    local verify=""
    verify="$(kde_current_keybind)"
    if [ "$verify" != "$keybind" ]; then
        print_error "Wrote keybind but read-back is '$verify' — please set it in System Settings > Shortcuts."
        print_error "  Command: $INSTALL_PATH"
        return 1
    fi

    kde_activate_keybind "$(plasma_version)"
    print_info "KDE keybind '$keybind' registered for sul-uploader."
}

# ------------------------------------------------------------- misc

print_hyprland_hint() {
    print_info "Hyprland hint — add this bind to your hyprland config:"
    print_info "  bind = \$mainMod SHIFT, S, exec, $INSTALL_PATH"
}

ensure_path() {
    case ":$PATH:" in
        *":$INSTALL_DIR:"*) ;;
        *)
            print_warn "$INSTALL_DIR is not in your PATH."
            print_warn "  bash/zsh: export PATH=\"\$HOME/.local/bin:\$PATH\""
            print_warn "  fish:     fish_add_path \$HOME/.local/bin"
            ;;
    esac
}

main() {
    print_info "Starting sul-uploader installation..."

    local de suggestion backend
    de="$(detect_de)"
    suggestion="$(preselect_backend "$de")"
    backend="$(choose_backend "$de" "$suggestion")" || exit 1
    print_info "Using screenshot backend: $backend ($(backend_label "$backend"))"

    if ! backend_available "$backend"; then
        print_warn "Backend '$backend' needs:$(backend_missing_cmds "$backend")"
    fi

    install_dependencies "$backend" || print_warn "Continuing despite missing dependencies."
    write_uploader || exit 1
    setup_config "$backend" || print_warn "Continuing without a configured API key."

    if [ "$de" = "kde" ]; then
        setup_kde_keybind || print_warn "Continuing without a KDE keybind."
    elif [ "$backend" = "hyprland-satty" ]; then
        print_hyprland_hint
    fi

    ensure_path
    print_info "Done! Run 'sul-uploader' to take a screenshot (you may need to restart your shell for PATH)."
}

main
