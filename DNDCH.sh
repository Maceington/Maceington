#!/bin/bash

# ============================================================
# D&D Character Creator - Work in Progress
# A learning project for practicing bash scripting.
# Up Next: Save File System
# ============================================================


# --- SETUP: Clear the screen and greet the player ---
# 'clear' wipes the terminal so the output looks clean each time.
# 'echo' prints a line of text. An empty 'echo' just prints a blank line.
clear
echo "Welcome to the D&D Character Creator!"
echo "Let's build your hero."
echo


# --- INPUT SECTION: Ask the player for basic character info ---
# 'read -p' displays a prompt and waits for the player to type something.
# Whatever they type gets stored in a variable (e.g., $name, $race).
# Variables are how bash remembers information — you set them and refer to them with a $ prefix.
read -p "What is your character's name? " name
read -p "Choose a race (Human, Elf, Dwarf, Gnome, or Dragonborn): " race
read -p "Choose a class (Wizard, Fighter, Rogue, Bard, Cleric, Barbarian or Sorcerer): " class
read -p "Enter your character's level [Default is 1]: " level

# If the player left 'level' blank, default it to 1.
# The ${variable:-default} syntax means "use this value if the variable is empty or unset."
level=${level:-1}


# --- STAT SETUP: Initialize the point-buy system ---
# In D&D 5e, you get 27 points to spend raising your ability scores above the base value of 8.
# 'declare -A' creates an associative array — think of it as a table where each stat name
# maps to a number. You look up a value with ${stats[STR]}, for example.
points=27
declare -A stats=( ["STR"]=8 ["DEX"]=8 ["CON"]=8 ["INT"]=8 ["WIS"]=8 ["CHA"]=8 )


# --- FUNCTION: Calculate the point cost of a given score ---
# A 'function' is a named, reusable block of code. You define it once, then call it by name.
# This function takes one number (a score) and prints how many points it costs in total.
# Higher scores cost disproportionately more — 14 and 15 are especially expensive.
cost_for_score() {
  local score=$1  # 'local' means this variable only exists inside this function.
                  # $1 refers to the first argument passed in when the function is called.
  case $score in  # 'case' is like a series of if/else checks — it matches $score to a value.
    8)  echo 0 ;;
    9)  echo 1 ;;
    10) echo 2 ;;
    11) echo 3 ;;
    12) echo 4 ;;
    13) echo 5 ;;
    14) echo 7 ;;
    15) echo 9 ;;
    *)  echo -1 ;; # '*' is the catch-all. Any score not listed above returns -1 (invalid).
  esac
}


# --- FUNCTION: Convert an ability score to its modifier ---
# In D&D, the number you actually add to dice rolls is the modifier, not the raw score.
# A score of 10 or 11 gives +0. Every 2 points above 10 adds +1, every 2 below subtracts 1.
# We use a lookup table here instead of math because bash division rounds toward zero,
# which gives wrong answers for scores like 9 (it would give 0 instead of -1).
modifier_for_score() {
  local score=$1
  case $score in
    1)       echo -5 ;;
    2|3)     echo -4 ;;
    4|5)     echo -3 ;;
    6|7)     echo -2 ;;
    8|9)     echo -1 ;;
    10|11)   echo 0  ;;
    12|13)   echo 1  ;;
    14|15)   echo 2  ;;
    16|17)   echo 3  ;;
    18|19)   echo 4  ;;
    20)      echo 5  ;;
    *)       echo 0  ;;
  esac
}


# --- FUNCTION: Format a modifier for display with its + or - sign ---
# In D&D, modifiers are always shown with their sign: +2, -1, +0, etc.
# Bash doesn't add a '+' automatically for positive numbers, so we do it here.
format_modifier() {
  local mod=$1
  if (( mod >= 0 )); then
    echo "+$mod"
  else
    echo "$mod"  # Negative numbers already have a minus sign.
  fi
}


