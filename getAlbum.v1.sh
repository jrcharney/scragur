# File: GetAlbum.sh
# Date: 30 May 2013
# Created by /u/Vector_Caclulus
# Info: Get photo albums from imgur and minus sites.
# Options:
#  -i = get from an imgur album. This will not work on user or subreddit albums
#  -m = get from a minus album. This might not work on user albums. Minus sites have larger images so download may take longer and archives much bigger!
#  -r = reverse the order of the images. (Useful if for some reason a Minus site loads your pics in backward order.)
#  -q = quiet mode, don't tell me the progress of all the files. (Foolish if you ask me. Especially if one of your files fails.)
#  -v = verbose mode, tell me what the compression programs are doing. (Will likely be available for -R and -Z. Not sure about -D, -P, or -S)
#  When neither -q or -v are used, the files being downloaded are shown but not the compression process.
#  -R = compress into a .cbr file. .cbrs are .rar files renamed as .cbr
#  -Z = compress into a .cbz file. .cbzs are .zip files renmaed as .cbz. They are slighly smaller than .cbrs most of the time. This is the default option.
#  -D = store as a .djvu file. I'm not sure if that is possible but I was thinking of it. Smaller than .pdfs.
#  -P = store as a .pdf file. (Wouldn't be awesome if you could do this?)
#  -S = store as a .ps file.

# site=$1
# album=$2		# assuming that the URL starts with http://imgur.com/a/
if [[ "$#" -lt "2" ]]; then
 echo -e "GetImgur Album downloader\n $0 [-i|imgur|-m|minus] <album id> [-r]\n"
 exit 1
fi

#Choose a site
case $1 in
 -i|imgur) site="imgur" ;;
 -m|minus) site="minus" ;;
 *) echo "ERROR: Invalid site. Aborting."; exit 1 ;;
esac

album=$2

# Check which site we are using.
case $site in
 imgur)
  aurl="http://imgur.com/a/"	#Album URL
  iurl="http://i.imgur.com/"	#Image URL
  ;;
 minus)
  aurl="http://minus.com/"	# Album URL (assuming there is no username prefixing it)
  iurl="http://i.minus.com/"	# Image URL
  ;;
 *)
  echo "Sorry, this script can't handle that site...yet."
  exit 1
  ;;
esac

# Fetch the file manifests and extract the list of files.
printf "Fetching the album manifest from \033[1;33m%s%s\033[0m ... " $aurl $album;
case $site in
 imgur) list=$(wget -q -O- $aurl$album |
               sed -n '/images      :/p' - |
               awk 'BEGIN{RS="{";FS=","}
                    function gs(f){return gensub(/\".+\":\"(.+)\"/,"\\1","g",f);}
                    /^\"hash/{printf("%s%s\n",gs($1),gs($7));}' - );
	;;
 minus) list=$(wget -q -O- $aurl$album |
               sed -n '/^"items":/p' - |
               awk 'BEGIN{ RS="{";FS=", "; }
                    function gv(f){return gensub(/\".+\": \"(.+)\"/,"\\1","g",f);}
                    function gfe(f){return gensub(/.+(\..+)$/,"\\1","g",f);}
                    $21 !~ /_(poster|board).jpg/{printf("i%s%s\n", gv($15), gfe(gv($21)));}' - |
              sed -n '/^i$/d;p' - );
	;;
 *) echo "How did you even get here?"; exit 1 ;;
esac

# Show the count of the files
if [ "$?" = "0" ]; then
 ct=$(echo "$list" | wc -l);	# get the count of the number of items
 printf "\033[1;32mSUCCESS!\033[0m Found \033[1;33m%s\033[0m items.\n" $ct
else
 printf "\033[1;31mFAILURE!\033[0m Aborting.\n"
 printf "Try visiting \033[1;33m%s%s\033[m to see if the album is still there.\n" $aurl $album;
 exit 1
fi

# This command should reverse the order of the items to download. This can be usesful if minus loads a gallery backwards.
if [[ "$3" = "-r" ]]; then	# attempt to reverse the order of the items
 list=$(echo "$list" | tac)
fi

# TODO: Fetch the title of the gallery. Still haven't figured out how to automate this part.
case $site in
 imgur) title=$(wget -q -O- $aurl$album |
                sed -n "/data\-title/p" - |
                awk 'BEGIN{FS="\""} /data\-title/{printf("%s\n",$6);}' - |
                sed -n "1p" - );
	;;
 minus) title=$(wget -q -O- $aurl$album |
                sed -n '/^  "name":/p' - |
                awk 'BEGIN{FS=": "} {printf("%s",gensub(/\"(.+)\"\,/,"\\1","g",$2));}' - );
	;;
 *) echo "ERROR: I'm pretty sure I didn't program this script so you could see this message."; exit 1 ;;
esac

# The download process
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

# Now's a good time to show the title of this album if there is one.
if [ -n "$title" ]; then printf "\033[1;33m%s\033[0m ... " $title; fi	# Show us the title if there is one.

# Was the download successful?
if [ "$failct" = "0" ]; then
 printf "\033[1;32mDOWNLOAD COMPLETE!\033[0m\n"
else
 printf "\033[1;31mDOWNLOAD INCOMPLETE!\033[0m\n"
 printf "  There were %s files that did not download.\n" $failct;
 printf "  The files that did download can be found in the %s folder\n" $album;
 exit 1
fi

# Archive and clean up
if [ "$gifct" = "0" ]; then			# So as long as none of the files are .gif, put them into a .cbr or .cbz
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
