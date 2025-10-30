#!/bin/bash

clear
echo "Welcome to the D&D Character Creator!"
echo "Let's build your hero."
echo

#-INPUT SECTION
read -p "What is your character's name? " name
read -p "Choose a race (Human, Elf, Dwarf, Gnome, or Dragonborn): " race
read -p "Choose a class (Wizard, Fighter, Rogue, Bard, Cleric, Barbarian or Sorcerer): " class
read -p "Enter your character's level [Default is 1]: " level
level=${level:-1}
#Points array
points=27
declare -A stats=( ["STR"]=8 ["DEX"]=8 ["CON"]=8 ["INT"]=8 ["WIS"]=8 ["CHA"]=8 )

#cost calculator
cost_for_score() {
  local score=$1
  case $score in
    8) echo 0 ;;
    9) echo 1 ;;
    10) echo 2 ;;
    11) echo 3 ;;
    12) echo 4 ;;
    13) echo 5 ;;
    14) echo 7 ;;
    15) echo 9 ;;
    *) echo -1 ;; # invalid
  esac
}


for ability in STR DEX CON INT WIS CHA; do
  while true; do
    clear
    echo "Assigning points for: $ability"
    echo "----------------------------------"
    echo "Current ability scores:"
    for a in STR DEX CON INT WIS CHA; do
      echo "  $a: ${stats[$a]}"
    done
    echo "----------------------------------"
    echo "Remaining points: $points"
    echo "(Scores range from 8 to 15)"
    echo

    read -p "Enter desired $ability score: You only get one chance! " new_score


    if ! [[ $new_score =~ ^[0-9]+$ ]]; then
      echo "Please enter a number between 8 and 15."
      sleep 1
      continue
    fi


    if (( new_score < 8 || new_score > 15 )); then
      echo "Score must be between 8 and 15."
      sleep 1
      continue
    fi

    base_score=${stats[$ability]}
    base_cost=$(cost_for_score "$base_score")
    new_cost=$(cost_for_score "$new_score")

    if (( new_cost == -1 )); then
      echo "Invalid score."
      sleep 1
      continue
    fi

    cost_diff=$(( new_cost - base_cost ))

    if (( cost_diff > points )); then
      echo "Not enough points! You have $points left."
      sleep 1
      continue
    fi

    stats[$ability]=$new_score
    points=$(( points - cost_diff ))

    break
  done
done

# --- OUTPUT SECTION ---
clear
echo "=========================================="
echo "           🧾 CHARACTER SHEET"
echo "=========================================="
echo "Name:         $name"
echo "Race:         $race"
echo "Class:        $class"
echo "Level:        $level"
echo
echo "----- ABILITY SCORES -----"
for a in STR DEX CON INT WIS CHA; do
  echo "$a: ${stats[$a]}"
done
echo "------------------------------------------"
echo "Remaining Points: $points"
echo "=========================================="

echo "This is all it takes to start playing D&D!"
