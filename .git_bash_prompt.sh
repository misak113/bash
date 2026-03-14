# Bash PS1 for Git repositories showing branch and relative path inside 
# the Repository with git status on the right side

# Reset
RESET="\[\033[0m\]"

# Regular Colors
BLACK="\[\033[0;30m\]"
RED="\[\033[0;31m\]"
GREEN="\[\033[0;32m\]"
YELLOW="\[\033[0;33m\]"
BLUE="\[\033[0;34m\]"
PURPLE="\[\033[0;35m\]"
CYAN="\[\033[0;36m\]"
WHITE="\[\033[0;37m\]"

# Bright Colors
BRIGHT_GREEN="\[\033[1;32m\]"
BRIGHT_RED="\[\033[1;31m\]"
BRIGHT_YELLOW="\[\033[1;33m\]"

# PS1 Prompt variables
#TIME12H="\T"
#TIME12A="\@"
#PATHSHORT="\W"
#PATHFULL="\w"
#NEWLINE="\n"
#JOBS="\j"

__git_relative_dir() {
  local dirname
  if [ -d .git ]; then
    dirname=""
  else
    dirname="$(git rev-parse --show-prefix)"
  fi
  echo "$dirname"
}

__git_root_dir_relative_to_home() {
  local git_root_wd=`git rev-parse --show-toplevel`
  local git_root_relative_to_home_wd="${git_root_wd/$HOME}"
  if [ "${git_root_wd/$HOME}" = "$git_root_wd" ] ; then
    echo "$git_root_wd"
  else
    echo "~${git_root_wd/$HOME}"
  fi
}

__git_remote_uri() {
  local origin_uri=`git config --get remote.origin.url`
  if [ -z "$origin_uri" ] ; then
    echo ""
  else
    echo "($origin_uri)"
  fi
}

__clamp_path() {
  local path="$1"
  local max_len=20
  
  if [ ${#path} -le $max_len ]; then
    echo "$path"
  else
    # Take first 2 chars and last (max_len - 5) chars with "..." in between
    local prefix="${path:0:2}"
    local suffix_len=$((max_len - 5))
    local suffix="${path: -$suffix_len}"
    echo "${prefix}...${suffix}"
  fi
}

__git_status_counts() {
  local staged=0
  local modified=0
  local untracked=0
  local ahead=0
  local behind=0
  
  # Arrays to store file info
  local -a staged_files=()
  local -a modified_files=()
  local -a untracked_files=()
  
  # Get git status in porcelain format for parsing
  while IFS= read -r line; do
    local x="${line:0:1}"
    local y="${line:1:1}"
    local file="${line:3}"
    
    # Handle renames (format: "R  old -> new")
    if [[ "$file" == *" -> "* ]]; then
      file="${file##* -> }"
    fi
    
    local icon=""
    local color=""
    
    # Staged files (index changes)
    if [[ "$x" =~ [MADRC] ]]; then
      ((staged++))
      case "$x" in
        A|?) icon="+" ;;
        D) icon="-" ;;
        M|R|C) icon="~" ;;
      esac
      color="\033[1;32m" # bright green
      staged_files+=("${color}$(__clamp_path "$file") ${icon}\033[0m")
    fi
    
    # Modified/deleted files (working tree changes)
    if [[ "$y" =~ [MD] ]]; then
      ((modified++))
      case "$y" in
        D) icon="-" ;;
        M) icon="~" ;;
      esac
      color="\033[1;33m" # bright yellow
      modified_files+=("${color}$(__clamp_path "$file") ${icon}\033[0m")
    fi
    
    # Untracked files
    if [[ "$x" == "?" ]]; then
      ((untracked++))
      icon="+"
      color="\033[1;31m" # bright red
      untracked_files+=("${color}$(__clamp_path "$file") ${icon}\033[0m")
    fi
  done < <(git status --porcelain 2>/dev/null)
  
  # Get ahead/behind info
  local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  if [ -n "$upstream" ]; then
    local counts=$(git rev-list --left-right --count HEAD...$upstream 2>/dev/null)
    ahead=$(echo "$counts" | cut -f1)
    behind=$(echo "$counts" | cut -f2)
  fi
  
  # Combine all files in order: staged, modified, untracked
  local -a all_files=("${staged_files[@]}" "${modified_files[@]}" "${untracked_files[@]}")
  local total_files=${#all_files[@]}
  
  # Build file list (max 5 lines)
  local file_list=""
  local max_files=5
  local show_files=$total_files
  local show_ellipsis=false
  
  if [ $total_files -gt $max_files ]; then
    show_files=$max_files
    show_ellipsis=true
  fi
  
  # Add ellipsis if needed
  if [ "$show_ellipsis" = true ]; then
    file_list="...\n"
  fi
  
  # Add files (newest/last ones if truncated)
  local start_idx=0
  if [ $total_files -gt $max_files ]; then
    start_idx=$((total_files - max_files))
  fi
  
  for ((i=start_idx; i<total_files && i<start_idx+max_files; i++)); do
    file_list+="${all_files[$i]}\n"
  done
  
  # Build summary status string
  local status_str=""
  
  if [ $ahead -gt 0 ]; then
    status_str+="↑$ahead "
  fi
  
  if [ $behind -gt 0 ]; then
    status_str+="↓$behind "
  fi
  
  if [ $staged -gt 0 ]; then
    status_str+="\033[1;32m●$staged\033[0m "
  fi
  
  if [ $modified -gt 0 ]; then
    status_str+="\033[1;33m●$modified\033[0m "
  fi
  
  if [ $untracked -gt 0 ]; then
    status_str+="\033[1;31m●$untracked\033[0m"
  fi
  
  # Combine file list and status summary
  if [ -n "$file_list" ]; then
    echo -e "${file_list}${status_str}"
  else
    echo -e "$status_str"
  fi
}

