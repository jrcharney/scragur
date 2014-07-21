#!/bin/bash
# File: GetImgur.sh
# Author: Jason Charney (jrcharneyATgmailDOTcom)
# Version: 1.2
# WARNING: You MUST install the rar package if you want to create a rar file or cbr file.
# Date: 27 May 2013
# Info: Downloads an ENTIRE Imgur album accorind to its file manifest hidden on the page
#       AND downloads them in the order they appear. JPG and PNG albums will be saved
#       as comic book archives (.cbr) so that you can open them with evince as photo albums.
#	Differences since the last version:
#	* COLOR! (Note: I use Yellow, Bright Green, and Bright Red. I would hope you use a
#		console with a black or dark colored background.)
#	* Find the title of the album. (Unfortuantely, because alot of people use ampersands, 
#		square brackets, and other chars, I'm not sure how I can ammend the title to 
#		the .cbr file without bash thinking it is the start or part of a command.
#	* Replaced most of the echos with printfs (If you need to use both -e and -n
#		in your echo commands, you should probably just use printf.)
#	* RAR is quiet now. (It runs quite fast, so I decided to mute the output except for
#		errors and questions with the -idq switch.)
# TODO: rather than chosing not to zip an album with .gifs, chose not to zip an album with ANIMATED .gifs. The manifest might indcate which are animated.
# TODO: Functions!
# TODO: As an alternative, we could just input the URL and strip it out.
# Requires: wget, sed, gawk, rar or zip

# wget -q -O- url			# Print the file to standard output
# | sed -n '/images      :/p' -		# Find the image array. It's written in javascript
# | awk ...				# get file names and extensions

aurl="http://imgur.com/a/"	#Album URL
iurl="http://i.imgur.com/"	#Image URL

# TODO: Randomly generate a user agent, for now, you are an iPad
ipadua="Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405"

# Func: sp (String Print)
# Info: Shortcut for "printf" for a string
pfs(){
 printf "%s" "${1}"
}

# Func: spn (String Print with new line)
# Info: Shortcut for "printf" for a string ending with a newline
pfsn(){
 printf "%s\n" "${1}" 
}

# Func: xm1 (Exit Message 1)
# Info: A message to use when aborting a program, throws an exit status of 1
xm1(){
 printf "ERROR: %s\n" "${1}"
 exit 1
}

# Func: gp ("getPage")
# Info: Fetch a page and print to standard output (think of it as wget meets cat)
# Args: $1 = $url = URL to
# Features/Improvements:
# * --random-wait (randomize the wait time so you don't piss off the server)
# * -w 20	( set the random wait to randomize the wait time to an extent.)
# * --user-agent (Here we fake being an iPad.) :3
gp(){
 wget -q -O- -w 20 --random-wait --user-agent="${ipadua}" "${1}"
 [[ "$?" != "0" ]] && xm1 "wcat could not fetch ${1}"
}

# Func: gf ("getFile")
# Info: Download the file to a folder
# $1 = The file
# $2 = The folder
getFile(){
 wget -q -w 20 --random-wait --user-agent="${ipadua}" -P "${2}" "${1}"
 [[ "$?" != "0" ]] && xm1 "getFile could not fetch ${1}" 
}

# Func: prompt
# TODO: promptyn
# Info: Ask a question for input. Return a value.
#	Note: if an invalid response is given three times, the program will abort.
# Args: $1 = question
# Returns: $ans
# Usage: answer_variable=$(prompt "Question string?")
# Note: The data in this question will not appear in shell history.
prompt(){
 q="${1}"	# Just to be safe, asign the question to a variable.
 qct=0;
 while true; do
  read -p "${q} " ans						# ask a question and store the answer to a variable
  if [[ $ans ]]; then						# If the answer is not blank
   break							# Break out of the loop
  else								# Otherwise
   (( qct++ ))							# Increase the question count
   if [[ $qct -eq 3 ]]; then					# If asked three times
    echo "Sorry, I didn't get a valid response after three trys. Aborting."
    exit 1
   fi
  fi
 done
 echo "${ans}"			# print the answer
}

