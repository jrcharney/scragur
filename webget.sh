#!/bin/bash
# File: webget.sh
# Date: 22 Aug 2013
# Version: 1.0
# Author: Jason Charney (jrcharneyATgmailDOTcom)
# Info: A library full of common functions used for web extraction
# Usage: . webget.sh
# Notes:
#  * Only functions should be in this library.
# TODO: What about global variables?
# TODO: Create a function that gets a random user agent that does not belong to a mobile device.



# Source the ua variable from the hidden file ".getweb". Create this file if it doesn't exist.
# ".getweb" is where we will store and write our user agent string (UAS) for creating a random user agent.
[[ ! -f .getweb ]] && cat << 'EOF' > .getweb
ua=
EOF
. .getweb

# Func: srng ("Seeded Random Number Generator")
# NOTE: Bash's $RANDOM variable will only generate a number between 0 and 32767.
#	Therefore it is not ideal for creating random encryption keys.
#	For that reason alone, awk gets to do the SRNGing.
# NOTE: To set the SRNG for a random number within a range, use
#  awk '{srand();print int(rand()*($max-$min))+$min;}'
# of corse you coud always use perl
#  perl -e 'print int(rand($max-$min))+$min'
# NOTE: A do-while loop was added to ensure that a divbyzero does not occur.
#       The reciprocal is used because r is a floating point between 0 and 1.
# I'll acknowledge, I borrowed this from http://awk.info/?tip/random with some modification.
srng(){
 awk 'BEGIN{
  "od -tu4 -N4 -A n /dev/random" | getline
  srand(0+$0);
  do{ r=rand(); }while(r == 0);
  print int(1/r);
 }'
}
 
