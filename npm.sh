#!/bin/sh


##### Specific Settings for your NPM config: ###
##### EDIT HERE #####

ip="192.168.0.178"  # input the ip of your NPM here, default ist 192.168.0.178 -- NOT tested with other IP address, should be working fine
pw="12345678"       # input the password of your lxb (Admin) User, default ist 12345678 -- NOT TESTED WITH OTHER PASSWORD especially not if Password contains non-hex characters
                    # Works with default user "lxb" will probably not work with other user name.

##### STOP EDITING HERE #####

operation="$1"
shift
arg2="$1"
shift
arg3="$1"

# When talking to the NPM there is kind of a random looking char that belongs to every port
portcodes='7452301E'


######### CHANGE PORT STATUS #################
if [ "$operation" = "set" ]; then  # if specified that you want to change the status of a port
	port="$arg2"                   # 2nd command line parameter is the port no (allowed: 1-8)

	if [ "$port" -lt 1 -o "$port" -gt 8 ]; then  # short check if port is between 1-8
		echo "Error setting Port $port"          # You got a port that does not exist here....
		echo "Port must be between 1 and 8"
		exit 2
	fi

	setto="$arg3"  # 3rd command line parameter is what you want to set the port to (on/off)
	if [ "$setto" = "on" ]; then
		setcode="B"  # B is the code to activate a port
	elif [ "$setto" = "off" ]; then
		setcode="C"  # C is the code to deactivate a port
	else
		echo "Error setting Port $port"  # in case you messed up the syntax
		echo "  Invalid argument \"$setto\""
		exit 2
	fi
	befehl="${setcode}204FFFF0$port$setcode$(echo "$portcodes" | cut -b "$port")"  # Put the HEX command toghether

	(echo -n "5507FFFF${pw}5A"; sleep 0.2; echo -n "$befehl") | netcat -w1 "$ip" 4001 2>&1 1>/dev/null  # netcat the NPM, authenticate (YES, $pw is the password in plain)
######### END CHANGE PORT STATUS #################
fi



######### DIPLAY PORT STATUS #################
if [ "$operation" = "status" ]; then   # if you want to see the status of the NPM
	port="$arg2"                       # 2nd command line parameter is the port (allowed: 1-8)

	if [ "$port" = 'v' -o "$port" = 'verbose' -o "$port" = '' ] || [ "$port" -ge 1 -a "$port" -le 8 ]; then
	           # short check if port is between 1-8, "v", "verbose" or empty

		answer="$( (echo -n "5507FFFF${pw}5A"; sleep 0.2; echo -n 'D103FFFFD2') | netcat -w1 "$ip" 4001)"  # netcat the NPM, authenticate (YES, $pw is the password in plain)
                                                                                                         # and send the "give port status command" (D103FFFFD2), and put the answer string in $answer
		if [ "$(expr length "$answer")" -ne 22 ]; then                                                   # sometimes we need another try
			sleep 1
			answer="$( (echo -n "5507FFFF${pw}5A"; sleep 0.2; echo -n 'D103FFFFD2') | netcat -w1 "$ip" 4001)"
		fi

		if [ "$(expr length "$answer")" -ne 22 ]; then                                                   # if it still doesn't word, tell the user it doesn't
			echo "Communication to NPM device failed, check IP, Username and Password"
		fi
		portstatusHEX="$(echo "$answer" | cut -b 19-20)"   # extract interesting chars from answer string (we are interested in the YY: xxxxxxxxxxxxxxxxxxYYxx )
		portstatusBIN="$(echo "$portstatusHEX" | tr a-f A-F | sed -e 's/0/0000/g' -e 's/1/0001/g' -e 's/2/0010/g' -e 's/3/0011/g' -e 's/4/0100/g' -e 's/5/0101/g' -e 's/6/0110/g' -e 's/7/0111/g' -e 's/8/1000/g' -e 's/9/1001/g' -e 's/A/1010/g' -e 's/B/1011/g' -e 's/C/1100/g' -e 's/D/1101/g' -e 's/E/1110/g' -e 's/F/1111/g')"
		# convert the two HEX chars to binary this gives us the status of the ports in reverse order
		# e.g. 10010001 would be: active ports: 8,5,1; deactivated ports: 7,6,4,3,2

		portstatus=''
		for i in 8 7 6 5 4 3 2 1; do
			portstatus="$portstatus$(echo "$portstatusBIN" | cut -b "$i")"
		done
		verb="$arg2"   # 3rd command line parameter tells us if the user wants th short or the long version (verbose)
		if [ "$verb" = 'verbose' -o "$verb" = 'v' ]; then   # if no port is given but "verbose" or "v" instead, display port Status in long version
			for i in 1 2 3 4 5 6 7 8
			do
				if [ "$(echo "$portstatus" | cut -b "$i")" -eq 1 ]; then   # ok, if the port is switched on (=1) ...
					stattext='on'   # ... give them some text it is ...
				else
					stattext='off'  # ... and if it's switched off, we'll also give them some text
				fi
				echo "Port $i is switched $stattext"   # and of course print the text
			done
			exit 0
		elif [ "$port" != '' ] && [ "$port" -ge 1 -a "$port" -le 8 ]; then   # short check if port is between 1-8
			if [ "$(echo "$portstatus" | cut -b "$port")" -eq 1 ]; then   # if the port the user asked about...
				stattext="on"   # ... is switched on, ...
			else
				stattext="off"  # ... or off ...
			fi
			echo "Port $port is switched $stattext"    # ... tell the about
			exit 0
		else
			echo "$portstatus"   # if the user does not want the verbose version, were done
			exit 0
		fi
	else
		echo "Error setting Port $port"   # You got a port that does not exist here....
		echo "Port must be numeric and between 1 and 8"
		exit 2
	fi
