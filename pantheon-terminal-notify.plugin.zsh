#!/usr/bin/env zsh

## setup ##

[[ -o interactive ]] || return #interactive only!
zmodload zsh/datetime || { print "can't load zsh/datetime"; return } # faster than date()
autoload -Uz add-zsh-hook || { print "can't add zsh hook!"; return }

(( ${+pantheon_terminal_notify_threshold} )) || pantheon_terminal_notify_threshold=5 #default 5 seconds


## definitions ##

if ! (type pantheon_terminal_notify_formatted | grep -q 'function'); then
  function pantheon_terminal_notify_formatted {
    ## exit_status, command, elapsed_time
    [ $1 -eq 0 ] && title="Task finished" || title="Task failed"
    pantheon_terminal_notify "$title" "$2"
  }
fi

currentWindowId () {
  xprop -root | awk '/NET_ACTIVE_WINDOW/ { print $5; exit }'
}

pantheon_terminal_notify () {
  notify-send -i utilities-terminal $1 $2
}

## Zsh hooks ##

pantheon_terminal_notify_begin() {
  pantheon_terminal_notify_timestamp=$EPOCHSECONDS
  pantheon_terminal_notify_lastcmd=$1
  pantheon_terminal_notify_windowid=$(currentWindowId)
}

pantheon_terminal_notify_end() {
  didexit=$?
  elapsed=$(( EPOCHSECONDS - pantheon_terminal_notify_timestamp ))
  past_threshold=$(( elapsed >= pantheon_terminal_notify_threshold ))
  if (( pantheon_terminal_notify_timestamp > 0 )) && (( past_threshold )); then
    if [ $(currentWindowId) != "$pantheon_terminal_notify_windowid" ]; then
      print -n "\a"
      pantheon_terminal_notify_formatted "$didexit" "$pantheon_terminal_notify_lastcmd"
    fi
  fi
  pantheon_terminal_notify_timestamp=0 #reset it to 0!
}

add-zsh-hook preexec pantheon_terminal_notify_begin
add-zsh-hook precmd pantheon_terminal_notify_end