# --- POINT-BUY LOOP: Let the player assign scores to each ability ---
# 'for ability in ...' loops through each stat name one at a time, left to right.
# 'while true' keeps looping forever until we explicitly 'break' out of it.
# This lets us keep asking until the player gives us a valid answer.
for ability in STR DEX CON INT WIS CHA; do
  while true; do
    clear
    echo "Assigning points for: $ability"
    echo "----------------------------------"
    echo "Current ability scores:"
    # Inner loop: print all current stat values so the player can see where they stand.
    for a in STR DEX CON INT WIS CHA; do
      echo "  $a: ${stats[$a]}"
    done
    echo "----------------------------------"
    echo "Remaining points: $points"
    echo "(Scores range from 8 to 15)"
    echo

    read -p "Enter desired $ability score: " new_score

    # Validate that the input is a whole number.
    # '=~' matches the input against a pattern. '^[0-9]+$' means:
    # ^ = start of input, [0-9]+ = one or more digits, $ = end of input.
    # The '!' flips it — this block runs if it does NOT match (i.e., it's not a number).
    if ! [[ $new_score =~ ^[0-9]+$ ]]; then
      echo "Please enter a number between 8 and 15."
      sleep 1
      continue  # 'continue' jumps back to the top of the while loop to ask again.
    fi

    # Check that the number is within the allowed 8–15 range.
    # '(( ))' is bash's arithmetic mode — use it for math and number comparisons.
    if (( new_score < 8 || new_score > 15 )); then
      echo "Score must be between 8 and 15."
      sleep 1
      continue
    fi

    # Look up the point cost of the current score and the desired new score.
    # '$( )' runs a command and captures its output as a value.
    base_score=${stats[$ability]}
    base_cost=$(cost_for_score "$base_score")  # How much the old score cost.
    new_cost=$(cost_for_score "$new_score")    # How much the new score costs.

    if (( new_cost == -1 )); then
      echo "Invalid score."
      sleep 1
      continue
    fi

    # cost_diff is the net points this change will spend.
    # If the new score is cheaper than the old one, this will be negative (a refund).
    cost_diff=$(( new_cost - base_cost ))

    # Make sure the player can afford it.
    if (( cost_diff > points )); then
      echo "Not enough points! You have $points left."
      sleep 1
      continue
    fi

    # Everything checks out — save the new score and subtract the cost.
    stats[$ability]=$new_score
    points=$(( points - cost_diff ))

    break  # Exit the while loop and move on to the next ability.
  done
done


# --- RACIAL BONUSES: Apply stat increases based on the chosen race ---
# Each race in D&D 5e comes with free bonus points to certain stats.
# These are applied AFTER point-buy and don't cost anything.
#
# '${race,,}' converts the player's input to all-lowercase letters,
# so "ELF", "Elf", and "elf" all match the same case block.
#
# We also track each bonus separately in 'racial_bonuses' so we can
# display them clearly on the character sheet at the end.
declare -A racial_bonuses=( ["STR"]=0 ["DEX"]=0 ["CON"]=0 ["INT"]=0 ["WIS"]=0 ["CHA"]=0 )

case "${race,,}" in
  human)
    # Humans are versatile — they get +1 to every ability score.
    # We loop through all six stats and add 1 to each.
    for stat in STR DEX CON INT WIS CHA; do
      stats[$stat]=$(( ${stats[$stat]} + 1 ))
      racial_bonuses[$stat]=1
    done
    ;;
  elf)
    # Elves are nimble and perceptive: +2 DEX, +1 WIS.
    stats[DEX]=$(( ${stats[DEX]} + 2 ))
    stats[WIS]=$(( ${stats[WIS]} + 1 ))
    racial_bonuses[DEX]=2
    racial_bonuses[WIS]=1
    ;;
  dwarf)
    # Dwarves are tough and strong: +2 CON, +1 STR.
    stats[CON]=$(( ${stats[CON]} + 2 ))
    stats[STR]=$(( ${stats[STR]} + 1 ))
    racial_bonuses[CON]=2
    racial_bonuses[STR]=1
    ;;
  gnome)
    # Gnomes are clever and surprisingly sturdy: +2 INT, +1 CON.
    stats[INT]=$(( ${stats[INT]} + 2 ))
    stats[CON]=$(( ${stats[CON]} + 1 ))
    racial_bonuses[INT]=2
    racial_bonuses[CON]=1
    ;;
  dragonborn)
    # Dragonborn are powerful and charismatic: +2 STR, +1 CHA.
    stats[STR]=$(( ${stats[STR]} + 2 ))
    stats[CHA]=$(( ${stats[CHA]} + 1 ))
    racial_bonuses[STR]=2
    racial_bonuses[CHA]=1
    ;;
  *)
    # If the input doesn't match any known race, warn the player and continue without bonuses.
    echo "Warning: Race '$race' not recognized. No racial bonuses applied."
    sleep 2
    ;;
