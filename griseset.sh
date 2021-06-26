#!/bin/bash

# GRiseSet
# by draumaz, 2021
# Gammy automatic sunrise-sunset configurator.

splash="GRiseSet, by draumaz"
config_path="/home/$(whoami)/.config"
conf_path="${config_path}/gammyconf"
grise_conf_path="${config_path}/griseconf"

if [ -z $1 ]
then
	loc_no_arg=1
elif [ "$1" == "--version" ]
then
	echo "v0.04"
	exit
elif [ "$1" == "--path" ]
then
	echo -n "Gammy config --> "
	echo $conf_path
	echo -n "GRiseSet config --> "
	echo $grise_conf_path
	exit
else
	location=$1
	echo "You are about to write '${location}' (supplied from argument) to ${grise_conf_path}. It will be used to configure your sunrise/sunset times."
	sleep 2
	echo $location > $grise_conf_path
fi

echo $splash

if [ ! -e $config_path ]
then
	mkdir $config_path
fi

if [ ! -e $conf_path ]
then
	echo "You need to run Gammy at least once beforehand in order to generate the gammyconf."
       	exit
fi       

if [ -e $grise_conf_path ]
then
	location=$(cat $grise_conf_path)
else
	if [ loc_no_arg == 1 ]
	then
		echo -n "Location code (https://weather.codes): "
		read location
	else
		echo $location > $grise_conf_path
		echo "Written to ${grise_conf_path}."
	fi
fi

a_current_rise=$(cat $conf_path | grep -i "SUNRISE")
b_current_rise=${a_current_rise:21}
current_rise=${b_current_rise::-2}

a_current_set=$(cat $conf_path | grep -i "SUNSET")
b_current_set=${a_current_set:20}
current_set=${b_current_set::-2}

# Retrieve actual rise/set

echo -n "Retrieving local sunrise & sunset..."
tmpfile=/tmp/$location.out
if wget -q "https://weather.com/weather/today/l/$location" -O "$tmpfile"
then
	echo " Retrieved."
else
	echo ""
	echo " Unable to fetch current times. Make sure your internet is conected."
	exit
fi
SUNR=$(grep SunriseSunset "$tmpfile" | grep -oE '((1[0-2]|0?[1-9]):([0-5][0-9]) ?([AaPp][Mm]))' | head -1)
SUNS=$(grep SunriseSunset "$tmpfile" | grep -oE '((1[0-2]|0?[1-9]):([0-5][0-9]) ?([AaPp][Mm]))' | tail -1)
new_rise=$(date --date="$SUNR" +%R):00
new_set=$(date --date="$SUNS" +%R):00

# Set times

if [ "$current_rise" == "$current_set" ] || [ "$new_rise" == "$new_set" ]
then
	echo "Time values are broken. Check your gammyfile and make sure the current times are not broken or null."
	exit
else
	:
fi

if [ "$current_rise" != "$new_rise" ]
then
	echo -n "Writing local sunrise & sunset to config..."
	sed -i "s|$current_rise|$new_rise|g" $conf_path
	sed -i "s|$current_set|$new_set|g" $conf_path
	echo " Done."
else
	echo "Local gammyconf times and retrieved times are identical. Exiting."
fi

exit