# This function generates the prompt, depending on Git's status...
function __git_prompt()
{
#  local pre_prompt="\u@\h"
  local pre_prompt="${YELLOW}\u${RESET}${WHITE}@${CYAN}\h${RESET}"

  git branch &>/dev/null
  if [ "$?" -eq "0" ]; then
    local git_prompt="$(__git_ps1 ' (%s)')"
    local git_root_relative_to_home_wd="$(__git_root_dir_relative_to_home)"
    local post_prompt=" $git_root_relative_to_home_wd/$YELLOW$(__git_relative_dir)$RESET"
    local remote_prompt=" $BLUE$(__git_remote_uri)$RESET"
    local last_prompt=" \n\$ "
    
    # Get git status for right side
    local git_status_right="$(__git_status_counts)"
    
    # Calculate position for right side (multi-line)
    local right_prompt=""
    if [ -n "$git_status_right" ]; then
      local cols=$(tput cols)
      local IFS=$'\n'
      local -a status_lines=($git_status_right)
      local num_lines=${#status_lines[@]}
      local clear_width=30  # Increased to clear icons and file paths
      local clear_rows=100  # Clear many rows to ensure complete cleanup
      
      # Build right-aligned multi-line output
      # Save cursor, move up, clear right side, print lines, restore cursor
      right_prompt="\[\033[s\]"
      
      # Move up to start clearing from way above
      right_prompt+="\[\033[${clear_rows}A\]"
      
      # Clear the right side for many lines
      for ((i=0; i<clear_rows; i++)); do
        local clear_pos=$((cols - clear_width + 1))
        right_prompt+="\[\033[${clear_pos}G\]"
        right_prompt+="\[\033[K\]" # Clear from cursor to end of line
        right_prompt+="\[\033[1B\]"
      done
      
      # Move back to original position
      right_prompt+="\[\033[u\]\[\033[s\]"
      
      # Move up to the first line position for printing status
      if [ $num_lines -gt 1 ]; then
        right_prompt+="\[\033[$((num_lines - 1))A\]"
      fi
      
      # Now print the status lines
      for ((i=0; i<num_lines; i++)); do
        local line="${status_lines[$i]}"
        # Remove ANSI codes for length calculation
        local line_length=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g' | wc -m)
        local position=$((cols - line_length + 1))
        
        right_prompt+="\[\033[${position}G\]${line}"
        
        # Move down to next line (except for the last line)
        if [ $i -lt $((num_lines - 1)) ]; then
          right_prompt+="\[\033[1B\]"
        fi
      done
      right_prompt+="\[\033[u\]"
    fi
    
    git status | grep "nothing to commit" > /dev/null 2>&1
    if [ "$?" -eq "0" ]; then
      # Clean repository, show it in green..
      PS1="${right_prompt}$pre_prompt${GREEN}$git_prompt${RESET}$post_prompt$remote_prompt$last_prompt"
    else
      # Repository dirty, show in red...
      PS1="${right_prompt}$pre_prompt${RED}$git_prompt${RESET}$post_prompt$remote_prompt$last_prompt"
    fi
  # @2 - Prompt when not in GIT repo
  else
    PS1="$pre_prompt \w${RESET}\n\$ "; \
  fi
}

PROMPT_COMMAND=__git_prompt
