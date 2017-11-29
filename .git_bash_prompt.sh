# Bash PS1 for Git repositories showing branch and relative path inside 
# the Repository

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

# This function generates the prompt, depending on Git's status...
function __git_prompt()
{
#  local pre_prompt="\u@\h"
  local pre_prompt="${YELLOW}\u${RESET}${WHITE}@${PURPLE}\h${RESET}"

  git branch &>/dev/null
  if [ "$?" -eq "0" ]; then
    local git_prompt="$(__git_ps1 ' (%s)')"
    local git_root_relative_to_home_wd="$(__git_root_dir_relative_to_home)"
    local post_prompt=" $git_root_relative_to_home_wd/$YELLOW$(__git_relative_dir)$RESET"
    local remote_prompt=" $BLUE$(__git_remote_uri)$RESET"
    local last_prompt=" \n\$ "
    git status | grep "nothing to commit" > /dev/null 2>&1
    if [ "$?" -eq "0" ]; then
      # Clean repository, show it in green..
      PS1="$pre_prompt${GREEN}$git_prompt${RESET}$post_prompt$remote_prompt$last_prompt"
    else
      # Repository dirty, show in red...
      PS1="$pre_prompt${RED}$git_prompt${RESET}$post_prompt$remote_prompt$last_prompt"
    fi
  # @2 - Prompt when not in GIT repo
  else
    PS1="$pre_prompt \w${RESET}\n\$ "; \
  fi
}

PROMPT_COMMAND=__git_prompt
