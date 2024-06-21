declare-option -hidden str-list buffers_list
declare-option int buffers_count
declare-option int current_buff_index
declare-option str current_buff_name
declare-option bool nav_visible
declare-option bool bounce_enter
declare-option str prev_buff
declare-option str current_buff

hook global WinDisplay .* %{
	set-option global prev_buff %opt{current_buff}
	set-option global current_buff %val{bufname}
}

hook global RawKey <esc> %{
	buffer-nav-close
}

hook global RawKey <ret> %{
	evaluate-commands %sh{
#    		if [ $kak_opt_bounce_enter = true ]; then
#    			printf "set-option global bounce_enter false\n"
		if [ $kak_opt_nav_visible = true ]; then
			printf "buffer $kak_opt_current_buff_name\n"
   			printf "buffer-nav-close\n"
		fi
	}
}
	
hook global RawKey <up> %{
	evaluate-commands %sh{
		if [ $kak_opt_nav_visible = true ]; then
			newInd=$((kak_opt_current_buff_index - 1))
			if [ $newInd -lt 1 ]; then
				newInd=1
			elif [ $newInd -gt $kak_opt_buffers_count ]; then
				newInd=$kak_opt_buffers_count
			fi
			printf "set-option global current_buff_index $newInd\n"
			printf "buffer-nav-show\n"
		fi
	}
}

hook global RawKey <down> %{
	evaluate-commands %sh{
    		if [ $kak_opt_nav_visible = true ]; then
			newInd=$((kak_opt_current_buff_index + 1))
			if [ $newInd -lt 0 ]; then
				newInd=0
			elif [ $newInd -gt $kak_opt_buffers_count ]; then
				newInd=$kak_opt_buffers_count
			fi
			printf "set-option global current_buff_index $newInd\n"
			printf "buffer-nav-show\n"
		fi
	}
}

define-command -hidden refresh-buffers-list %{
	set-option global buffers_list
	set-option global buffers_count 0

	evaluate-commands -no-hooks -buffer * %{
		set-option -add global buffers_list "%val{bufname}|_|%val{modified}"
	}

	evaluate-commands %sh{
		total=$(printf '%s\n' "$kak_opt_buffers_list" | tr ' ' '\n' | wc -l)
		printf "set-option global buffers_count $total"
	}
}

define-command buffer-nav-close %{
	evaluate-commands %sh{
		printf "info -style modal"
	}
	set-option global nav_visible false
}

define-command -hidden buffer-nav-show %{
	evaluate-commands %sh{
		index=0

		menu="Press arrows <up> and <down> to navigate:  \n\n"
		eval "set -- $kak_quoted_opt_buffers_list"
		while [ "$1" ]; do
        		index=$((index + 1))
			menu="$menu "

			name=${1%|_|*}
			if [ "$index" = "$kak_opt_current_buff_index" ]; then
				menu="${menu} > "
				printf "set-option global current_buff_name $name\n"
			fi

			if [ "$name" = "$kak_bufname" ]; then
				menu="${menu} [*]"
			elif [ "$name" = "$kak_opt_prev_buff" ]; then
				menu="${menu} [#]"
			else
				menu="${menu} [ ]"
			fi
 
			menu="$menu $name\n"

			#   modified=${1##*_}
			#   if [ "$modified" = true ]; then
			#     printf '+ '
			#   else
			#     printf '  '
			#   fi

			#   if [ "$index" -lt 10 ]; then
			#     echo "0$index - $name"
			#   else
			#     echo "$index - $name"
			#   fi
			shift
		done

		printf "info -style modal -title 'Opened buffers: $kak_opt_buffers_count' %%^"
		echo $menu
		printf ^\\n
	}
}

define-command buffer-nav -docstring 'Navigate between buffers' %{
	refresh-buffers-list

	evaluate-commands %sh{
		index=0
		current=0

		eval "set -- $kak_quoted_opt_buffers_list"
		while [ "$1" ]; do
			index=$((index + 1))
			name=${1%|_|*}
			if [ "$name" = "$kak_bufname" ]; then
				current=$index 
			fi
			shift
		done
		printf "set-option global current_buff_index $current\n"
	}

	set-option global nav_visible true
	set-option global bounce_enter true
	buffer-nav-show
}

declare-option -docstring 'Splash screen: frame color' str splash_frame rgb:dfdedb
declare-option -docstring 'Splash screen: K body color' str splash_k_body rgb:637486
declare-option -docstring 'Splash screen: K leg color' str splash_k_leg rgb:435a6c
declare-option -docstring 'Splash screen: phonetics foreground' str splash_phon_fg rgb:ffffff
declare-option -docstring 'Splash screen: phonetics background' str splash_phon_bg rgb:b38059
declare-option -docstring 'Splash screen: faded font color' str splash_faded rgb:8a8986