# Func: grua ("Get Random User Agent")
# Info: Get a random user agent string (UAS) from UserAgentString.com
grua(){
 # CHANGE: No more Internet%20Explorer. (Too many OLD entries!)
 # CHANGE: No more Windows NT. (Who uses that anymore?!)
 local pages=(Chrome Firefox Opera Safari)
 local pc=${#pages[*]}          # number of elements in the pages array
 local rn=$(srng)               # A random number to generate
 (( rn %= pc ))             # narrow down the values of the rn to the number of items in the array.
 local page="${pages[$rn]}"     # Pick the page to use

 # UAS.com require a slash at the end of the address, other wise it returns nothing.
 # gp "http://www.useragentstring.com/pages/${page}/"
 # They've also decided to use single quotes. Nice try, guys.
 # These lists are very long, so we'll just use one of the first ten instances.
 
 # wget ... - fetch a UAS.com page
 # sed ... - extract the content list (now, extract the contents list through the end of the page)
 # sed ... - Replace any text that preceds a <br /> tag with a new line. (Chrome only)
 # sed ... - Delete all blank lines. (Chrome only)
 # sed ... - replace all closing anchor-list combos with newline
 # sed ... - replace all opening list tags with newline
 # sed ... - strip out all opening list-anchor combos
 # sed ... - delete all outstaning lines that contain HTML tags
 # sed ... - Delete the first line that starts with a space through the end of the page.
 #		(Get's rid of JavaScript and Google's Urchin at the end of the page)
 # sed ... - Delete all the Windows NT entries. (Try not to look shady to the server.)
 # sed ... - print the first ten lines since those are generally the latest browser UAS's

 # TODO: Expand the last sed to more than 10 commands. (Idea for more variety but pulls up older entries.)
 # NOTE: NO CHARACTERS AFTER BACKSLASH! Otherwise you're going to have a bad time!
 local list=$( [[ "$page" = "Chrome" ]] && {
  wget -q -O- -w 20 --random-wait --user-agent="${ua}" "http://www.useragentstring.com/pages/${page}/" \
  | sed -r -n "/^<div id='liste'>/,\$p" \
  | sed -r -n "s/^.*<br *\/>/\n/g;p" \
  | sed -r -n "/^\$/d;p" \
  | sed -r -n "s/<\/a><\/li>/\n/g;p" \
  | sed -r -n "s/<ul[^>]*>/\n/g;p" \
  | sed -r -n "s/<li><a href='[^']*'[^>]*>//g;p" \
  | sed -r -n "/^<.*/d;p" \
  | sed -r -n "/^ +/,\$d;p" \
  | sed -r -n "/Windows NT/d;p" \
  | sed -r -n "1,10p"
 } || {
  wget -q -O- -w 20 --random-wait --user-agent="${ua}" "http://www.useragentstring.com/pages/${page}/" \
  | sed -r -n "/^<div id='liste'>/,\$p" \
  | sed -r -n "s/<\/a><\/li>/\n/g;p" \
  | sed -r -n "s/<ul[^>]*>/\n/g;p" \
  | sed -r -n "s/<li><a href='[^']*'[^>]*>//g;p" \
  | sed -r -n "/^<.*/d;p" \
  | sed -r -n "/^ +/,\$d;p" \
  | sed -r -n "/Windows NT/d;p" \
  | sed -r -n "1,10p"
 }
 )

 IFSB=$IFS					# Back up the IFS variable
 IFS=$'\n'					# "array items (rows) are separated by newlines"
 list=(${list})
 local ic=${#list[*]}
 rn=$(srng)
 (( rn %= ic ))
 local ua="${list[$rn]}"
 IFS=$IFSB					# Restore the IFS variable.
 echo "${ua}"
}

# Set the ua string for the application
ua=$(grua)	# use this only once! The fact that is used here means you don't need to redeclare it.

# Delete .getua and create a new .getua file.
# TODO: What if instead of deleting and creating a new .getua we just overwrite the value?
[[ -f .getweb ]] && rm .getweb
printf "ua=\"%s\"\n" "${ua}" > .getweb		# TODO: tee this command


# Func: gp ("getPage")
# Info: Fetch a page and print to standard output (think of it as wget meets cat)
# Args: $1 = $url = URL to
# Features/Improvements:
# * --random-wait (randomize the wait time so you don't tick off the server)
# * -w 20	( set the random wait to randomize the wait time to an extent.)
# * --user-agent (grua should generate one
# NOTE: This function does not get the contents from files, but the page that the contents are located.
#       If you want to get something from a file, try gf.
gp(){
 wget -q -O- -w 20 --random-wait --user-agent="${ua}" "${1}"
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
     wget -q -w 20 --random-wait --user-agent="${ua}" "${1}"
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

# Func: gfx ("get file extension")
# Info: get the file extension and make it look pretty
# Args: "${1}" is a file name, not a URL
# TODO: make similar functions for fetching file names, paths, url strings
# TODO: This version is experimental
gfx(){
   local file="${1##*/}"	# Make sure that file is a file not a URL
   local ext="${file##*.}"	# get the file extension from the file part.
   echo "${ext,,}"		# convert it to lowercase and return it
}


# Func: xp ("Check Page")
# Info: Check to see if a URL exists before going through with this program.
# CAUTION: Some sites do not like spiders!
# NOTE: The HTTP request response may have a different format depending on what website is used.
# NOTE: To force the spider to work with sed, redirect the standard error to standard output using "2>&1"
# TODO: Initally, this function is really designed for imgur.com, YMMV with other sites.
#	I hope to make a version of this function that can be used for all sites.
xp(){
 local response=$( wget -q -w 20 --random-wait --user-agent="${ua}" --server-response --spider "${1}" 2>&1 | sed -n -r 's/  HTTP\/1.1 (.*)/\1/p')
 case "$response" in
  200\ OK)         printf "\x1b[1;32mOK!\x1b[0m\n" "${1}" ;;
  404\ Not\ Found) printf "\x1b[1;31mNOT FOUND!\x1b[0m Aborting.\n"; exit 1 ;;
  *)               printf "\x1b[1;31mERROR: %s\x1b[0m Aborting.\n" "$response"; exit 1 ;;
 esac
}

# --------------
# TODO: The following functions should probably go in a library meant for archiving.

# Func: xf ("Check File")
# Info: Check to see if the file we are downloading already exists and ask if it should be overwritten.
# Note: I thought about using askyn, but this was better.
# NOTE: This will only check for directories and .cbz files.
# TODO: Find a way to use askyn
# TODO: Should I make a version of this function that checks for files of specific file extensions?
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