esac


# --- CLASS MODIFIERS: Set class-specific stats based on chosen class ---
# Each class defines three things:
#   hit_die       — the die used for HP (e.g., 12 means a d12).
#   class_saves   — the two saving throws this class is trained in.
#   primary_stat  — the ability score this class relies on most.
#
# HP works like this in D&D 5e:
#   Level 1:           max hit die roll + CON modifier
#   Each level after:  average hit die roll (half + 1) + CON modifier
#
# So a level 3 Barbarian with CON 14 (+2) gets:
#   12 + 2  (level 1, max roll)
#   + (7+2) + (7+2)  (levels 2 and 3, average roll)
#   = 14 + 9 + 9 = 32 HP

# Start with safe defaults in case the class isn't recognized.
hit_die=8
class_saves="None"
primary_stat="None"

case "${class,,}" in
  wizard)
    hit_die=6
    class_saves="INT, WIS"
    primary_stat="INT"
    ;;
  sorcerer)
    hit_die=6
    class_saves="CON, CHA"
    primary_stat="CHA"
    ;;
  rogue)
    hit_die=8
    class_saves="DEX, INT"
    primary_stat="DEX"
    ;;
  bard)
    hit_die=8
    class_saves="DEX, CHA"
    primary_stat="CHA"
    ;;
  cleric)
    hit_die=8
    class_saves="WIS, CHA"
    primary_stat="WIS"
    ;;
  fighter)
    hit_die=10
    class_saves="STR, CON"
    primary_stat="STR"
    ;;
  barbarian)
    hit_die=12
    class_saves="STR, CON"
    primary_stat="STR"
    ;;
  *)
    # Unrecognized class — warn the player and use generic defaults.
    echo "Warning: Class '$class' not recognized. Using default hit die (d8) and no saves."
    sleep 2
    ;;
esac

# Calculate the CON modifier — it's added to HP every single level.
con_mod=$(modifier_for_score "${stats[CON]}")

# Level 1 HP = maximum hit die result + CON modifier.
# Each level after that uses the average roll: (hit_die / 2) + 1.
avg_per_level=$(( hit_die / 2 + 1 ))
hp=$(( hit_die + con_mod + (level - 1) * (avg_per_level + con_mod) ))

# HP can never go below 1, no matter how bad the CON modifier is.
if (( hp < 1 )); then
  hp=1
fi


# --- OUTPUT SECTION: Print the completed character sheet ---
# Everything the player entered and calculated is displayed here in one place.
clear
echo "=========================================="
echo "           CHARACTER SHEET"
echo "=========================================="
echo "Name:         $name"
echo "Race:         $race"
echo "Class:        $class  (d$hit_die hit die)"
echo "Level:        $level"
echo "Hit Points:   $hp"
echo
echo "----- ABILITY SCORES -----"
# For each stat, calculate and display:
#   - The final score (after point-buy and racial bonuses)
#   - The modifier in parentheses, e.g. (+2)
#   - A racial bonus note if one applies
#   - A marker if this is the class's primary stat
for a in STR DEX CON INT WIS CHA; do
  score=${stats[$a]}
  mod=$(modifier_for_score "$score")
  mod_display=$(format_modifier "$mod")
  racial_note=""
  class_note=""

  # Add a note if this stat got a racial bonus.
  if (( racial_bonuses[$a] > 0 )); then
    racial_note="  [+${racial_bonuses[$a]} racial]"
  fi

  # Mark the class's primary stat so the player knows what to prioritize.
  if [[ "$a" == "$primary_stat" ]]; then
    class_note="  <-- primary stat"
  fi

  echo "  $a: $score ($mod_display)$racial_note$class_note"
