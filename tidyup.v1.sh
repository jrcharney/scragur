#!/bin/bash
# File: tidyup.sh
# Author: Jason Charney (jrcharneyATgmailDOTcom)
# Info: A quick solution for storing a lot of files

images='.*\.(gif|jpeg|jpg|png)'				# images
sounds='.*\.(m3u|mp3|mid|midi|ogg|wav|wma)'		# sounds
videos='.*\.(avi|flv|mkv|mov|mp4|mpg|mpeg|wmv)'		# videos
offdox='.*\.(doc|xls|ppt)x?'				# office documents
# TODO: MORE FILE TYPES SOON.

# Func: usage
usage(){
 cat <<USAGE
$0 - Clean up your folders

USAGE:
 $0
 	Show this usage message
 $0 ARCHIVE_DIRECTORY
 	Archive everything into the ARCHIVE_DIRECTORY
 $0 ARCHIVE_DIRECTORY YEAR
 	Archive anything from a specific YEAR into the ARCHIVE_DIRECTORY
 $0 ARCHIVE_DIRECTORY START_YEAR END_YEAR
 	Archive anything from START_YEAR to END_YEAR into the ARCHIVE_DIRECTORY
 $0 ARCHIVE_DIRECTORY YEAR START_MONTH END_MONTH
 	Archive anything from a specific YEAR from START_MONTH to END_MONTH
	into the ARCHIVE_DIRECTORY
 $0 ARCHIVE_DIRECTORY START_YEAR START_MONTH END_YEAR END_MONTH
 	Archive anything from START_MONTH of START_YEAR to
	END_MONTH of END_YEAR into the ARCHIVE_DIRECTORY

 New features are to follow such as testing and counting files.
 At this time, this program only handles image types.
USAGE
 exit 0
}

# Func: daterange
# Info: Move a set of files within a specific time frame to a folder to be sorted later.
daterange(){
 local fgroup=$images
 local bm=$(date -d "$1/1/$2" +%-m)		# get the beginning month
 local by=$(date -d "$1/1/$2" +%Y)		# get the beginning year
 local fm=$(( bm + 1 ))				# get the finishing month, I could of used (( fm = bm + 1 )) but then fm wouldn't be local
 local fy=$by					# get the finishing year
 [[ $fm -eq 13 ]] && { fm=1; (( fy++ )); }		# if bm was 12 , flip to january of the following year
 local start=$(date -d "$bm/1/$by 0000" +%Y-%m-%d\ %H%M)	# define the beginning date for find
 local finish=$(date -d "$fm/1/$fy 0000" +%Y-%m-%d\ %H%M)	# define the finishing date for find
 local of=$(date -d "$bm/1/$by" +%Y_%m)			# define the output folder that items will be moved to
 local ct=$(find . -maxdepth 1 -type f -regextype posix-extended -iregex $fgroup -newermt "$start" ! -newermt "$finish" -exec ls -1 {} + | wc -l)
 [[ $ct -ne 0 ]] && {
  local op="$3"/$of						# define the path the output folder would be 
  echo "daterange: $op will store $ct files matching the RE '${fgroup}' from $start to $finish"
  [[ ! -d $op ]] && mkdir -p $op				# check to see if the path exists. If it doesn't create it.
  find . -maxdepth 1 -type f -regextype posix-extended -iregex '.*\.(gif|jpeg|jpg|png)' -newermt "$start" ! -newermt "$finish" -exec mv -t ./"$op" {} +
 } || {
  echo "daterange: found no files files matching the RE '${fgroup}' from $start to $finish"
 }

}

# do date range for a specific time period
mdaterange(){
 case $# in
  0) usage ;;
  1) af="$1";	sy=$(date +%Y);	sm=$(date +%-m); ey=$sy; em=$sm 
     daterange $sm $sy $af
     ;;	# af
  2) af="$1";	sy=$2;		sm=1;		 ey=$2;  em=12 
     for (( j = $sm; j <= $em; j++ )); do daterange $j $sy $af; done
     ;;	# af year
  3) af="$1";	sy=$2;		sm=1;		 ey=$3;	 em=12  
     # TODO: Check to make sure $sy -ne $ey
     # TODO: Check to make sure $sy -lt $ey
     for (( i = $sy; i <= $ey; i++ )); do
      for (( j = $sm; j <= $em; j++ )); do daterange $j $i $af; done
     done
     ;;	# af sy ey
  4) af="$1";	sy=$2;		sm=$3;		 ey=$2;  em=$4  
     # TODO: make sure that $sm -ne $em
     # TODO: make sure that $sm -lt $em
     for (( j = $sm; j <= $em; j++ )); do daterange $j $sy $af; done 
     ;;	# af year sm em
  5) af="$1";	sy=$2;		sm=$3;		 ey=$4;  em=$5
     # TODO: Check to make sure $sy -ne $ey
     # TODO: Check to make sure $sy -lt $ey
     for (( i = $sy; i <= $ey; i++ )); do
      if [[ ( $i -eq $sy ) && ( $sm -gt 1 ) ]]; then				# for the first year where $sm -gt 1
       for (( j = $sm; j <= 12; j++ )); do daterange $j $i $af; done
      elif [[ ( $i -eq $ey ) && ( $em -lt 12 ) ]]; then 			# for the last year where $em -lt 12
       for (( j = 1; j <= $em; j++ )); do daterange $j $i $af; done
      else									# any normal year
       for (( j = 1; j <= 12; j++ )); do daterange $j $i $af; done
      fi
     done
     ;;	# af sy sm ey em
  *) echo "Sorry, invalid number of arguments. Aborting."; exit 1 ;;		# TODO: make a usage function
 esac
}

# daterange $1 $2 Archive

mdaterange $@
