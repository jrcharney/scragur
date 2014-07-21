#!/bin/bash
# File: getimgur.sh
# Version: 2.0
# Author: Jason Charney (jrcharneyATgmailDOTcom)
# WARNING: You MUST install the zip package if you want to create a zip file or cbz file.
# Date: 25 July 2013
# Info: Downloads an ENTIRE Imgur album accorind to its file manifest hidden on the page
#       AND downloads them in the order they appear. JPG and PNG albums will be saved
#       as compressed comic book archives (.cbz) so that you can open them with evince as photo albums.
#	Differences since the last version:
#	* Starting over from scratch. I kinda goofed up version 1 while making improvements.
#	* Zip is now the prefered method of compression
#	* Prompts! Request a set of images using the URL or Album name. Requests will not appear in bash history.
#	* Functions. Modular design will now ensure that I don't f*ck up this time.
#	* Better wget usage. Incase the mods at Imgur think scripts like these are web scrapers, they will think you are an iPad user.
# TODO: rather than chosing not to zip an album with .gifs, chose not to zip an album with ANIMATED .gifs. The manifest might indcate which are animated.
# TODO: As an alternative, we could just input the URL and strip it out.
# UPDATE: Removed the more clunky inline functions

# ----- DECLARED GLOBAL VARIABLES -----

fg1="\x1b[1;31m";	# red
fg2="\x1b[1;32m";	# green
fg3="\x1b[1;33m";	# yellow
fg4="\x1b[0;33m";
rst="\x1b[0m";		# reset

# TODO: Randomly generate a user agent, for now, you are an iPad
# TODO: Grab a user agent from http://www.useragentstring.com/
ipadua="Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405"

# ----- INLINE FUNCTIONS ----

