#!/bin/bash
# gippopackages.sh
#
# A simple bash script to get the lastest version
# of your favourite free software from filehippo.com
# simply add the links to the APPS variable and
# seperate them via a white space.
# Don't expect this work when the site changes layout
#
#
# Requirements :
# md5sum, w3m, grep, sed, tr
#
# Author: Frank Lazzarini, Fabien Michel 2011
# Version 1.1
#

APPS='http://www.filehippo.com/download_ccleaner/ http://filehippo.com/download_process_explorer/ http://filehippo.com/download_antivir/ http://filehippo.com/download_hijackthis/ http://filehippo.com/download_spybot_search_destroy/ http://filehippo.com/download_7zip_32/ http://filehippo.com/download_winscp/ http://filehippo.com/download_firebird/ http://filehippo.com/download_notepad/ http://filehippo.com/download_virtualbox/ http://filehippo.com/download_filezilla/'
URL="http://www.filehippo.com"
REPO="/home/frank/upload/filehippo-repo"
KDEPOPUP=1


for app in $APPS; do
  # Get all the details of off filehippo.com
  title=`w3m -no-cookie -dump $app/tech/ | grep "Title:" | awk '{ print $2}'`
  onfilename=`w3m -no-cookie -dump $app/tech/ | grep "Filename:" | awk '{ print $2}'`
  filename=`w3m -no-cookie -dump $app/tech/ | grep "Title:" | sed -e 's/.*\://' | sed 's/ //g'`
  filenameextension=`w3m -no-cookie -dump $app/tech/ | grep "Filename:" | sed -e 's/.*\.//'`
  ourfilename=$filename"."$filenameextension
  bit=`w3m -no-cookie -dump $app/tech/ | grep "Title:" | grep "("| sed -e 's/.*(//' | sed -e 's/)//'`
  version=`w3m -no-cookie -dump $app/tech/ | grep "Title:"`
  downloadlink1=`w3m -no-cookie -dump_source $app/tech/ | grep -A 1 "id=\"dlbox" | sed -n 's/^<a href="\(.*\)">./\1/p' | sed -e 's/\".*//'`
  downloadlink2=`w3m -no-cookie -dump_source $URL$downloadlink1 | grep "<a id=\"_ctl0_contentMain_lnkURL\" class=\"black\"" | sed -e 's/.*href=\"//' | sed -e 's/\".*//'`
  onmd5=`w3m -no-cookie -dump $app/tech/ | grep "MD5 Checksum:" | awk '{ print $3 }'`



  # Prelimary checks
  # Create the repo subdirectory if it doesn't exist
  if [ ! -d "$REPO/$title$bit" ]; then
    mkdir "$REPO/$title$bit"
  fi

  if [ -f "$REPO/$title$bit/$ourfilename" ]; then
    mymd5=`md5sum $REPO/$title$bit/$ourfilename | awk '{ print $1}' | tr [:lower:] [:upper:]`
  else
    mymd5="file does not exist"
  fi


  echo "----[ Title: $title ]----"
  echo "Filename: $onfilename"
  echo "Local Filename: $ourfilename"
  echo "Download link: $URL$downloadlink2"
  echo "Online md5: $onmd5"
  echo "My md5    : $mymd5"


  # Check for new version
  # if online md5 differs from local md5 download new version
  if [ "$onmd5" != "$mymd5" ]; then
    echo "New Version available....downloading"
    if [ $KDEPOPUP = 1 ]; then
	kdialog --title "getmypackages" --passivepopup "New version : $title" 10
    fi

    wget --quiet -O "$REPO/$title$bit/$ourfilename" "$URL$downloadlink2"
  else
    if [ ! -f "$REPO/$title$bit/$ourfilename" ]; then
      # we don't have it yet so get it
      if [ $KDEPOPUP = 1 ]; then
	  kdialog --title "getmypackages" --passivepopup "New app : $title" 10
      fi

      wget --quiet -O "$REPO/$title$bit/$ourfilename" "$URL$downloadlink2"
    fi
  fi

done;
