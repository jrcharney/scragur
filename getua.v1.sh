#!/bin/bash
# File: getua.sh ("Get User Agent")
# Date: 30 Aug 2013
# Author: Jason Charney (jrcharneyATgmailDOTcom)
# Info: Grab a random user agent string from UserAgentString.com to mask wget usage.

# Source the ua variable from the hidden file ".getua". Create this file if it doesn't exist.
# ".getua" is where we will store and write our user agent string (UAS) for creating a random user agent.
[[ ! -f .getua ]] && cat << 'EOF' > .getua
ua=
EOF
. .getua

# Before
echo "$ua"

# NOTE: A do-while loop was added to ensure that a divbyzero does not occur.
#	The reciprocal is used because r is a floating point between 0 and 1.
# I'll acknowledge, I borrowed this from http://awk.info/?tip/random with some modification.
# NOTE: This SRNG is VERY SLOW! so use it only once!
srng(){
 awk 'BEGIN{
  "od -tu4 -N4 -A n /dev/random" | getline
  srand(0+$0);
  do{ r=rand(); }while(r == 0);
  print int(1/r);
 }'
}

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
 # TODO: Find a way to save a previous UA instance so that we can run gp with a random UA when we start
 #		up this program to fetch a new one.
 # TODO: Find a way to make an array out of the 10 values so that we can pick one item from the list.
 

 # wget ... - fetch a UAS.com page
 # sed ... - extract the content list (now, extract the contents list through the end of the page)
 # sed ... - Replace any text that preceds a <br /> tag with a new line.
 # sed ... - Delete all blank lines.
 # sed ... - replace all closing anchor-list combos with newline
 # sed ... - replace all opening list tags with newline
 # sed ... - strip out all opening list-anchor combos
 # sed ... - delete all outstaning lines that contain HTML tags
 # sed ... - Delete the first line that starts with a space through the end of the page.
 #		(Get's rid of JavaScript and Google's Urchin)
 # sed ... - print the first ten lines since those are generally the latest browser UAS's

 # gp "http://www.useragentstring.com/pages/${page}/" \
 # TODO: use gp again this function should generate a new $ua argument while using the old $ua at startup
 # TODO: It turns out the Chrome page has a paragraph in an <h4> element at the beginining of the list,
 # 	So we will need to make some changes so that it works with all five pages.
 # TODO: Expand the last sed to more than 10 commands. (Why the Chrome page lists Windows NT user agents is nuts!)
 # NOTE: NO CHARACTERS AFTER BACKSLASH! Otherwise you're going to have a bad time!
 # TODO: get rid of any Windows NT and WOW64 entries.
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

ua=$(grua)	# use this only once!

gp(){
 wget -q -O- -w 20 --random-wait --user-agent="${ua}" "${1}"
 [[ "$?" != "0" ]] && { printf "ERROR: gp could not fetch %s\n" "${1}"; exit 1; }
}

# TODO: Write $ua to .webget (since this will be integrated into the webget.sh library soon.)
# TODO: Overwrite $ua after the first time
# TODO: Read $ua on script startup

# gp "$1"	# use this everywhere!

# Delete .getua and create a new .getua file.
# TODO: What if instead of deleting and creating a new .getua we just overwrite the value?
[[ -f .getua ]] && rm .getua
printf "ua=\"%s\"\n" "${ua}" > .getua		# TODO: tee this command

# After
echo "${ua}"
