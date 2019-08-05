#!/bin/bash

# This script was made in order to block all the Youtube's advertisement in Pi-Hole

YTADSBLOCKER_VERSION="2.2"
YTADSBLOCKER_LOG="/var/log/ytadsblocker.log"
YTADSBLOCKER_GIT="https://raw.githubusercontent.com/deividgdt/ytadsblocker/master/ytadsblocker.sh"
VERSIONCHECKER_TIME="260"
SLEEPTIME="240"
DIR_LOG="/var/log"
PI_LOG="/var/log/pihole.log"
BLACKLST="/etc/pihole/blacklist.txt"
BLACKLST_BKP="/etc/pihole/blacklist.txt.BKP"
SERVICE_PATH="/lib/systemd/system"
SERVICE_NAME="ytadsblocker.service"
SCRIPT_NAME=$(basename $0)
PRINTWD=$(pwd)

# The followings vars are used in order to give some color to
# the different outputs of the script.
COLOR_R="\e[31m"
COLOR_Y="\e[33m"
COLOR_G="\e[32m"
COLOR_CL="\e[0m"

# The followings vars are used to point out the different 
# results of the process executed by the script
TAGINFO=$(echo -e "[i]") # [i] Information
TAGWARN=$(echo -e "[${COLOR_Y}w${COLOR_CL}]") # [w] Warning
TAGERR=$(echo -e "[${COLOR_R}✗${COLOR_CL}]") # [✗] Error
TAGOK=$(echo -e "[${COLOR_G}✓${COLOR_CL}]") # [✓] Ok

#If any command shows out an error code, the script ends
set -e

function Makeservice () {

	cd $SERVICE_PATH && touch $SERVICE_NAME
	cat > $SERVICE_NAME <<-EOF
[Unit]
Description=Youtube ads blocker service for Pi-hole
After=network.target

[Service]
ExecStart=$PRINTWD/$SCRIPT_NAME start
ExecStop=$PRINTWD/$SCRIPT_NAME stop

[Install]
WantedBy=multi-user.target
	EOF

}

function Install() {

	if [ ! -f $SERVICE_PATH/$SERVICE_NAME ]; then
		echo -e "${COLOR_R}__  ______  __  __________  ______  ______   ___    ____  _____"
		echo -e "\ \/ / __ \/ / / /_  __/ / / / __ )/ ____/  /   |  / __ \/ ___/"
		echo -e " \  / / / / / / / / / / / / / __  / __/    / /| | / / / /\__ \ "
		echo -e " / / /_/ / /_/ / / / / /_/ / /_/ / /___   / ___ |/ /_/ /___/ / "
		echo -e "/_/\____/\____/ ____ \______________________  |_/_____//____/"  
		echo -e "	   / __ )/ /   / __ \/ ____/ //_// ____/ __ \ "                 
		echo -e "	  / __  / /   / / / / /   / ,<  / __/ / /_/ / "                 
		echo -e "	 / /_/ / /___/ /_/ / /___/ /| |/ /___/ _, _/ "                  
		echo -e "	/_____/_____/\____/\____/_/ |_/_____/_/ |_| v${YTADSBLOCKER_VERSION}${COLOR_CL} by @deividgdt"   
		echo ""
		echo -e "${TAGINFO} Youtube Ads Blocker: INSTALLING..."; sleep 1
		echo -e "${TAGINFO} If you move the script to a different place, please run it again with the option 'install'";
		echo -e "${TAGINFO} You can check the logs in: $YTADSBLOCKER_LOG";
		echo -e "${TAGINFO} All the subdomains will be added to: $BLACKLST";
		echo -e "${TAGINFO} Every ${SLEEPTIME}s it reads: $PI_LOG"; sleep 3
		echo ""
		
		echo -ne "${TAGINFO} Installing the service..."; sleep 1
		Makeservice
		echo "OK. Service installed.";

		echo -ne "${TAGINFO} Enabling the service to start it automatically with the OS."; sleep 1
		systemctl enable ytadsblocker 1> /dev/null 2>&1
		echo "OK."

		echo -e "${TAGINFO} Searching googlevideo.com subdomains inside the Pi-Hole's logs..."; sleep 1    
		
		cp $DIR_LOG/pihole.log* /tmp
		for GZIPFILE in $(ls /tmp/pihole.log*gz > /dev/null 2>&1); do 
			gunzip $GZIPFILE; 
		done
		
		if [ -f "${BLACKLST}" ]; then
			echo -ne "${TAGINFO} Backing up the ${BLACKLST} file..."; sleep 1
			cp $BLACKLST $BLACKLST_BKP
			echo "OK. Backup done."
		else
			echo -ne "${TAGINFO} Creating the ${BLACKLST} file..."; sleep 1
			touch $BLACKLST
			echo "OK. File created."
		fi
		
		echo -e "${TAGINFO} Adding googlevideo.com subdomains..."; sleep 1
		ALL_DOMAINS=$(cat /tmp/pihole.log* | egrep --only-matching "r([0-9]{1,2})[^-].*\.googlevideo\.com" | sort | uniq)
		
		if [ ! -z "${ALL_DOMAINS}" ]; then
			for YTD in $ALL_DOMAINS; do
				echo "[$(date "+%F %T")] New subdomain to add: $YTD" >> $YTADSBLOCKER_LOG 
			done

			pihole -b $ALL_DOMAINS

			N_DOM=$(cat /tmp/pihole.log* | egrep --only-matching "r([0-9]{1,2})[^-].*\.googlevideo\.com" | sort | uniq | wc --lines)
			sudo pihole -g
			echo -e "${TAGOK} OK. $N_DOM subdomains added"
		else
			echo -e "${TAGWARN} No subdomains to add at the moment."
		fi
		
		echo -ne "${TAGINFO} Deleting temp..."; sleep 1
		rm --force /tmp/pihole.log*
		echo "OK. Temp deleted."; sleep 1
		echo -e "${TAGOK} Youtube Ads Blocker: INSTALLED..."; sleep 1
		echo ""
		echo -e "${TAGINFO} To start the service execute as follows: systemctl start ytadsblocker"; sleep 1

	else
		echo -e "${TAGWARN} Youtube Ads Blocker already installed..."; sleep 1
		echo -ne "${TAGINFO} Reinstalling the service..."; 
		Makeservice
		systemctl daemon-reload
		echo "OK. Reinstalled."
	fi

}

