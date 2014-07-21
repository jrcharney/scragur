# File: chased.rb (jason CHArney's Stream EDitor)
# Author: Jason Charney, BSCS (jrcharneyATgmailDOTcom)
# Date: 24 Sep 2013
# Info: Contains the Chased module for filtering data from a file or variable
# Requirements: wget for Linux, UNIX, or any other *NIX operating system.

# Func: wget
# Info: Execute a wget command for data manipulation.
# TODO: Still need to have a contengincy plan for when nothing is found.
#		What if we threw an exception?
# TODO: Use this function to also fetch Google Maps data and Zip code information
# TODO: Also random user agent. (Just because I want to share it.)

module Chased
 # Module variable (like class variables but for modules.
 @@ua = ""

 # Func: grua ("Get Random User Agent")
 # Info: Get a random user agent string (UAS) from UserAgentString.com
 # NOTE: The UAS may effect how some pages are processed. YMMV
 # Note: I originally used quite a bit of sed commands to make this work. I just hop gsub works as well
 # Lucky for me, all of this stuff I'm looking for is on the same line.
 # Note: I had to dumb-down this function for my webhost's version of ruby.
 #	There is no Random class in Ruby 1.8.7. Until you upgrade Ruby, use the Kernel version of the functions.
 def self.grua
  # @sprng = Random.new
  srand
  @browsers = %w{Chrome Firefox Opera Safari}		# No Internet%20Explorer (Too many old entries!)
  # @browser = @browsers[@sprng.rand(@browsers.count)]
  @browser = @browsers[rand(@browsers.count)]
  @us = %x{#{%Q{wget -q -O- 'http://www.useragentstring.com/pages/#{@browser}/'}}}
  @us = lp(@us, (@browser =~ /Chrome/) ? "^Chromium is the name" : "^<div id='liste'>" )
  [ /<br *\/>/, /<\/a><\/li>/, /<ul[^>]*>/ ].each { |re| @us = @us.gsub(re,"\n") }
  [ /<li><a href='[^']*'[^>]*>/, /^<.*/, /Windows NT/ ].each { |re| @us = @us.gsub(re,"") }
  @uas = @us.strip.split(/\n/).delete_if{|e| e == "" }
  @uas.shift if(@browser =~ /Chrome/)
  # return  @uas[@sprng.rand(10)]
  return  @uas[rand(10)]

  # This is what the last five lines just did.
  # @us = %x{...}			# Get the data from the website
  # @us = lp(@us, ... )			# Depending on which browser is picked, find the line where the data is kept.
  # @us = @us.gsub(/<br *\/>/,"\n")	# Replace any breaks with newlines
  # @us = @us.gsub(/<\/a><\/li>/,"\n")	# Replace any ending anchor-list_item combo with a newline
  # @us = @us.gsub(/<ul[^>]*>/,"\n")		# Replace any beginning unordered_list element with a newline
  # @us = @us.gsub(/<li><a href='[^']*'[^>]*>/,"")	# Strip out any beginning list_item-anchor combos
  # @us = @us.gsub(/^<.*/,"")				# Remove all lines that still have HTML in them
  # @us = @us.gsub(/Windows NT/,"")		# Remove any Windows NT listings (These entries are way old.)
  # @us = @us.strip				# Strip out any leading and ending breaks.
  # @uas  = @us.split("\n")			# Split into an array
  # @uas  = @uas.delete_if{|e| e == "" }	# Remove any blank array values
  # @uas.shift if(@browser =~ /Chrome/)		# shift the array to remove the first entry if the browser is Chrome.
  # return @uas[@sprng.rand(10)]		# Return a random entry of the first ten items.

  # @uas = lp(@uasd,"^<div id='liste'>").gsub(/^.*<br *\/>/,"\n").gsub(/<\/a><\/li>/,"\n").gsub(/<ul[^>]*>/,"\n").gsub(/<li><a href='[^']*'[^>]*>/,"").gsub(/^<.*/,"").gsub(/Windows NT/,"").strip.split("\n").delete_if{ |e| e == "" }[0..9]
  # The last line should set @@ua
 end

 def self.ua
  return @@ua
 end

 # Func: wgo (wget -O-)
 # Info: Fetches the text contents. Ideal for grabbing stuff off the Internet and reprocessing it into some other form.
 # TODO: Add the random user agent feature later since some sites assume wget is a webscraper
 # TODO: Find a way to reuse the same ua without running grua constantly.
 # 		Do Modules support class variables?
 def self.wgo(url)
  # @cmd="wget -q -O- '#{url}'"
  # %x{#{@cmd}}
  @@ua = grua if @@ua == ""		# set the user agent string if there isn't one
  %x{#{%Q{wget -q -O- -w 20 --random-wait --user-agent='#{@@ua}' '#{url}'}}}
 end

 # Func: lp (line print)
 # Info: Print a specific line given by a regular expression
 #	 Unlike Enumerable#grep, returns a string and doesn't strip out whitespaces.
 # NOTE: If more than one match is found, the matches are separated by newlines.
 # TODO: You may want to consider returning an array, for now a string is just perfect for what we need.
 # ALTERNATIVELY, file_string.each_line.grep(%r{#{res}})[0] is just as effective but without [0] returns an array.
 def self.lp(file_string,res)
  @out = ""
  file_string.each_line{ |line| @out << line if line =~ %r{#{res}} }
  return @out
 end

 # Func: grep
 # Info: like lp, but uses Enumerable#grep to return an array.
 #	 Any blank lines may be striped out at the beginning and end, since that's what Ruby does.
 def self.grep(file_string,res)
  file_string.each_line.grep(%r{#{res}})
 end

 # Func: rp (inclusive range print)
 # Info: Print the content between a given set of two lines describe by regular expressions including the lines given.
 # TODO: Find a way to have the first characters of the res variables read.
 #	If the first character is "!" use the "!~" operator to exclude the line from the range. 
 #		Don't forget to pop (or shift) the "!" from the string!
 #		Consider including an escape character "\!" to ignore this requiest and look for the character "!"
 #	Else use the "=~" operator to include the line in the range.
 # TODO: What if we only had one res? Could we emulate lp?
 # TODO: Find a way to find line number like sed.
 #		If possible find a way that doesn't involve converting the string to an array.
 #		More like count the number of times the record separatore (RS='\n') occurs.
 #		When counting lines, the index starts at 1 not zero.
 # TODO: Put this into a module.
 def self.rp(file_string,res1,res2)
  @out = ""
  file_string.each_line { |line| @out << line if ( line =~ %r{#{res1}} .. line =~ %r{#{res2}} ) }
  return @out
 end

 # Func: xrp (exclusive range print)
 # Info: Print the content between a give set of two lines described by regular expressions, but do not print the lines they are on.
 # Note: The first argument is called file_string because I think it might work with file contents as well.
 # TODO: Put this into a module.
 def self.xrp(file_string,res1,res2)
  @re1 = Regexp.new(res1)
  @re2 = Regexp.new(res2)
  @out = ""
  file_string.each_line { |line| @out << line if (( line =~ @re1 .. line =~ @re2 ) && line !~ @re1 && line !~ @re2 )}
  return @out
 end
end
