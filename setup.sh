#!/bin/bash

# 🖋️ Metadata
## Fork of https://github.com/Keyitdev/sddm-astronaut-theme
## Copyright (C) 2022-2025 Keyitdev
## Licensed under GPLv3+: https://www.gnu.org/licenses/gpl-3.0.html

# 🎨 Cappuccino-Themed Colors
HEADER='\033[1;38;5;221m'       # warm pastel yellow
INFO='\033[1;38;5;152m'         # soft cyan for options
PROMPT='\033[0;38;5;117m'       # cool pastel blue
INPUT='\033[1;38;5;189m'        # delicate lavender pink for input prompts
SUCCESS='\033[0;38;5;114m'      # mellow green
WARNING='\033[0;38;5;215m'      # peachy orange
ERROR='\033[0;38;5;203m'        # soft red
RESET='\033[0m'

DATE=$(date +%s)
CLONE_PATH="$HOME"
THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
# 🌀 Loading bar function
loading_bar() {
    msg="$1"
    bar="█"
    echo -ne "${INFO}[~] $msg${RESET} "
    for i in {1..30}; do
        echo -ne "${bar}"
        sleep 0.01
    done
    echo -e " ${SUCCESS}done!${RESET}"
}

install_dependencies() {
    echo -e "${HEADER}[>] Installing dependencies...${RESET}"
    if command -v pacman &>/dev/null; then
        sudo pacman --noconfirm --needed -S sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
    elif command -v xbps-install &>/dev/null; then
        sudo xbps-install -y sddm qt6-svg qt6-virtualkeyboard qt6-multimedia
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y sddm-qt6 libQt6Svg6 qt6-virtualkeyboard qt6-virtualkeyboard-imports qt6-multimedia qt6-multimedia-imports
    else
        echo -e "${ERROR}[!] Error: No supported package manager found.${RESET}" >&2
        exit 1
    fi
    echo -e "${SUCCESS}[✓] Dependencies installed.${RESET}"
}

git_clone() {
    echo -e "${HEADER}[>] Cloning repository...${RESET}"
    local repo_dir="$CLONE_PATH/sddm-astronaut-theme"

    if [ -d "$repo_dir" ]; then
        echo -e "${WARNING}[!] Directory already exists at ${repo_dir}${RESET}"
        echo -ne "${INPUT}[?] Remove existing directory and re-clone? (y/n): ${RESET}"
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            sudo rm -rf "$repo_dir"
            echo -e "${INFO}[~] Removed existing directory.${RESET}"
        else
            echo -e "${ERROR}[x] Clone aborted by user.${RESET}"
            return
        fi
    fi

    loading_bar "Cloning from GitHub..."
    sudo git clone -b main --depth 1 https://github.com/Ishan0121/Modify-SDDM-theme.git "$repo_dir"

}


copy_files() {
    echo -e "${HEADER}[>] Installing theme to SDDM directory...${RESET}"
    local dest_dir="${THEME_DIR}"

    if [ -d "$dest_dir" ]; then
        echo -e "${WARNING}[!] Existing theme directory found at ${dest_dir}${RESET}"
        echo -ne "${INPUT}[?] Remove existing theme and overwrite? (y/n): ${RESET}"
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            sudo rm -rf "$dest_dir"
            echo -e "${INFO}[~] Removed existing theme directory.${RESET}"
        else
            echo -e "${ERROR}[x] Theme copy aborted by user.${RESET}"
            return
        fi
    fi

    loading_bar "Copying theme files..."
    sudo mkdir -p "$dest_dir"
    sudo cp -r "$CLONE_PATH/sddm-astronaut-theme/"* "$dest_dir"
    sudo cp -r "$dest_dir/Fonts/"* /usr/share/fonts/
    echo -e "${SUCCESS}[✓] Theme files copied.${RESET}"

    echo "[Theme]
Current=sddm-astronaut-theme" | sudo tee /etc/sddm.conf > /dev/null

    echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf > /dev/null
}

select_theme() {
    META="/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop"
    PREFIX="ConfigFile=Themes/"
    DIR="/usr/share/sddm/themes/sddm-astronaut-theme/Themes"

    echo -e "${HEADER}[>] Scanning available themes...${RESET}"
    mapfile -t all_themes < <(find "$DIR" -maxdepth 1 -name '*.conf' -exec basename {} .conf \;)

    if [[ "${#all_themes[@]}" -eq 0 ]]; then
        echo -e "${ERROR}[!] No .conf themes found in ${DIR}.${RESET}"
        exit 1
    fi

    # List of known preset themes
    presets=(astronaut black_hole cyberpunk hyprland_kath jake_the_dog japanese_aesthetic pixel_sakura pixel_sakura_static post-apocalyptic_hacker purple_leaves)

    echo -e "\n${INFO}[i] ★ = Preset theme, ✎ = Custom user-created theme${RESET}"

    # Show all themes with markers
    for i in "${!all_themes[@]}"; do
        theme="${all_themes[$i]}"
        if [[ " ${presets[*]} " == *" $theme "* ]]; then
            echo -e "${INFO}$((i + 1)).${RESET} ★ $theme"
        else
            echo -e "${INFO}$((i + 1)).${RESET} ✎ $theme"
        fi
    done

    echo -ne "\n${INPUT}[?] Choose a theme number to apply (1–${#all_themes[@]}): ${RESET}"
    read -r choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#all_themes[@]})); then
        echo -e "${ERROR}[!] Invalid selection.${RESET}"
        return
    fi

    selected_theme="${all_themes[$((choice - 1))]}"
    sudo sed -i "s|^$PREFIX.*|${PREFIX}${selected_theme}.conf|" "$META"
    echo -e "${SUCCESS}[✓] Theme applied: $selected_theme${RESET}"
}

