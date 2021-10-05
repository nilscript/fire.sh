#!/bin/bash
# fire.sh: Animated fire teriminal screensaver.
# 
# Author: Nils Eriksson
# Email: nils.edvin.eriksson@gmail.com
# Repo: https://github.com/nilscript/fire.sh

WIDTH=0
HEIGHT=0
LENGTH="$((WIDTH * HEIGHT))"

HEATMAP=()
DISPLAY=()

ASCII=" '\`^i\",:;Il!i><~+_-?][}{1)(\|\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@\$"
GRAYSCALE=" .:-=+*#%@"
CHARSET="$GRAYSCALE"
CHARSET_LENGTH="${#CHARSET}"
CHARSET_FIFTH="$((CHARSET_LENGTH / 5))"

setup() {
	stty -echo
	tput smcup
	tput civis
	tput clear
	trap cleanup HUP TERM
	trap resize SIGWINCH
}
 
cleanup() {
	read -t 0.001 && cat </dev/stdin>/dev/null
	tput reset
   	tput rmcup
	tput cnorm
   	stty echo
}

resize() { 
	tmpw="$(tput cols)"
	tmph="$(tput lines)"

	if ((tmpw != WIDTH || tmph != HEIGHT)); then
		WIDTH="$tmpw" 
		HEIGHT="$tmph" 
		LENGTH="$((WIDTH * HEIGHT))"	
	
		# (Re)populate grid with 0
		for ((i=0; i < LENGTH; i++)); do
			HEATMAP["$i"]=0
		done

		# Populating 2 last rows with 9.
		#  One row would be enough but covering 2 of them helps 
		#  preventing a bug where the right bottom corner leaks 
		#  0 instead of 9
		for ((i=LENGTH - 2 * WIDTH; i < LENGTH; i++)); do
			HEATMAP["$i"]="$((CHARSET_LENGTH -1))"
		done
		tput clear
	fi
}

# $src is the source pixel we fetch the heat from
# $dst is the pixel we write to
# $heat has a programmed tendancy to stick around if it is 1. 
#  Otherwise it decays. 
update() { 
	for ((src=0; src < LENGTH; src++)); do
		dst="$((src - WIDTH - RANDOM % 3 - 1))"
		if ((dst >= 0)); then
			heat="${HEATMAP[$src]}"
			heat="$((
				heat == 1 
				? heat - RANDOM %(CHARSET_FIFTH + 1) + 1
				: heat - RANDOM % CHARSET_FIFTH
			))"
   
			heat="$((heat > 0 ? heat : 0))"
			HEATMAP["$dst"]="$heat"
			DISPLAY["$src"]="${CHARSET:$heat:1}"
 		fi
	done 
}

draw() {
	i=0
	for ((y=1; y <= HEIGHT; y++)); do
		for ((x=1; x <= WIDTH; x++)); do
			printf '\e[%d;%dH%s%s' "$y" "$x" "${DISPLAY[$i]}"
			let i+=1
		done
	done
}

main() {
	tput -T "$TERM" sgr0 >/dev/null || return "$?"
	setup
	trap 'break 2' INT
	while REPLY=; do
		read -t 0.001 -n 1 2>/dev/null
		[ -n "$REPLY" ] && break

		resize
		update 
		draw
	done
	cleanup
}

[ "$0" = "$BASH_SOURCE" ] && main "$@"