fi
######### END DISPLAY PORT STATUS #################



######### SHOW HELP #################
if [ "$operation" = 'help' -o "$operation" = '--help' -o "$operation" = '-h' ]; then
	echo "USAGE: ./npm.sh OPERATION [PARAMETER]"
	echo "Can set the status or report the status of the ports on a npm2000 manageable power device"
	echo "IP address and password of the device are set within the script. Open the script in you favorite editor and edit line 7 (IP address) accordingly. I do NOT recommend to edit the password as it has not been tested with a password other than \"12345678\". Be even more careful with a password that contains non-Hex chars."
	echo ""
	echo "To view the current port status of the npm2000 type:"
	echo "./npm.sh status"
	echo "this will give you the status of all ports in the form: 00100001 with every digit giving the status of the corresponding port 0 means that the port is switched off and 1 means the port is switched on."
	echo "in this case ports 3 and 8 are switched on, ports 1,2,4,5,6 and 7 are switech off."
	echo "Arguments for status reports:"
	echo "./npm.sh staus \$port"
	echo "where \$port is the number of the port you want to know the status of"
	echo "Example:"
	echo "./npm.sh status 5"
	echo "Port 5 is switched off"
	echo "./npm status verbose OR ./npm staus v"
	echo "this will give you the status of all ports in an human readable form:"
	echo "Port 1 is switched off"
	echo "Port 2 is switechd on"
	echo "...."
	echo ""
	echo "To set the status of a port of the npm2000 type:"
	echo "./npm.sh set \$port on/off"
	echo "where \$port is the number of the port you want to set"
	echo "Example:"
	echo "./npm.sh set 4 on"
	echo "this will switch port 4 on, regardless to the status it currently has."
	echo "If setting a port, the npm Script will take about 1.2 seconds to exit. This is due to netcat waiting for a response and timing out after one second. If you know a way to reduce the timeout for netcat please let me know."
	echo "" 
	echo "Script created by Niklas Goerke - wurstundkaese@gmail.com"
	echo "Please report any bugs you may encounter"
fi

######### END SHOW HELP #################
exit 0
