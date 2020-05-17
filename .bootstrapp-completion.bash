#!/bin/bash
#
# bash completion for bootstrapp
#
# To enable the completions either:
#  - place this file in /etc/bash_completion.d
#  or
#  - copy this file to e.g. ~/.bootstrapp-completion.bash and add the line
#    below to your .bashrc after bash completion features are loaded
#    . ~/.bootstrapp-completion.bash

function _bootstrapp_completion() {
  bootstrapp.sh | tail -n +5 | awk '{print $1}'
}

complete -W "$(_bootstrapp_completion)" bootstrapp.sh
