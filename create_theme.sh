#!/bin/bash

# 🎨 Cappuccino Colors
HEADER='\033[1;38;5;221m'
INFO='\033[1;38;5;152m'
PROMPT='\033[0;38;5;117m'
SUCCESS='\033[0;38;5;114m'
WARNING='\033[0;38;5;215m'
ERROR='\033[0;38;5;203m'
RESET='\033[0m'

THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
THEMES_DIR="$THEME_DIR/Themes"
BACKGROUNDS_DIR="$THEME_DIR/Backgrounds"
FONTS_DIR="$THEME_DIR/Fonts"
TEMPLATE_CONF="$THEME_DIR/template.conf"

# --- Theme Name ---
while true; do
    echo -ne "${PROMPT}[>] Enter a name for your new theme (letters, numbers, _ only): ${RESET}"
    read -r THEME_NAME
    [[ "$THEME_NAME" =~ ^[a-zA-Z0-9_]+$ ]] || { echo -e "${ERROR}[!] Invalid name.${RESET}"; continue; }
    [[ ! -e "$THEMES_DIR/$THEME_NAME.conf" ]] || { echo -e "${ERROR}[!] Theme already exists.${RESET}"; continue; }
    break
done

CONF_FILE="$THEMES_DIR/${THEME_NAME}.conf"

# --- Wallpaper ---
echo -ne "${PROMPT}[?] Do you want to use your own wallpaper? (y/n): ${RESET}"
read -r USE_CUSTOM_WALL
if [[ "$USE_CUSTOM_WALL" == "y" ]]; then
    while true; do
        echo -ne "${PROMPT}[>] Enter full path to your wallpaper: ${RESET}"
        read WALL_PATH
        if [[ -f "$WALL_PATH" ]]; then
            WALL_EXT="${WALL_PATH##*.}"
            WALL_FILE="${THEME_NAME}.${WALL_EXT}"
            sudo cp "$WALL_PATH" "$BACKGROUNDS_DIR/$WALL_FILE"
            echo -e "${SUCCESS}[✓] Wallpaper copied.${RESET}"

            if [[ "$WALL_EXT" =~ ^(mp4|webm|mov)$ ]]; then
                echo -e "${WARNING}[~] Video wallpaper detected. Placeholder required.${RESET}"
                while true; do
                    echo -ne "${PROMPT}[>] Path to placeholder image (png/jpg/gif): ${RESET}"
                    read PLACEHOLDER_PATH
                    PLACEHOLDER_EXT="${PLACEHOLDER_PATH##*.}"
                    if [[ -f "$PLACEHOLDER_PATH" && "$PLACEHOLDER_EXT" =~ ^(png|jpg|jpeg|gif)$ ]]; then
                        PLACEHOLDER_NAME="${THEME_NAME}_placeholder.${PLACEHOLDER_EXT}"
                        sudo cp "$PLACEHOLDER_PATH" "$BACKGROUNDS_DIR/$PLACEHOLDER_NAME"
                        BACKGROUND_PLACEHOLDER_LINE="BackgroundPlaceholder=\"Backgrounds/$PLACEHOLDER_NAME\""
                        break
                    else
                        echo -e "${ERROR}[!] Invalid file or format.${RESET}"
                    fi
                done
            fi
            break
        else
            echo -e "${ERROR}[!] File not found.${RESET}"
        fi
    done