# Func: isAlbumURL
# Info: Return true if $1 begins with the Album URL prefix
isAlbumURL(){
 [[ "${1}" =~ http://imgur.com/a/* ]] && true || false
}

# Func: toAlbumURL
# Info: If a string is not an AlbumURL, make it one.
toAlbumURL(){
 [[ "${1}" =~ http://imgur.com/a/* ]] && echo "${1}" || echo "http://imgur.com/a/${1}"
}

# Func: toAlbumString
# Info: If a string is an AlbumURL, strip out the URL part and return the album name.
toAlbumString(){
 [[ "${1}" =~ http://imgur.com/a/* ]] && echo "${1##*/}" || echo "${1}"
}

# Func: isImageURL
isImageURL(){
 [[ "${1}" =~ http://i.imgur.com/* ]] && true || false
}

# Func: toImageURL
# Info: If a string is not an ImageURL, make it one.
toImageURL(){
 [[ "${1}" =~ http://i.imgur.com/* ]] && echo "${1}" || echo "http://i.imgur.com/${1}"
}

# Func: toImageString
# Info: If a string is an ImageURL, strip out the URL part and return the image name.
toImageString(){
 [[ "${1}" =~ http://i.imgur.com/* ]] && echo "${1##*/}" || echo "${1}"
}

# Func: getImageExt
# Info: get the file extension and make it look pretty
# Args: "${1}" is a file name, not a URL
getImageExt(){
   local file=$(toImageString "${1}")			# Make sure that file is a file not a URL
   local ext=${file##*.}				# get the file extension
   echo "${ext,,}"					# convert it to lowercase and return it
}

# ---- BLOCK FUNCTIONS ----

# Func: usage
usage(){
 cat <<USAGE
$0 - Fetch whole galleries from Imgur.com and save them as Comic Book Archives (.cbz)

WHY USE THIS?
* Sometimes Imgur will state it can't download some galleries due to some error.
	This program grabs all the images from the gallery with no strings attached.
* Imgur's archives are always ZIP files.
	This program does one better and saves them as CBZ files that you can browse
	like a photo album using a program for reading comic book files.
	I recommend using Evince since it can read CBZ, CBRs, PDFs, just about anything.
* Imgur names file names randomly even if they are supposed to be in a sequence.
	This program downloads files in the order the were meant to be in by renaming
	them with sequentially numbered names. WYSIWYG!
* Downloads are discrete.
	Run this program to download whole galleries without it showing up in browser
	or console history.

This program isn't perfect though...
* Galleries with animated GIFS won't be compressed into CBZ files.
	They will be saved into the gallery's download folder.
* I haven't run into any gallery that had corrupted images yet...so if anyone does
	let me know so that I can tweak this to do something like retry downloading
	the file or skipping it.

Have fun with this script!
USAGE
 exit 0
}

# Func: gp ("getPage")
# Info: Fetch a page and print to standard output (think of it as wget meets cat)
# Args: $1 = $url = URL to
# Features/Improvements:
# * --random-wait (randomize the wait time so you don't piss off the server)
# * -w 20	( set the random wait to randomize the wait time to an extent.)
# * --user-agent (Here we fake being an iPad.) :3
# NOTE: This function does not get the contents from files, but the page that the contents are located.
#       If you want to get something from a file, try gf.
gp(){
 wget -q -O- -w 20 --random-wait --user-agent="${ipadua}" "${1}"
 [[ "$?" != "0" ]] && { printf "ERROR: gp could not fetch %s\n" "${1}"; exit 1; }
}

# Func: gf ("getFile")
# Info: Download the file to a folder
# $1 = The file
# $2 = The folder
# TODO: should I use -O instead of -P?
# NOTE: -P's default value is ".", that is the current directory.
#	For getimgur, we use -P to create a directory.
# gf(){
#  wget -q -w 20 --random-wait --user-agent="${ipadua}" -P "${2}" "${1}"
#  [[ "$?" != "0" ]] && { printf "ERROR: gf could not fetch %s\n" "${1}"; exit 1; }
# }

# $1 = The file to get
# $2 = The name to save it as (with path if necessary)
# TODO TODO TODO WARNING! THIS NEW VERSION OF THIS FUNCTION IS EXPERIMENTAL! TODO TODO TODO
gf(){
 case "$#" in
  0) printf "ERROR: gf needs at least one argument to work."; exit 1;;
  1) # Download the file in the current directory
     wget -q -w 20 --random-wait --user-agent="${ipadua}" "${1}"
     [[ "$?" != "0" ]] && { printf "ERROR: gf could not fetch %s\n" "${1}"; exit 1; }
     ;;
  2) # Put the file at a specified location with a specific name
     local pn=${2%/*}	# The path of the new file
     local fn=${2##*/}	# The file name of the new file
     [[ "${pn}" == "${fn}" ]] && pn="."			# if $pn is the same as $fn, use the current directory
     [[ ! -d "${pn}" ]] && mkdir -p "${pn}"		# if any of the folders in $pn do not exist, define them
     wget -q -w 20 --random-wait --user-agent="${ipadua}" -O "${pn}"/"${fn}" "${1}"
     [[ "$?" != "0" ]] && { printf "ERROR: gf could not fetch %s\n" "${1}"; exit 1; }
     ;;
  *) printf "ERROR: gf can't handle more than two arguments...yet."; exit 1;;
 esac
}

# Func: gf2 (getFile 2)
# Info: In this version, do not throw an exit whenever there is failure.
# $1 = The file to get
# $2 = The name to save it as (with path if necessary)
# $3 = ${row[1]} = the status of a gif if it is animated. (TODO: UH OH!)
# TODO: Find a more static way for checking if the directory of a file exists.
# TODO TODO TODO WARNING! THIS NEW VERSION OF THIS FUNCTION IS EXPERIMENTAL! TODO TODO TODO
gf2(){
 case "$#" in
  0) printf "ERROR: gf2 needs at least one argument to work."; exit 1;;
  1) # Download the file in the current directory
     wget -q -w 20 --random-wait --user-agent="${ipadua}" "${1}"
     [[ "$?" != "0" ]] && { printf "ERROR: gf could not fetch %s\n" "${1}"; exit 1; }
     ;;
  2) # Put the file at a specified location with a specific name
     local pn=${2%/*}					# The path of the new file
     local fn=${2##*/}					# The file name of the new file
     [[ "${pn}" == "${fn}" ]] && pn="."			# if $pn is the same as $fn, use the current directory
     [[ ! -d "${pn}" ]] && mkdir -p "${pn}"		# if any of the folders in $pn do not exist, define them
     wget -q -w 20 --random-wait --user-agent="${ipadua}" -O "${pn}/${fn}" "${1}"
     [[ $? -eq 0 ]] && {							# TODO: This code block is experimental
      printf "\x1b[1;32mSUCCESS!\x1b[0m Saved as "
      # TODO: What about ${row[1]}?
      [[ "${row[1]}" -eq 1 ]] && printf "\x1b[0;33m" || printf "\x1b[1;33m"	# dim an item if it is an animated gif.
      printf "%s/%s\x1b[0m\n" "${dld}" "${fname}"
     } || printf "\x1b[1;31mFAILED!\x1b[0m\n"
     ;;
  *) printf "ERROR: gf2 can't handle more than two arguments...yet."; exit 1;;
 esac
}

# Func: xp ("Check Page")
# Info: Check to see if a URL exists before going through with this program.
# CAUTION: Some sites do not like spiders!
# NOTE: The HTTP request response may have a different format depending on what website is used.
# NOTE: To force the spider to work with sed, redirect the standard error to standard output using "2>&1"
# NOTE: This function is really designed for imgur.com, YMMV with other sites.
xp(){
 local response=$( wget -q -w 20 --random-wait --user-agent="${ipadua}" --server-response --spider "${1}" 2>&1 | sed -n -r 's/  HTTP\/1.1 (.*)/\1/p')
 case "$response" in
  200\ OK)         printf "\x1b[1;32mOK!\x1b[0m\n" "${1}" ;;
  404\ Not\ Found) printf "\x1b[1;31mNOT FOUND!\x1b[0m Aborting.\n"; exit 1 ;;
  *)               printf "\x1b[1;31mERROR: %s\x1b[0m Aborting.\n" "$response"; exit 1 ;;
 esac
}

# Func: xf ("Check File")
# Info: Check to see if the file we are downloading already exists and ask if it should be overwritten.
# Note: I thought about using askyn, but this was better.
# TODO: Find a way to use askyn
xf(){
 local fn="${1}"
 if [[ -f "${fn}.cbz" || -d "${fn}" ]]; then
  printf "This archive already exists.\n";
  while true; do
   read -p "Do you wish to replace this archive? " yn
   case $yn in
    [Yy]* ) 
     [[ -f "${fn}.cbz" ]] && rm "${fn}.cbz"
     [[ -d "${fn}" ]] && { rm "${fn}"/*; rmdir "${fn}"; }
     break
     ;;
    [Nn]* ) printf "ERROR: Program aborted\n"; exit 1;;
    *)
     printf "Invalid entry. ";
     ((try++))
     [[ $try -eq 3 ]] && { printf "Program aborted after three tries.\n"; exit 1; } || { printf "Please try again.\n"; }
     ;;
   esac
  done
 fi
}

# Func: ask
# Info: Creates a prompt. Ask a question for input. Return a value.
#	Note: if an invalid response is given three times, the program will abort.
# Args: $1 = question
# Returns: $ans
# Usage: answer_variable=$(ask "Question string?")
# Note: The data in this question will not appear in shell history.
ask(){
 local q="${1}"	# Just to be safe, asign the question to a variable.
 local qct=0;
 while true; do
  read -p "${q} " ans						# ask a question and store the answer to a variable
  [[ $ans ]] && break						# If the answer is not blank, break out of the loop
  (( qct++ ))							# Otherwise, Increase the question count
  [[ $qct -eq 3 ]] && { printf "Sorry, I didn't get a valid response after three tries. Aborting.\n"; exit 1; }		# If asked three times
 done
 echo "${ans}"			# print the answer
}

# Func: askyn
# Info: Like ask, but for yes or no answers.
# CAUTION: Yes answers will result in true being returned whereas No answers will return false.
# TODO: Find a way to execute Yes or no responses but without executing what happens with those responses until ans answer is chosen.
askyn(){
 local q="${1}"	# Just to be safe, asign the question to a variable.
 local qct=0;
 while true; do
  read -p "${q} " yn						# ask a question and store the answer to a variable
  if [[ $yn ]]; then						# If the answer is not blank
   case $yn in
    [Yy]* ) ans=0; break;;
    [Nn]* ) ans=1; break;;
    *)
      (( qct++ ))						# Increase the question count
      [[ $qct -eq 3 ]] && { printf "Sorry, I didn't get a valid response after three tries. Aborting.\n"; exit 1; }		# If asked three times
     ;;
   esac
  else								# Otherwise
   (( qct++ ))							# Increase the question count
   [[ $qct -eq 3 ]] && { printf "Sorry, I didn't get a valid response after three tries. Aborting.\n"; exit 1; }		# If asked three times
  fi
 done
 echo "${ans}"			# print the answer

}

# Func: getAlbumTitle
# Info: Fetch the title string of the album if there is one.
# Args: $1 = Album URL
# TODO: Fetch the title of the gallery. I haven't quite figured out how I should use this considering some galleries have ampersands, hypens, and brackets.
# NOTE: using gp like this is ideal for page fetching. Remember to write functions in this function's style.
# wget ...	- Fetch the file
# sed ...	- Find the line that has the data-title attribute
# awk ...	- Find the value of the data title
# sed ...	- Return the first line with that value
# sed ...	- Replace &amp; with &
getAlbumTitle(){
 gp "${1}" \
 | sed -n "/data\-title/p" \
 | awk 'BEGIN{FS="\""} /data\-title/{printf("%s\n",$6);}' \
 | sed -n '1p' \
 | sed -n -r 's/&amp;/\&/g;p'
 # TODO: Add more sed filters when necessary
}

# Func: getAlbumManifest
# Info: Get the list of files that are part of this album.
# Args: $1 = The Album URL ($url)
# NOTE: We shouldn't have to worky about doing an error check (that is [[ #? -ne 0 ]]) since gp takes care of that.
# wget ... - get the manifest page
# sed  ... - extract the manifest from the page
# awk  ... - extract the names of the files from the manifest
# $( )     - make it a space separated string (Not in this version)
# Each row will have the file name + file ext and whether or not that file is animated.
# NOTE: For some reason, when the user agent is an iPad, the spaces in the mainfest are altered.
#	For that we need to alter the requested RE in the sed command. Which is much better.
getAlbumManifest(){
 gp "${1}" \
 | sed -n -r '/images *:/p' \
 | awk 'BEGIN{RS="{";FS=","}
  function gs(f){return gensub(/\".+\":\"(.+)\"/,"\\1","g",f);}
  function gn(f){return gensub(/\".+\":([0-9]+)/,"\\1","g",f);}
  /^\"hash/{printf("%s%s\t%s\n",gs($1),gs($7),gn($8));}'
}

# File: getAniCt (get Animation Count)
# Info: Count the number of times in a provided manifest list that an animation has been found in the mainfest list.
# Args: $1 = manifest list
getAniCt(){
 local tbl="${1}"				# assign the list string to the table variable
 local gifct=0					# Initialize the gif count
 IFSB=$IFS					# Back up the IFS variable
 IFS=$'\n'					# "array items (rows) are separated by newlines"
 tbl=( ${tbl} )					# convert table list string to an array
 
 for row in ${tbl[*]}; do
  IFS=$'\t'					# "row items (columns) are separated by tabs"
  row=( ${row} )				# "convert row string to row array"
  IFS=$'\n'					# "columns are separated by newlines"
  [[ "${row[1]}" -eq 1 ]] && ((gifct++));	# If a file is a gif, increment gifct
 done
 IFS=$IFSB					# Restore the IFS variable.
 
 echo "${gifct}"				# Return the number of animated gifs listed in the manifest
}

# Func: mgf (multi-gf or multi-get-file)
# Info: Using a provided list of file names, get each file.
# TODO: Instead of aborting the program here, list all the files that didn't download after all the files that were downloaded made it.
# TODO: Should I use the "local" modifier or will bash take care of that for me?
# TODO: There is a variable  called "cdnUrl", perhaps I should look into that just in case the default iurl is different.
mgf(){
 local tbl="${1}"			# maifest data
 local dld="${2}"			# download directory
 local ct=$(echo "$tbl" | wc -l)	# count the number of items in the list ( TODO: could we do an item count array style later?)
 # BUG: $ct might return 1 even if the count is zero? Check to see.  It might be wise to look for an alternative to "wc -l"
 [[ $ct -eq 0 ]] && { printf "There aren't any files in this album! Aborting.\n"; exit 1; }

 printf  "Found \x1b[1;32m%d\x1b[0m items.\n" $ct

 IFSB=$IFS			# Back up the IFS variable
 IFS=$'\n'			# "array items are separated by newlines"
 tbl=( ${tbl} )		# "list becomes an array"
 # ct="${#tbl[*]}"		# TODO: Consider trying this out later

 local i=0;				# initalize counter for the for loop
 for row in ${tbl[*]}; do
  IFS=$'\t'			# "array items are separated by tabs"
  row=( ${row} )		# Item becomes an array
  IFS=$'\n'			# "array items are separated by newlines"

  ((i++))						# increment counter
  iurl=$(toImageURL "${row[0]}")			# Note: row[0] is the file name with extension
  printf "Downloading [%03d/%03d] \x1b[1;33m%s\x1b[0m ... " $i $ct "${iurl}"
  ext=$(getImageExt "${row[0]}")			# get the file extension for the new file name.
  fname=$(printf "%03d.%s" $i $ext)			# prepare the new name of the file.
  gf2 "${iurl}" "${dld}/${fname}"			# get the file
 done
 IFS=$IFSB		# Restore the IFS variable.

 # TODO: Count the number of files in the directory. If it is not equal to $ct, echo "DOWNLOAD FAILED."
 printf "\x1b[1;32mDOWNLOAD COMPLETE!\x1b[0m\n"
}

# Func: arc (Archive)
# Info: Determine if the newly created folder has the qualifications to be archived.
# Note: this function will only run if there are no animated gifs found in the manifest
# Args: $1 = "$dld" the download directory
arc(){
 local dld="${1}"
 printf "Putting everything into a .cbz file..."
 zip -q -r "${dld}.cbz" "${dld}"
 [[ $? -ne 0 ]] && { printf "\x1b[1;31mFAILED!\x1b[0m Something happened that shouldn't have happened during the archive process!\n"; exit 1; }
 printf "\x1b[1;32mDONE!\x1b[0m Saved as \x1b[1;33m%s.cbz\x1b[0m\n" "${dld}"
 printf "Deleting \x1b[1;33m%s\x1b[0m folder to conserve space..." "${dld}"
 rm "${dld}"/*					# delete the files
 rmdir "${dld}"					# delete the folder
 printf "\x1b[1;32mDONE!\x1b[0m\n"
 printf "\x1b[1;32mARCHIVE COMPLETE!\x1b[0m\n"
}

# ----- MAIN PART OF THE PROGRAM! -----
# Get and check the URL's existance
url=$(ask "Please enter the URL or album directory of an imgur album to fetch.")
url=$(toAlbumURL "$url")
printf "Check to make sure that \x1b[1;33m%s\x1b[0m exists..."
xp "$url"

# Set up the album file/directory and check the file's existance
album=$(toAlbumString "$url")
title=$(getAlbumTitle "$url")
[[ $title ]] && dld="$album - $title" || dld="$album"
xf "$dld"

printf "Fetching \x1b[1;33m%s\x1b[0m to be saved in the directory \x1b[1;33m%s\x1b[0m\n" "$url" "$dld"
printf "Fetching the album manifest from \x1b[1;33m%s\x1b[0m ... " "$url"
list=$(getAlbumManifest "$url")			# space separated string (this is not an array, yet.)
mgf "$list" "$dld"				# Download the files in the manifest list to the dowload directory
[[ $(getAniCt "$list") -eq 0 ]] && arc "$dld"	# If there are no animated gifs in the manifest list, archive the download directory
