#!/bin/bash

# 🌟 Cappuccino Color Scheme
bold=$(tput bold)
normal=$(tput sgr0)

green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
cyan='\033[0;36m'
magenta='\033[0;35m'
reset='\033[0m'

# Directories (adjust if needed)
THEMES_DIR="./Themes"
BACKGROUNDS_DIR="./Backgrounds"
FONTS_DIR="./Fonts"
DEFAULT_WALLPAPER="$BACKGROUNDS_DIR/default.png"
DEFAULT_FONT="$FONTS_DIR/ESPACION.ttf"

# Validate theme name
validate_theme_name() {
    [[ "$1" =~ ^[a-zA-Z0-9_]+$ ]]
}

# Validate background file type
is_valid_background() {
    local ext="${1##*.}"
    case "${ext,,}" in jpg|jpeg|png|gif|mp4|webm|mov) return 0 ;; *) return 1 ;; esac
}

# Validate font file type
is_valid_font() {
    local ext="${1##*.}"
    case "${ext,,}" in ttf|otf) return 0 ;; *) return 1 ;; esac
}

echo -e "${cyan}${bold}🧵 Theme Creator — sddm-astronaut-theme${reset}"

# Prompt for theme name
while true; do
    echo -ne "${yellow}[?] Enter a new theme name (letters, numbers, underscores only): ${reset}"
    read THEME_NAME

    if ! validate_theme_name "$THEME_NAME"; then
        echo -e "${red}[!] Invalid name. Use only letters, numbers, and underscores (_).${reset}"
        continue
    fi

    if [[ -e "$THEMES_DIR/$THEME_NAME.conf" ]]; then
        echo -e "${red}[!] Theme \"$THEME_NAME\" already exists. Choose another name.${reset}"
        continue
    fi
    break
done

# --- Wallpaper ---
echo -ne "${yellow}[?] Use your own wallpaper? (y/n): ${reset}"
read USE_CUSTOM_WALL

if [[ "$USE_CUSTOM_WALL" == "y" ]]; then
    while true; do
        echo -ne "${INPUT}[>] Enter full path to your wallpaper: ${RESET}"
        read -r WALL_PATH

        if [[ -f "$WALL_PATH" ]] && is_valid_background "$WALL_PATH"; then
            WALL_EXT="${WALL_PATH##*.}"
            DEST_WALL="$BACKGROUNDS_DIR/${THEME_NAME}.${WALL_EXT}"
            sudo cp "$WALL_PATH" "$DEST_WALL"
            echo -e "${SUCCESS}[✓] Wallpaper copied to: $DEST_WALL${RESET}"

            if [[ "$WALL_EXT" =~ ^(mp4|webm|mov)$ ]]; then
                echo -e "${INFO}[~] Detected a video background. A static placeholder is required.${RESET}"

                while true; do
                    echo -ne "${INPUT}[>] Enter full path to a placeholder image (jpg/png/gif): ${RESET}"
                    read -r PLACEHOLDER_PATH

                    PLACEHOLDER_EXT="${PLACEHOLDER_PATH##*.}"
                    PLACEHOLDER_NAME="${THEME_NAME}_placeholder.${PLACEHOLDER_EXT}"
                    DEST_PLACEHOLDER="$BACKGROUNDS_DIR/$PLACEHOLDER_NAME"

                    if [[ -f "$PLACEHOLDER_PATH" ]] && [[ "$PLACEHOLDER_EXT" =~ ^(jpg|jpeg|png|gif)$ ]]; then
                        sudo cp "$PLACEHOLDER_PATH" "$DEST_PLACEHOLDER"
                        BACKGROUND_PLACEHOLDER_LINE="BackgroundPlaceholder=\"Backgrounds/$PLACEHOLDER_NAME\""
                        echo -e "${SUCCESS}[✓] Placeholder added as: $PLACEHOLDER_NAME${RESET}"
                        break
                    else
                        echo -e "${ERROR}[!] Invalid file or unsupported format. Please use jpg, png, or gif.${RESET}"
                    fi
                done
            fi
            break
        else
            echo -e "${ERROR}[!] Wallpaper not found or unsupported format.${RESET}"
        fi
    done