else
    echo -e "${HEADER}[~] Choose a wallpaper from available ones:${RESET}"
    mapfile -t wallpapers < <(find "$BACKGROUNDS_DIR" -maxdepth 1 -type f -exec basename {} \;)
    for i in "${!wallpapers[@]}"; do
        echo -e "${INFO}$((i+1)).${RESET} ${wallpapers[i]}"
    done
    while true; do
        echo -ne "${PROMPT}[?] Enter wallpaper number: ${RESET}"
        read -r WNUM
        if [[ "$WNUM" =~ ^[0-9]+$ ]] && ((WNUM >= 1 && WNUM <= ${#wallpapers[@]})); then
            WALL_FILE="${wallpapers[$((WNUM-1))]}"
            WALL_EXT="${WALL_FILE##*.}"
            break
        else
            echo -e "${ERROR}[!] Invalid selection.${RESET}"
        fi
    done
fi

WALL_LINE="Background=\"Backgrounds/$WALL_FILE\""

# --- Font ---
echo -e "${HEADER}[~] Choose a font from available ones:${RESET}"
mapfile -t fonts < <(find "$FONTS_DIR" -maxdepth 1 -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec basename {} \;)
echo -e "${INFO}$((1)).${RESET} Open Sans"
for i in "${!fonts[@]}"; do
    echo -e "${INFO}$((i+2)).${RESET} ${fonts[i]}"
done
while true; do
    echo -ne "${PROMPT}[?] Enter font number: ${RESET}"
    read -r FNUM
    if [[ "$FNUM" =~ ^[0-9]+$ ]] && ((FNUM >= 1 && FNUM <= ${#fonts[@]})); then
        if [[ FNUM == 1 ]]; then
            FONT_FILE="Open Sans"
            break
        else
            FONT_FILE="${fonts[$((FNUM-1))]}"
        fi
        break
    else
        echo -e "${ERROR}[!] Invalid selection.${RESET}"
    fi
done

FONT_NAME="${FONT_FILE%%.*}"  # remove extension only
FONT_LINE="Font=\"$FONT_NAME\""

# --- Layout Option ---
echo -ne "${PROMPT}[?] Do you want to base your theme on a preset layout? (y/n): ${RESET}"
read -r USE_PRESET

if [[ "$USE_PRESET" == "y" ]]; then
    echo -e "${HEADER}[~] Choose a preset layout to copy:${RESET}"
    mapfile -t presets < <(find "$THEMES_DIR" -name "*.conf" -exec basename {} .conf \;)
    for i in "${!presets[@]}"; do
        echo -e "${INFO}$((i+1)).${RESET} ${presets[i]}"
    done
    while true; do
        echo -ne "${PROMPT}[?] Enter preset number: ${RESET}"
        read -r PNUM
        if [[ "$PNUM" =~ ^[0-9]+$ ]] && ((PNUM >= 1 && PNUM <= ${#presets[@]})); then
            PRESET_NAME="${presets[$((PNUM-1))]}"
            sudo cp "$THEMES_DIR/${PRESET_NAME}.conf" "$CONF_FILE"
            sudo sed -i "s|^Background=.*|$WALL_LINE|" "$CONF_FILE"
            # Font injection
            if grep -q "^Font=" "$CONF_FILE"; then
                sudo sed -i "s|^Font=.*|$FONT_LINE|" "$CONF_FILE"
            else
                echo "$FONT_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
            fi

            [[ -n "$BACKGROUND_PLACEHOLDER_LINE" ]] && \
                sudo sed -i "s|^BackgroundPlaceholder=.*|$BACKGROUND_PLACEHOLDER_LINE|" "$CONF_FILE"
            echo -e "${SUCCESS}[✓] Preset '$PRESET_NAME' copied and modified.${RESET}"
            exit 0
        else
            echo -e "${ERROR}[!] Invalid selection.${RESET}"
        fi
    done
fi

# --- Manual Layout ---
echo -ne "${PROMPT}[?] Do you want guidance for layout creation? (y/n): ${RESET}"
read -r GUIDE

echo -e "${HEADER}[~] Generating ${CONF_FILE}...${RESET}"
echo "[General]" | sudo tee "$CONF_FILE" >/dev/null
echo "$WALL_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
echo "$FONT_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
[[ -n "$BACKGROUND_PLACEHOLDER_LINE" ]] && echo "$BACKGROUND_PLACEHOLDER_LINE" | sudo tee -a "$CONF_FILE" >/dev/null

if [[ "$GUIDE" == "y" ]]; then
    echo -e "${INFO}[~] Guided config begins. Hit [Enter] to skip any field.${RESET}"

    # Suggestions for known properties
    declare -A SUGGESTIONS=(
        ["ScreenWidth"]="e.g. 1920"
        ["ScreenPadding"]="e.g. 100"
        ["FontSize"]="e.g. 20"
        ["KeyboardSize"]="Default: 0.4"
        ["RoundCorners"]="true / false"
        ["Locale"]="e.g. en_US / ja_JP"
        ["HourFormat"]="12 / 24"
        ["DateFormat"]="dd/MM/yyyy / yyyy-MM-dd"
        ["HeaderText"]="e.g. Welcome!"
        ["BackgroundSpeed"]="1 / 2 / 3"
        ["PauseBackground"]="true / false"
        ["DimBackground"]="true / false"
        ["CropBackground"]="true / false"
        ["BackgroundHorizontalAlignment"]="left / center / right"
        ["BackgroundVerticalAlignment"]="top / center / bottom"
        ["HeaderTextColor"]="#RRGGBB"
        ["TimeTextColor"]="#RRGGBB"
        ["FormBackgroundColor"]="#RRGGBB88"
        ["DimBackgroundColor"]="#RRGGBB88"
        ["LoginFieldBackgroundColor"]="#RRGGBB"
        ["LoginFieldTextColor"]="#RRGGBB"
        ["UserIconColor"]="#RRGGBB"
        ["PlaceholderTextColor"]="#RRGGBB"
        ["LoginButtonTextColor"]="#RRGGBB"
        ["SystemButtonsIconsColor"]="#RRGGBB"
        ["VirtualKeyboardButtonTextColor"]="#RRGGBB"
        ["DropdownTextColor"]="#RRGGBB"
        ["DropdownBackgroundColor"]="#RRGGBB"
        ["HighlightTextColor"]="#RRGGBB"
        ["HighlightBorderColor"]="#RRGGBB"
        ["HoverUserIconColor"]="#RRGGBB"
        ["HoverSystemButtonsIconsColor"]="#RRGGBB"
        ["HoverVirtualKeyboardButtonTextColor"]="#RRGGBB"
        ["PartialBlur"]="true / false"
        ["FullBlur"]="true / false"
        ["BlurMax"]="e.g. 5, 10, 20"
        ["Blur"]="e.g. 2, 3, 5"
        ["HaveFormBackground"]="true / false"
        ["FormPosition"]="left / center / right"
        ["VirtualKeyboardPosition"]="top / bottom"
        ["HideVirtualKeyboard"]="true / false"
        ["HideLoginButton"]="true / false"
        ["ForceLastUser"]="true / false"
        ["PasswordFocus"]="true / false"
        ["HideCompletePassword"]="true / false"
        ["AllowEmptyPassword"]="true / false"
        ["AllowUppercaseLettersInUsernames"]="true / false"
        ["BypassSystemButtonsChecks"]="true / false"
        ["RightToLeftLayout"]="true / false"
        ["TranslatePlaceholderUsername"]="e.g. Username"
        ["TranslateLogin"]="e.g. Login"
        ["TranslateCapslockWarning"]="e.g. Caps Lock is on"
        ["TranslateHibernate"]="e.g. Hibernate"
        ["TranslateShutdown"]="e.g. Shutdown"
        ["TranslateVirtualKeyboardButtonOn"]="e.g. Show Keyboard"
        ["TranslateVirtualKeyboardButtonOff"]="e.g. Hide Keyboard"
    )

    # Start fresh
    sudo tee "$CONF_FILE" <<< "" >/dev/null
    echo "# Generated using guided layout wizard" | sudo tee "$CONF_FILE" >/dev/null

    exec 3< "$TEMPLATE_CONF"
    while IFS= read -r line <&3 || [[ -n "$line" ]]; do
        # Preserve comments, blank lines, and section headers
        if [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^#.*$ || "$line" =~ ^\[.*\]$ ]]; then
            echo "$line" | sudo tee -a "$CONF_FILE" >/dev/null
            continue
        fi

        key="${line%%=*}"
        suggestion="${SUGGESTIONS[$key]}"

        echo -ne "${PROMPT}[>] $key"
        [[ -n "$suggestion" ]] && echo -ne " (${suggestion})"
        echo -ne " = ${RESET}"
        read -r value

        if [[ -n "$value" ]]; then
            echo "$key=\"$value\"" | sudo tee -a "$CONF_FILE" >/dev/null
        else
            # Write key with blank value if user skipped
            echo "$key=" | sudo tee -a "$CONF_FILE" >/dev/null
        fi
    done
    exec 3<&-

    # Append required lines for functionality
    [[ -n "$WALL_LINE" ]] && echo "$WALL_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
    [[ -n "$FONT_LINE" ]] && echo "$FONT_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
    [[ -n "$BACKGROUND_PLACEHOLDER_LINE" ]] && echo "$BACKGROUND_PLACEHOLDER_LINE" | sudo tee -a "$CONF_FILE" >/dev/null


    echo -e "${SUCCESS}[✓] Layout generated: $CONF_FILE${RESET}"
else
    echo -e "${INFO}[~] Creating empty config with minimal values.${RESET}"
    echo "# You can tweak the layout manually later." | sudo tee "$CONF_FILE" >/dev/null
    echo "$WALL_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
    echo "$FONT_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
    [[ -n "$BACKGROUND_PLACEHOLDER_LINE" ]] && echo "$BACKGROUND_PLACEHOLDER_LINE" | sudo tee -a "$CONF_FILE" >/dev/null
fi


echo -e "${SUCCESS}[✓] Theme '${THEME_NAME}' created successfully.${RESET}"
