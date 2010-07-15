#!/bin/bash

operation="$1"
shift
arg2="$1"
shift
arg3="$1"

#port1="$1"
#shift
#port2="$1"
#shift
#port3="$1"
#shift
#port4="$1"
#shift
#port5="$1"
#shift
#port6="$1"
#shift
#port7="$1"
#shift
#port8="$1"
#shift

##### Specific Settings for your NPM config: ###
##### EDIT HERE #####

ip="192.168.0.178"	# input the ip of your NPM here, default ist 192.168.0.178
pw="12345678"		# input the password of your lxb (Admin) User, default ist 12345678


# When talking to the NPM there is kind of a random looking char that belongs to every port
portcode[1]="7"	
portcode[2]="4"
portcode[3]="5"
portcode[4]="2"
portcode[5]="3"
portcode[6]="0"
portcode[7]="1"
portcode[8]="E"


######### CHANGE PORT STATUS #################
if [ "$operation" = "set" ]; then	# if specified that you want to change the status of a port
port=$arg2				# 2nd command line parameter is the port no (allowed: 1-8)

 if [[ $port != 1 && $port != 2 && $port != 3 && $port != 4 && $port != 5 && $port != 6 && $port != 7 && $port != 8 ]]; then	# short check if port is between 1-8 .. very ugly at the moment, to be shortened 
	echo "Error setting Port $port"		# You got a port that does not exist here....
	echo "	Port must be between 1 and 8"
	exit 2
 fi

setto=$arg3				# 3rd command line parameter is what you want to set the port to (on/off)
 if [ "$setto" = "on" ]; then
	setcode="B"				# B is the code to activate a port
	befehl=($setcode"204FFFF0"$port$setcode${portcode["$port"]})	# Put the HEX command toghether
 elif [ "$setto" = "off" ]; then
	setcode="C"				# C is the code to deactivate a port
	befehl=($setcode"204FFFF0"$port$setcode${portcode["$port"]})	# Put the HEX command together 
 else
	echo "Error setting Port $port"	# in case you messed up the syntax
	echo "  Invalid argument \"$setto\""
	exit 2
 fi

(echo -n '5507FFFF123456785A'; sleep 0.2; echo -n "$befehl") | netcat -w1 192.168.0.178 4001 2>&1 1>/dev/null		# netcat the NPM, authenticate (YES, $pw is the password in plain), 
fi
######### END CHANGE PORT STATUS #################




######### DIPLAY PORT STATUS #################
if [ "$operation" = "status" ]; then 	# if you want to see the status of the NPM
port=$arg2				# 2nd command line parameter is the port (allowed: 1-8)

if [[ "$port" = "v" || "$port" = "verbose" || "$port" = "" || $port = 1 || $port = 2 || $port = 3 || $port = 4 || $port = 5 || $port = 6 || $port = 7 || $port = 8 ]]; then	
													# short check if port is between 1-8, "v", "verbose" or empty  .. very ugly at the moment, to be shortened 


	answer="$((echo -n '5507FFFF123456785A'; sleep 0.2; echo -n 'D103FFFFD2') | netcat -w1 192.168.0.178 4001 | less)"	# netcat the NPM, authenticate (YES, $pw is the password in plain), 
																# and send the "give port status command" (D103FFFFD2), and put the answer string in $answer 
	if [ ${#answer} != 22 ]; then												# sometimes we need another try
	answer="$((echo -n '5507FFFF123456785A'; sleep 0.2; echo -n 'D103FFFFD2') | netcat -w1 192.168.0.178 4001 | less)" 
	fi

	if [ ${#answer} != 22 ]; then												# if it still doesn't word, tell the user it doesn't
	echo "Communication to NPM device failed, check IP, Username and Password"
	fi
	#echo $answer 					#debug
	portstatusHEX=${answer:18:2}			#extract interesting chars from answer string (we are interested in the YY: xxxxxxxxxxxxxxxxxxYYxx )
	#echo $portstatusHEX 				#debug
	portstatusBIN_short="$(echo "ibase=16;obase=2;$portstatusHEX" | bc | less)" 	# convert the two HEX chars to binary this gives us the status of the ports in reverse order...
										# ... e.g. 10010001 would be: active ports: 8,5,1; deactivated ports: 7,6,4,3,2
	portstatusBIN=$(printf %08d $portstatusBIN_short)

	#echo $portstatusBIN						# debug
	
	for (( i=${#portstatusBIN}; $i>=0;i-- ))			# we need to reverse the order of the ports
	do
	portstatus=$portstatus${portstatusBIN:$i:1}			# ... will now be 1 to 8 instead of 8 to 1
	done
	
	verb=$arg2							# 3rd command line parameter tells us if the user wants th short or the long version (verbose)
	if [[ "$verb" = "verbose" || "$verb" = "v" ]]; then 		# if no port is given but "verbose" or "v" instead, display port Status in long version
		for i in 1 2 3 4 5 6 7 8
		do
			if [ ${portstatus:($i-1):1} = 1 ]; then		# ok, if the port is switched on (=1) ...
				stattext="on"				# ... give them some text it is ...
			else
				stattext="off"				# ... and if it's switched off, we'll also give them some text
			fi
			echo "Port $i is switched $stattext"		# and of course print the text
		done
		exit
	elif [[ $port = 1 || $port = 2 || $port = 3 || $port = 4 || $port = 5 || $port = 6 || $port = 7 || $port = 8 ]]; then	# short check if port is between 1-8 .. very ugly at the moment, to be shortened 

			if [ ${portstatus:($port-1):1} = 1 ]; then	# if the port the user asked about...
				stattext="on"				# ... is switched on, ...
			else
				stattext="off"				# ... or off ...
			fi
			echo "Port $port is switched $stattext"		# ... tell the about
			exit
	else
		echo $portstatus				# if the user does not want the verbose version, were done
		exit 
	fi
else
	echo "Error setting Port $port"		# You got a port that does not exist here....
	echo "	Port must be numeric and between 1 and 8"
	exit 2
fi
fi
######### END DISPLAY PORT STATUS #################

exit
