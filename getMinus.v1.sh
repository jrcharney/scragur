#!/bin/bash
# File: GetMinus.sh
# Author: Jason Charney (jrcharneyATgmailDOTcom)
# Version: 1.0
# WARNING: You MUST install the rar package if you want to create a rar file or cbr file.
# Date: 27 May 2013
# Info: Downloads an ENTIRE Minus.com album accorind to its file manifest hidden on the page
#       AND downloads them in the order they appear. JPG and PNG albums will be saved
#       as comic book archives (.cbr) so that you can open them with evince as photo albums.
#	This script is based off my other script `getimgur.sh`
# Requires: wget, sed, gawk, rar
# NOTE: Minus galleries can be much larger than Imgur galleries.
# TODO: Merge this script with getimgur.sh
# TODO: Functions

# wget -q -O- url			# Print the file to standard output
# | sed -n '/images      :/p' -		# Find the image array. It's written in javascript
# | awk ...				# get file names and extensions

# On minus.com you MUST use the maifest because their page is written in some ASP-like HTML that is processed by javascript

album=$1		# Assuming that the URL starts with http://minus.com/
if [[ -z $album ]]; then
 echo -e "GetMinus Album downloader\n $0 <album id>\n" 
 exit 1
fi

# Let's assume for the moment that thumbnails are stored where album images are.
# We want to do this query because thumbnail urls, like the urls for full images
# begin with a numbered prefix (i.e. http://i5.minus.com/imagestring.ext)
# TODO: Do we need the "\n" at the end of the awk printf string?
# aurl=$(wget -q -O- http://minus.com/$album |
# sed -n '/"thumbnail_url":/p' - |
#  awk 'BEGIN{FS=": "} {printf("%s",gensub(/\"(http:\/\/.+\/).+\"/,"\\1","g",$2));}' -
# );

aurl="http://minus.com/"	# Album URL (assuming there is no username prefixing it)
iurl="http://i.minus.com/"	# Image URL

# FIELDS
# 15	id			<------
# 17	thumbnails		# There are commas in this value! Think of a work around
# 21	name			<------
# 27	secure_prefix		# I don't think I have to worry about using this field

# Note: The field separator (FS) is a comma and a space so that field $17 ("thumbnails") which has commas in it,
#	doesn't trick awk into thinking the value in this field is a set of fields.
# gv = get value - strip out the key and show just the value
# gfe = get file extension

# Eventually, replace gv($21) with gfe(gv($21)) but first we got to get rid of a couple of lines.
# The last sed command in the list fetch eliminates the download of an error file that was downloaded
# because the "item" line managed to sneak into the list.

printf "Fetching the album manifest from \033[1;33m%s%s\033[0m ... " $aurl $album;

list=$(wget -q -O- $aurl$album |
 sed -n '/^"items":/p' - |
 awk 'BEGIN{ RS="{";FS=", "; }
  function gv(f){return gensub(/\".+\": \"(.+)\"/,"\\1","g",f);}
  function gfe(f){return gensub(/.+(\..+)$/,"\\1","g",f);}
  $21 !~ /_(poster|board).jpg/{printf("i%s%s\n", gv($15), gfe(gv($21)));}' - |
 sed -n '/^i$/d;p' -
);

if [ "$?" = "0" ]; then
 ct=$(echo "$list" | wc -l);	# get the count of the number of items
 printf "\033[1;32mSUCCESS!\033[0m Found \033[1;33m%s\033[0m items.\n" $ct
else
 printf "\033[1;31mFAILURE!\033[0m Aborting.\n"
 printf "Try visiting \033[1;33m%s%s\033[m to see if the album is still there.\n" $aurl $album;
 exit 1
fi

# This command should reverse the order of the items to download. This can be usesful if minus loads a gallery backwards.
if [[ "$2" = "-r" ]]; then	# attempt to reverse the order of the items
 list=$(echo "$list" | tac)
fi

# TODO: Fetch the title of the gallery. Still haven't figured out how to automate this part.
title=$(wget -q -O- $aurl$album |
 sed -n '/^  "name":/p' - |
 awk 'BEGIN{FS=": "} {printf("%s",gensub(/\"(.+)\"\,/,"\\1","g",$2));}' -
);

i=0;					# initalize counter
gifct=0;				# Count the number of gif files. If there are any the archiving process won't happen.
failct=0;				# Number of failed downloads. If more than one, the cbr process is cancelled.
for item in $list; do
 ((i++))				# increment counter	(Moved it to before the echo statement so that $? would not return 1 because $i = 1)
 printf "Downloading [%03d/%03d] \033[1;33m%s%s\033[0m..." $i $ct $iurl $item
 wget -q -P $album $iurl$item		# -P will set the directory prefix
 if [ "$?" = "0" ]; then			# if no errors
  ext=${item##*.}				# get the extension
  ext=${ext,,}					# convert it to lowercase
  # TODO: Eliminate any non alphabetica characters that may be added to the end of files. (i.e. "?1")
  if [[ $ext =~ gif ]]; then ((gifct++)); fi	# if a file is a increase the count.
  fname=$(printf "%03d.%s" $i $ext)		# prepare the new name of the file.
  mv $album/$item $album/$fname		# rename the file sequentially. If there are gaps, it means failures
  printf "\033[1;32mSUCCESS!\033[0m Saved as \033[1;33m%s/%s\033[0m\n" $album $fname
 else
  ((failct++))
  echo -e "\033[1;31mFAILED!\033[0m\n"
 fi
done

if [ -n "$title" ]; then printf "\033[1;33m%s\033[0m ... " $title; fi	# Show us the title if there is one.

if [ "$failct" = "0" ]]; then
 printf "\033[1;32mDOWNLOAD COMPLETE!\033[0m\n"
else
 printf "\033[1;31mDOWNLOAD INCOMPLETE!\033[0m\n"
 printf "  There were %s files that did not download.\n" $failct;
 printf "  The files that did download can be found in the %s folder\n" $album;
 exit 1
fi

# TODO: Compress into CBZ NOT CBR!

# TODO: So as long as none of the files are .gif, put them into .cbr or .cbz file
if [[ "$gifct" = "0" ]]; then
 printf "Putting everything into a .cbz file..."
 # rar a -idq $album.cbr $album			# Save the file as a .cbr. This is a .rar format used for comic books, but also ideal for photo albums.
 zip -q -r $album.cbz $album			# Save the file as a .cbz. Slightly more compressed than .cbr
 if [ "$?" = "0" ]; then
  printf "\033[1;32mDONE!\033[0m Saved as \033[1;33m%s.cbr\033[0m\n" $album
  printf "Deleting \033[1;33m%s\033[0m folder to conserve space..." $album
  rm $album/*					# delete the files
  rmdir $album					# delete the folder
  printf "\033[1;32mDONE!\033[0m\n"
 else
  printf "\033[1;31mFAILED!\033[0m Something happened that shouldn't have happened!\n"
 fi
else
 printf "That's it. I can't put it into a .cbz file because there are .gifs in the \033[1;33m%s\033[0m folder.\n" $album
fi

