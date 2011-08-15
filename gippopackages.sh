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
# Version 1.2
#

APPS='ccleaner process_explorer antivir virtualbox filezilla hijackthis winscp 7zip_32 spybot_search_destroy notepad'
URL="http://www.filehippo.com"
REPO="/tmp/filehippo-repo"
TMPDIR="/tmp"
KDEPOPUP=1

function fetchSite() {
  techcontent=$TMPDIR/techcontent.txt
  techcontentsource=$TMPDIR/techcontentsource.txt
  techcontentdownload=$TMPDIR/techcontentdownload.txt

  if [ -n $1 ] && [ -w $TMPDIR ]; then 
    cururl="$URL/download_$1/tech"
    w3m -no-cookie -dump "$cururl" > $techcontent
    w3m -no-cookie -dump_source "$cururl" > $techcontentsource
    # Follow the download link
    downloadlink=`grep -A 1 "id=\"dlbox" $techcontentsource | sed -n 's/^<a href="\(.*\)">./\1/p' | sed -e 's/\".*//'`
    w3m -no-cookie -dump_source $cururl$downloadlink > $techcontentdownload

    if [ $? -ne 0 ]; then echo "Failed to load $url" && exit 1; fi;
  else
    echo "Error fetching $1. Check if $TMPDIR is writeable."
  fi
}

function getDetails() {
  if [ -n $1 ]; then fetchSite $1; else exit 1; fi;
  # Get all the details of off filehippo.com
  title=`grep "Title:" $techcontent | awk '{ print $2}'`
  #onfilename=`grep "Filename:" $techcontent | awk '{ print $2}'`
  filename=`grep "Title:" $techcontent | sed -e 's/.*\://' | sed 's/ //g'`
  filenameextension=`grep "Filename:"  $techcontent | sed -e 's/.*\.//'`
  bit=`grep "Title:"  $techcontent | grep "("| sed -e 's/.*(//' | sed -e 's/)//'`
  version=`grep "Title:" $techcontent`
  onmd5=`grep "MD5 Checksum:"  $techcontent | awk '{ print $3 }'`
  downloadlink=`grep "<a id=\"_ctl0_contentMain_lnkURL\" class=\"black\"" $techcontentdownload | sed -e 's/.*href=\"//' | sed -e 's/\".*//'`
  ourfilename=$filename"."$filenameextension
}

function comparemd5() {
  if [ $1 -eq $2 ]; then
    return 1
  else
    return 0
  fi
}




for app in $APPS; do
  getDetails $app

  # Print out the details we've just collected
  echo "----[ Title: $title ]----"
  echo "Filename: $ourfilename"
  echo "Download link: $URL$downloadlink"
  echo "Md5 compare (online/local): $onmd5 / $mymd5"

  # Prelimary checks
  # Create the repo subdirectory if it doesn't exist
  if [ ! -d "$REPO/$title$bit" ]; then
    mkdir "$REPO/$title$bit"
  fi

  # Do we have the file already on the disk if so get the md5sum
  if [ -f "$REPO/$title$bit/$ourfilename" ]; then
    mymd5=`md5sum $REPO/$title$bit/$ourfilename | awk '{ print $1}' | tr [:lower:] [:upper:]`
  else
    mymd5="file does not exist"
  fi


  # Check for new version
  # if online md5 differs from local md5 download new version
  if [ "$onmd5" != "$mymd5" ]; then
    echo "New Version available....downloading"

    if [ $KDEPOPUP = 1 ]; then
	kdialog --title "getmypackages" --passivepopup "New version : $title" 10
    fi

    wget --quiet -O "$REPO/$title$bit/$ourfilename" "$URL$downloadlink"
  else
    if [ ! -f "$REPO/$title$bit/$ourfilename" ]; then
      # we don't have it yet so get it
      if [ $KDEPOPUP = 1 ]; then
	  kdialog --title "getmypackages" --passivepopup "New app : $title" 10
      fi

      wget --quiet -O "$REPO/$title$bit/$ourfilename" "$URL$downloadlink"
    fi
  fi


done

exit 0