create_theme() {
    local theme_dir="${THEME_DIR}"
    echo -e "${HEADER}[>] Running theme creation wizard...${RESET}"
    sudo chmod +x $theme_dir/create_theme.sh
    sudo bash $theme_dir/create_theme.sh
}

preview_themes() {
    local theme_dir="${THEME_DIR}"
    local metadata_file="$theme_dir/metadata.desktop"
    local config_prefix="ConfigFile=Themes/"
    local original_config
    original_config=$(grep "^${config_prefix}" "$metadata_file")

    mapfile -t themes < <(find "$theme_dir/Themes" -maxdepth 1 -name "*.conf" -exec basename {} .conf \;)
    if [[ ${#themes[@]} -eq 0 ]]; then
        echo -e "${ERROR}[!] No themes found to preview.${RESET}"
        return
    fi

    echo -e "${INFO}[~] Available themes to preview:${RESET}"
    for i in "${!themes[@]}"; do
        echo -e "  ${INFO}$((i + 1)).${RESET} ${PROMPT}${themes[i]}${RESET}"
    done
    echo -e "  ${INFO}0.${RESET} ${PROMPT}Exit${RESET}"

    while true; do
        echo -ne "${INPUT}Enter the theme number to preview: ${RESET}"
        read -r selection

        if [[ "$selection" == "0" ]]; then
            echo -e "${INFO}[~] Cancelled preview.${RESET}"
            break
        elif [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#themes[@]} )); then
            theme="${themes[$((selection - 1))]}"
            echo -e "${INFO}[~] Previewing '${theme}'...${RESET}"
            sudo sed -i "s|^${config_prefix}.*|${config_prefix}${theme}.conf|" "$metadata_file"
            sddm-greeter-qt6 --test-mode --theme "$theme_dir"
        else
            echo -e "${ERROR}[!] Invalid selection. Try again.${RESET}"
        fi
    done

    if [[ -n "$original_config" ]]; then
        sudo sed -i "s|^${config_prefix}.*|$original_config|" "$metadata_file"
        echo -e "${SUCCESS}[✓] Restored original theme selection.${RESET}"
    fi
}

enable_sddm() {
    echo -e "${HEADER}[>] Setting SDDM as default display manager...${RESET}"
    sudo systemctl disable display-manager.service
    sudo systemctl enable sddm.service
    echo -e "${SUCCESS}[✓] SDDM enabled.${RESET}"
}

# 🌟 Main Menu
while true; do
    clear
    echo -e "${HEADER}┌──────────────────────────────────────────────┐${RESET}"
    echo -e "${HEADER}│         SDDM Astronaut Theme Installer       │${RESET}"
    echo -e "${HEADER}└──────────────────────────────────────────────┘${RESET}"
    echo -e "${INFO} 1.${RESET} ${PROMPT}Full setup (clone → install → select → enable)${RESET}"
    echo -e "${INFO} 2.${RESET} ${PROMPT}Full installation, (clone → install)${RESET}"
    echo -e "${INFO} 3.${RESET} ${PROMPT}Install dependencies${RESET}"
    echo -e "${INFO} 4.${RESET} ${PROMPT}Preview a theme before applying${RESET}"
    echo -e "${INFO} 5.${RESET} ${PROMPT}Apply a theme${RESET}"
    echo -e "${INFO} 6.${RESET} ${PROMPT}Create a new theme${RESET}"
    echo -e "${INFO} 7.${RESET} ${PROMPT}Preview the current theme${RESET}"
    echo -e "${INFO} 8.${RESET} ${PROMPT}Enable SDDM${RESET}"
    echo -e "${INFO} 0.${RESET} ${PROMPT}Exit${RESET}"
    echo -e "${INFO} *** Full installation or Full setup recommended for first time user.${RESET}"
    echo -ne "${INPUT}[?] Your choice: ${RESET}"

    read -r choice

    case $choice in
        1) install_dependencies; git_clone; copy_files; select_theme; enable_sddm; exit ;;
        2) install_dependencies; git_clone; copy_files; exit ;;
        3) install_dependencies; exit ;;
        4) preview_themes; exit ;;
        5) select_theme; exit ;;
        6) create_theme; exit ;;
        7) sddm-greeter-qt6 --test-mode --theme ${THEME_DIR}/; exit ;;
        8) enable_sddm; exit ;;
        0) echo -e "${INFO}Exiting...${RESET}"; exit ;;
        *) echo -e "${ERROR}[!] Invalid option.${RESET}" ;;
    esac
done
