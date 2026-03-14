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

__git_status_counts() {
  local staged=0
  local modified=0
  local untracked=0
  local ahead=0
  local behind=0
  
  # Get git status in porcelain format for parsing
  while IFS= read -r line; do
    local x="${line:0:1}"
    local y="${line:1:1}"
    
    # Staged files (index changes)
    if [[ "$x" =~ [MADRC] ]]; then
      ((staged++))
    fi
    
    # Modified/deleted files (working tree changes)
    if [[ "$y" =~ [MD] ]]; then
      ((modified++))
    fi
    
    # Untracked files
    if [[ "$x" == "?" ]]; then
      ((untracked++))
    fi
  done < <(git status --porcelain 2>/dev/null)
  
  # Get ahead/behind info
  local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  if [ -n "$upstream" ]; then
    local counts=$(git rev-list --left-right --count HEAD...$upstream 2>/dev/null)
    ahead=$(echo "$counts" | cut -f1)
    behind=$(echo "$counts" | cut -f2)
  fi
  
  # Build status string
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
  
  echo -e "$status_str"
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
    
    # Calculate position for right side
    # Save cursor, move to column, print status, restore cursor
    local right_prompt=""
    if [ -n "$git_status_right" ]; then
      # Remove ANSI codes for length calculation
      local status_length=$(echo -e "$git_status_right" | sed 's/\x1b\[[0-9;]*m//g' | wc -m)
      local cols=$(tput cols)
      local position=$((cols - status_length + 1))
      right_prompt="\[\033[s\]\[\033[${position}G\]${git_status_right}\[\033[u\]"
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