function Start() {
	
	echo "Youtube Ads Blocker Started"
	echo "Check the $YTADSBLOCKER_LOG file in order to get further information."

	echo "[$(date "+%F %T")] Youtube Ads Blocker Started" >> $YTADSBLOCKER_LOG

	while true; do
		
		echo "[$(date "+%F %T")] Checking..." >> $YTADSBLOCKER_LOG
		
		YT_DOMAINS=$(cat /var/log/pihole.log | egrep --only-matching "r([0-9]{1,2})[^-].*\.googlevideo\.com" | sort | uniq)
		CURRENT_DOMAINS=$(cat $BLACKLST)
		NEW_DOMAINS=
		
		for YTD in $YT_DOMAINS; do
			if [[ ! $( grep "$YTD" "$BLACKLST" ) ]]; then
				NEW_DOMAINS="$NEW_DOMAINS $YTD"
				echo "[$(date "+%F %T")] New subdomain to add: $YTD" >> $YTADSBLOCKER_LOG
			fi
		done
		
		if [ -z $NEW_DOMAINS ]; then
			echo "[$(date "+%F %T")] No new subdomains to added." >> $YTADSBLOCKER_LOG
		else
			pihole -b $NEW_DOMAINS
			echo "[$(date "+%F %T")] All the new subdomains added." >> $YTADSBLOCKER_LOG
		fi
		
		COUNT=$(($COUNT + 1))
		sleep $SLEEPTIME;

		if [[ $COUNT -eq ${VERSIONCHECKER_TIME} ]]; then
			VersionChecker
			COUNT=0
		else
			continue;
		fi
	done

}

function Stop() {

	echo "Youtube Ads Blocker Stopped"
	echo "[$(date "+%F %T")] Youtube Ads Blocker Stopped" >> $YTADSBLOCKER_LOG
	kill -9 `pgrep ytadsblocker`

}

function Uninstall() {

	echo "Uninstalling..."
	systemctl disable ytadsblocker
	rm -f ${SERVICE_PATH}/${SERVICE_NAME}
	rm -f ${YTADSBLOCKER_LOG}
	egrep -v "r([0-9]{1,2})[^-].*\.googlevideo\.com" ${BLACKLST} > ${BLACKLST}.new
	mv -f ${BLACKLST}.new ${BLACKLST}
	pihole -g
	echo "YouTube Ads Blocker Uninstalled"
	kill -9 `pgrep ytadsblocker`
	

}

function VersionChecker() {

	NEW_VERSION=$(curl --http1.0 --silent $YTADSBLOCKER_GIT | egrep --line-regexp "YTADSBLOCKER_VERSION=\"[1-9]{1,2}\.[1-9]{1,2}\"" | cut --fields=2 --delimiter="=" | sed 's,",,g')

	echo "[$(date "+%F %T")] Checking if there is any new version." >> $YTADSBLOCKER_LOG

	if [[ "${YTADSBLOCKER_VERSION}" != "${NEW_VERSION}" ]]; then
		echo "[$(date "+%F %T")] There is a new version: ${NEW_VERSION}. Current version: ${YTADSBLOCKER_VERSION}" >> $YTADSBLOCKER_LOG
		echo "[$(date "+%F %T")] It will proceed to download it." >> $YTADSBLOCKER_LOG
		curl --http1.0 --silent $YTADSBLOCKER_GIT > /tmp/${SCRIPT_NAME}.${NEW_VERSION}
		echo "[$(date "+%F %T")] New version downloaded. You can find the new script at /tmp." >> $YTADSBLOCKER_LOG
	else
		echo "[$(date "+%F %T")] Nothing to do." >> $YTADSBLOCKER_LOG
	fi
}

case "$1" in
	"install"   ) Install 	;;
	"start"     ) Start 	;;
	"stop"      ) Stop 		;;
	"uninstall" ) Uninstall ;;
	*           ) echo "That option does not exists. Usage: ./$SCRIPT_NAME [ install | start | stop | uninstall ]";;
esac