define-command -hidden buff-nav-show  %{
    echo "HERE!!!"
    evaluate-commands -save-regs S %{
		# Fill register with content
		set-register S \
"┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│   ███ ██                                                            │
│   █████                                                             │
│   █████                                                             │
│   █████ A K O U N E                          /kə'kuːn/             │
│                                                                       │
│                                                                       │
│                                                                       │
│                                                                       │
│                                                                       │
│   Edit empty buffer                             i                     │
│   Open a file                                   :e <space>            │
│   Read help                                     :doc <space>          │
│   Quit                                          :q <enter>            │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘"
		# Paste content into buffer
		execute-keys <esc><esc> <percent> <">S R

		# Colorize frame
		add-highlighter window/borders regex "[─│┌┐└┘├┤┬┴┼]" \
			"0:%opt(splash_frame)"

		# Colorize logo
		add-highlighter window/logo_1 regex "███ ██" \
			"0:%opt(splash_k_body)"
		add-highlighter window/logo_2 regex "█████" \
			"0:%opt(splash_k_body)"
		add-highlighter window/logo_3 regex "(█████)()" \
			"1:%opt(splash_k_body),%opt(splash_k_leg)+g" "2:%opt(splash_k_leg)"
		add-highlighter window/logo_4 regex "(████)(█)" \
			"1:%opt(splash_k_body)" "2:%opt(splash_k_leg)"
		add-highlighter window/logo_5 regex "A K O U N E" \
			0:default,+b

		# Colorize phonetic string
		add-highlighter window/phon regex "/kə'kuːn/" \
			"0:%opt(splash_phon_fg),%opt(splash_phon_bg)+b"

		# Colorize text elements
		add-highlighter window/edit regex '^ *│ *(Edit empty buffer) + (i)' \
			"1:%opt(splash_faded)" 2:default,+b "3:%opt(splash_faded)"
		add-highlighter window/open regex '^ *│ *(Open a file) + (:e) (<space>)' \
			"1:%opt(splash_faded)" 2:default,+b "3:%opt(splash_faded)"
		add-highlighter window/help regex '^ *│ *(Read help) + (:doc) (<space>)' \
			"1:%opt(splash_faded)" 2:default,+b "3:%opt(splash_faded)"
		add-highlighter window/quit regex '^ *│ *(Quit) + (:q) (<enter>)' \
			"1:%opt(splash_faded)" 2:default,+b "3:%opt(splash_faded)"
	}

	# remove the uggly cursor. We'll add it back later
	face buffer PrimaryCursorEol Default

	# center the thingy hook
	hook -group splash-center buffer WinResize .* %{
		evaluate-commands %sh{
			# press a key and remove the splash if the screen is to small
			if [ "75" -gt "$kak_window_width" ]; then
				printf "%s\n" "execute-keys -with-hooks %{h}"
				exit
			fi
			if [ "17" -gt "$kak_window_height" ]; then
				printf "%s\n" "execute-keys -with-hooks %{h}"
				exit
			fi
		
			# clear previous indent
			# this may fail if their is no previous indent so its in a
			# try block
			printf "%s\n" "try %{execute-keys %{%s^ +<ret>d}}"
			# clear previous empty lines. just like the other one this can fail
			printf "%s\n" "try %{execute-keys %{%s^$<ret>d}}"
			# 71 is the width of the splash (i believe)
			# four is the width of gutter + line numbers (most of the time)
			printf "%s\n" "execute-keys %{%<a-s>i$(
				printf %$((
					(kak_window_width - 71 - 4) / 2
				))s
			)<esc>}"
			# 16 is the heigth of the splash
			# one is for the status line
			printf "%s\n" "execute-keys %{ggi$(
				printf %$((
					(kak_window_height - 16 - 1) / 2
				))s | tr ' ' '\n';
				printf %s '<esc>'
			)}"
			# put a few lines at the end to make sure that
			# the line numbers continue in a pretty way
			# this doesn't really mather so we add a few extra
			# to comensate for any integer roundings
			printf "%s\n" "execute-keys %{gei$(
				printf %$((
					(kak_window_height - 17 + 10) / 2
				))s | tr ' ' '\n';
				printf %s '<esc>gg'
			)}"
		}
	}

	# don't place the cursor on the splash
	# this can't be done in the hook above as
	# win resize is executed in a draft context
	hook -group splash-center buffer NormalIdle .* %{
		execute-keys "gg"
	}

	# if the user pressed a key we shouldn't mess with it
	# But if the user is typing a command we may as well
	# display the splash a litle longer
	hook -group splash-center buffer NormalKey [^:]* %{
		remove-hooks buffer splash-center
		# show the cursor again
		face buffer PrimaryCursorEol PrimaryCursorEol
		# clear the buffer
		execute-keys -draft %{%d}

		# remove all highlighters used to color the thing
		remove-highlighter window/borders
		remove-highlighter window/logo_1
		remove-highlighter window/logo_2
		remove-highlighter window/logo_3
		remove-highlighter window/logo_4
		remove-highlighter window/logo_5
		remove-highlighter window/phon
		remove-highlighter window/edit
		remove-highlighter window/open
		remove-highlighter window/help
		remove-highlighter window/quit
	}
}