else
    WALL_EXT="${DEFAULT_WALLPAPER##*.}"
    sudo cp "$DEFAULT_WALLPAPER" "$BACKGROUNDS_DIR/${THEME_NAME}.${WALL_EXT}"
    echo -e "${green}[+] Default wallpaper applied.${reset}"
fi

# --- Font ---
echo -ne "${yellow}[?] Use your own font? (y/n): ${reset}"
read USE_CUSTOM_FONT

if [[ "$USE_CUSTOM_FONT" == "y" ]]; then
    while true; do
        echo -ne "${yellow}[>] Enter full path to your font (.ttf/.otf): ${reset}"
        read FONT_PATH
        if [[ -f "$FONT_PATH" ]] && is_valid_font "$FONT_PATH"; then
            FONT_NAME=$(basename "$FONT_PATH")
            sudo cp "$FONT_PATH" "$FONTS_DIR/$FONT_NAME"
            echo -e "${green}[+] Font copied.${reset}"
            break
        else
            echo -e "${red}[!] File not found or unsupported format.${reset}"
        fi
    done
else
    echo -e "${green}[+] Default font used.${reset}"
fi

# --- Layout ---
echo -e "${cyan}\n📐 Layout Source:${reset}"
echo -e "${yellow}1) Use a preset theme\n2) Create your own .conf${reset}"
echo -ne "${yellow}[?] Enter choice (1 or 2): ${reset}"
read LAYOUT_CHOICE

CONF_FILE="$THEMES_DIR/${THEME_NAME}.conf"
WALL_LINE="Background=\"Backgrounds/${THEME_NAME}.${WALL_EXT}\""

if [[ -n "$FONT_NAME" ]]; then
    FONT_LINE="Font=\"Fonts/${FONT_NAME}\""
fi


if [[ "$LAYOUT_CHOICE" == "1" ]]; then
    echo -e "${cyan}[+] Available Preset Themes:${reset}"
    mapfile -t PRESETS < <(ls "$THEMES_DIR"/*.conf | xargs -n 1 basename | sed 's/\.conf$//')

    for i in "${!PRESETS[@]}"; do
        echo -e "  ${INFO}$((i + 1)).${RESET} ${PROMPT}${PRESETS[i]}${RESET}"
    done

    while true; do
        echo -ne "${yellow}[?]Enter the number of the preset you want to use: ${reset}"
        read -r preset_choice

        if [[ "$preset_choice" =~ ^[0-9]+$ ]] && (( preset_choice >= 1 && preset_choice <= ${#PRESETS[@]} )); then
            PRESET="${PRESETS[preset_choice - 1]}"
            CONF_FILE="$THEMES_DIR/${THEME_NAME}.conf"
            sudo cp "$THEMES_DIR/${PRESET}.conf" "$CONF_FILE"
            echo -e "${green}[+] Copied layout from: $PRESET${reset}"

            [[ -n "$WALL_LINE" ]] && sudo sed -i "s|^Background=.*|$WALL_LINE|" "$CONF_FILE" || echo "$WALL_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
            [[ -n "$FONT_LINE" ]] && sudo sed -i "s|^Font=.*|$FONT_LINE|" "$CONF_FILE" || echo "$FONT_LINE" | sudo tee -a "$CONF_FILE" >/dev/null

            if [[ -n "$BACKGROUND_PLACEHOLDER_LINE" ]]; then
                if grep -q "^BackgroundPlaceholder=" "$CONF_FILE"; then
                    sudo sed -i "s|^BackgroundPlaceholder=.*|$BACKGROUND_PLACEHOLDER_LINE|" "$CONF_FILE"
                else
                    echo "$BACKGROUND_PLACEHOLDER_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
                fi
            fi
            break
        else
            echo -e "${red}[!] Invalid selection. Try again.${reset}"
        fi
    done
else
    sudo touch "$CONF_FILE"
    echo "# Define your theme layout here" | sudo tee "$CONF_FILE" >/dev/null
    echo "$WALL_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
    # echo "$FONT_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
    [[ -n "$BACKGROUND_PLACEHOLDER_LINE" ]] && echo "$BACKGROUND_PLACEHOLDER_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
    echo -e "${cyan}[+] Template created. You can now edit: $CONF_FILE${reset}"
fi

echo -e "\n${green}✅ Theme '${THEME_NAME}' created successfully!${reset}"