done
echo
echo "----- CLASS FEATURES -----"
echo "  Saving Throws:  $class_saves"
echo "  Primary Stat:   $primary_stat"
echo "------------------------------------------"
echo "Unspent Points: $points"
echo "=========================================="
echo "This is all it takes to start playing D&D!"


# --- SAVE SYSTEM: Optionally write the character sheet to a text file ---
# We ask first — saving is completely optional.
echo
read -p "Would you like to save this character? (y/n): " save_choice

if [[ "${save_choice,,}" == "y" || "${save_choice,,}" == "yes" ]]; then

  # Build a default filename from the character's name.
  # ${name,,} converts to lowercase. ${var// /_} replaces every space with an underscore.
  # So "Aria Stormwind" becomes "aria_stormwind".
  default_filename="${name,,}"
  default_filename="${default_filename// /_}"

  read -p "Filename (press Enter for '$default_filename.txt'): " chosen_name

  # If the player left it blank, use the default. Strip any .txt the player may have typed
  # so we control the extension ourselves — the character always ends up as a .txt file.
  chosen_name="${chosen_name:-$default_filename}"
  chosen_name="${chosen_name%.txt}"
  save_file="${chosen_name}.txt"

  # Save files go in a 'saves/' folder next to the script.
  # 'dirname' gets the folder the script lives in.
  # 'realpath' turns it into a full absolute path so it works from any directory.
  # 'mkdir -p' creates the folder (and any parent folders) if they don't already exist.
  save_dir="$(dirname "$(realpath "$0")")/saves"
  mkdir -p "$save_dir"
  save_path="$save_dir/$save_file"

  # If a save file with that name already exists, ask before overwriting it.
  if [[ -f "$save_path" ]]; then
    read -p "'$save_file' already exists. Overwrite? (y/n): " overwrite
    if [[ "${overwrite,,}" != "y" && "${overwrite,,}" != "yes" ]]; then
      echo "Save cancelled."
      exit 0
    fi
  fi

  # Write the character sheet to the file.
  # The { ... } block groups all the echo commands together.
  # The '> "$save_path"' at the end redirects ALL of their output into the file at once,
  # which is cleaner than putting '>> file' after every single line.
  {
    echo "=========================================="
    echo "           CHARACTER SHEET"
    echo "=========================================="
    echo "  Name:       $name"
    echo "  Race:       $race"
    echo "  Class:      $class  (d$hit_die hit die)"
    echo "  Level:      $level"
    echo "  Hit Points: $hp"
    echo
    echo "----- ABILITY SCORES -----"
    for a in STR DEX CON INT WIS CHA; do
      score=${stats[$a]}
      mod=$(modifier_for_score "$score")
      mod_display=$(format_modifier "$mod")
      racial_note=""
      class_note=""
      if (( racial_bonuses[$a] > 0 )); then
        racial_note="  [+${racial_bonuses[$a]} racial]"
      fi
      if [[ "$a" == "$primary_stat" ]]; then
        class_note="  <-- primary stat"
      fi
      echo "  $a: $score ($mod_display)$racial_note$class_note"
    done
    echo
    echo "----- CLASS FEATURES -----"
    echo "  Saving Throws:  $class_saves"
    echo "  Primary Stat:   $primary_stat"
    echo "------------------------------------------"
    echo "  Unspent Points: $points"
    echo "=========================================="
    echo "  Saved: $(date)"
    echo "=========================================="
  } > "$save_path"

  echo "Character saved to: $save_path"
fi