# Func: promptyn
# Info: Like prompt, but for yes or no answers.
# CAUTION: Yes answers will result in true being returned whereas No answers will return false.
promptyn(){
 q="${1}"	# Just to be safe, asign the question to a variable.
 qct=0;
 while true; do
  read -p "${q} " yn						# ask a question and store the answer to a variable
  if [[ $yn ]]; then						# If the answer is not blank
   case $yn in
    [Yy]* ) ans=true; break;;
    [Nn]* ) ans=false; break;;
    *)
      (( qct++ ))						# Increase the question count
      if [[ $qct -eq 3 ]]; then					# If asked three times
       echo "Sorry, I didn't get a valid response after three trys. Aborting."
       exit 1
     fi
     ;;
   esac
  else								# Otherwise
   (( qct++ ))							# Increase the question count
   if [[ $qct -eq 3 ]]; then					# If asked three times
    echo "Sorry, I didn't get a valid response after three trys. Aborting."
    exit 1
   fi
  fi
 done
 echo "${ans}"			# print the answer

}

# Func: isAlbumURL
# Info: Return true if $1 begins with 
function isAlbumURL(){ [[ "${1}" =~ http://imgur.com/a/* ]] && true || false ; }

# Func: toAlbumURL
# Info: If a string is not an AlbumURL, make it one.
function toAlbumURL(){
 [[ "${1}" =~ http://imgur.com/a/* ]] && echo "${1}" || echo "http://imgur.com/a/${1}"
}

# Func: toAlbumString
# Info: If a string is an AlbumURL, strip out the URL part and return the album name.
function toAlbumString(){
 [[ "${1}" =~ http://imgur.com/a/* ]] && echo "${1##*/}" || echo "${1}"
}

# Func: getAlbumTitle
# Info: Fetch the title string of the album if there is one.
# Args: $1 = $aurl$album
# TODO: Fetch the title of the gallery. I haven't quite figured out how I should use this considering some galleries have ampersands, hypens, and brackets.
# wget ...	- Fetch the file
# sed ...	- Find the line that has the data-title attribute
# awk ...	- Find the value of the data title
# sed ...	- Return the first line with that value
function getAlbumTitle(){
 url=$(toAlbumURL "${1}")	# Make $1 an AlbumURL if it isn't one
 wget -q -O- "$url" \
 | sed -n "/data\-title/p" \
 | awk 'BEGIN{FS="\""} /data\-title/{printf("%s\n",$6);}' \
 | sed -n "1p"
}

# Func: getAlbumString
# Info: Extract the name of the album from the URL
function getAlbumString(){
 # str=$(toAlbumString "${1}")
 echo "${1##*/}"
}

# Func: usage
# Info: Help message
function usage(){
 echo -e "GetImgur Album downloader\n $0 <album id or url>\n"
 exit 0
}

fg1="\003[1;31m";	# red
fg2="\033[1;32m";	# green
fg3="\033[1;33m";	# yellow
rst="\033[0m";		# reset

if [[ -z $1 ]]; then usage; fi

# TODO: OK, this question won't work, espeically if we've appended the title to the file name.
# TODO: mv album.cbz "album - title.cbz" works, but not sure if it will in shell scripts.

album=$(getAlbumString "${1}")

if [[ -f ${1}.cbz || -d ${1} ]]; then
 echo -e "This archive already exists."
 # TODO: Ask if you would like to overwrite it
 # See http://stackoverflow.com/questions/226703/how-do-i-prompt-for-input-in-a-linux-shell-script 
 try=0	# Something I added. If the user doesn't get it right after three times, just abort.
 while true; do
  read -p "Do you wish to replace this archive?" yn
  case $yn in
   [Yy]* ) 
    if [[ -f ${1}.cbz ]]; then rm ${1}.cbz; fi
    if [[ -d ${1} ]]; then
     rm ${1}/*
     rmdir ${1}
    fi
    break
    ;;
   [Nn]* ) printf "Program aborted.\n"; exit 1 ;;
   *)
    printf "Invalid entry. ";
    ((try++))
    if [[ $try -eq 3 ]]; then
     printf "Program aborted after three tries.\n"
     exit 1
    else
     printf "Please try again.\n"
    fi
    ;;
  esac
 done
 exit 1
fi

album=$1		# assuming that the URL starts with http://imgur.com/a/

aurl="http://imgur.com/a/"	#Album URL
iurl="http://i.imgur.com/"	#Image URL

title=$(getAlbumTitle "${aurl}${album}")

# TODO: Test to see if the link exists.

# In this version, we return the file name and status of a file to see if it is animated or not.
# Normally we can't do this, but imgur though ahead and added a field called "animated" that can tell us that.
printf "Fetching the album manifest from \033[1;33m%s%s\033[0m ... " $aurl $album
# wget ... - get the manifest page
# sed  ... - extract the manifest from the page
# awk  ... - extract the names of the files from the manifest
# $( )     - make it a space separated string
list=$(wget -q -O- $aurl$album |
 sed -n '/images      :/p' - |
 awk 'BEGIN{RS="{";FS=","}
  function gs(f){return gensub(/\".+\":\"(.+)\"/,"\\1","g",f);}
  function gn(f){return gensub(/\".+\":([0-9]+)/,"\\1","g",f);}
  /^\"hash/{printf("%s%s\t%s\n",gs($1),gs($7),gn($8));}' -
);

if [ "$?" = "0" ]; then
 ct=$(echo "$list" | wc -l);		# get the count of the number of items (easier that converting $list to an array, which it is not.)
 printf "${fg2}SUCCESS!${rst} Found ${fg3}%s${rst} items.\n" $ct
else
 printf "${fg1}FAILURE!${rst} Aborting.\n"
 printf "Try visiting ${fg3}%s%s${rst} to see if the album is still there.\n" $aurl $album
 exit 1
fi

i=0;				# initalize counter
gifct=0;			# Count the number of ANIMATED gif files. If there are any, the archiving process won't happen.

IFSB=$IFS			# Back up the IFS variable
IFS=$'\n'			# "array items are separated by newlines"
list=( ${list} )		# "list becomes an array"

for item in ${list[*]}; do
 IFS=$'\t'			# "array items are separated by tabs"
 item=( ${item} )		# Item becomes an array
 IFS=$'\n'			# "array items are separated by newlines"

 ((i++))				# increment counter	(Moved it to before the echo statement so that $? would not return 1 because $i = 1)
 file="${item[0]}"				# get the original file name
 printf "Downloading [%03d/%03d] \033[1;33m%s%s\033[0m..." $i $ct $iurl $file
 wget -q -P $album $iurl$file			# -P will set the directory prefix
 if [ "$?" = "0" ]; then			# if no errors
  ext=${file##*.}				# get the file extension
  ext=${ext,,}					# convert it to lowercase
  # TODO: Eliminate any non alphabetical characters that may be added to the end of files. (i.e. "?1")
  #if [[ $ext =~ gif ]]; then ((gifct++)); fi	# if a file is a increase the count.
  if [[ "${item[1]}" -eq 1 ]]; then ((gifct++)); fi
  fname=$(printf "%03d.%s" $i $ext)		# prepare the new name of the file.
  mv $album/$file $album/$fname			# rename the file sequentially. If there are gaps, it means failures
  printf "\033[1;32mSUCCESS!\033[0m Saved as "
  [[ "${item[1]}" -eq 1 ]] && printf "\033[0;33m%s/%s\033[0m\n" $album $fname || printf "\033[1;33m%s/%s\033[0m\n" $album $fname
 else
  echo -e "\033[1;31mFAILED!\033[0m\n"
 fi
done
IFS=$IFSB		# Restore the IFS variable.

# TODO: Count the number of files in the directory. If it is not equal to $ct, echo "DOWNLOAD FAILED."
printf "\033[1;32mDOWNLOAD COMPLETE!\033[0m\n"
# echo "Number of gifs: $gifct";

# TODO: So as long as none of the files are .gif, put them into .cbr or .cbz file
if [ "$gifct" = "0" ]; then
 printf "Putting everything into a .cbz file..."
 # TODO: Find a way to make rar less verbose.
 # rar a -idq $album.cbr $album			# Save the file as a .cbr. This is a .rar format used for comic books, but also ideal for photo albums.
 zip -q -r $album.cbz $album			# Save the file as a .cbz. Slightly more compressed than .cbr
 if [ "$?" = "0" ]; then
  printf "\033[1;32mDONE!\033[0m Saved as \033[1;33m%s.cbz\033[0m\n" $album
  printf "Deleting \033[1;33m%s\033[0m folder to conserve space..." $album
  rm $album/*					# delete the files
  rmdir $album					# delete the folder
  printf "\033[1;32mDONE!\033[0m\n"
 else
  printf "\033[1;31mFAILED!\033[0m Something happened that shouldn't have happened!\n"
 fi
else
 printf "That's it. I can't put it into a .cbz file because there are %d .gifs in the \033[1;33m%s\033[0m folder.\n" $gifct $album
fi

# [[ -n "$title" ]] && echo "$title" || echo "There is no title."
# TODO: Find a way to use the title in the file name even with special characters in it.
if [[ -n "$title" ]]; then
 # title=$(echo "$title" | sed -r -n 's/[\ ]//g;p')
 echo "$title"
else
 echo "There is no title"
fi
