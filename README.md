scragur
=======

Scrape Imgur galleries

About scragur
=============
The name "scragur" (pronounced SKRAH-GUR) is a portmateau of "scrape imgur".  A year ago, I was looking for a way to download many image files quickly.  After looking at the page source for an Imgur gallery, I noticed that they used a table of JSON data hidden in the background to pull up two or three different files at a time. (This is why when you browse an Imgur gallery, it doesn't load the complete gallery.)

Sometimes when an imgur gallery gets really big (like 25 or more images), instead of just wanting to download just one file, you'll want to download the entire gallery.  Sometimes, however, when you try to click on the button that says "Download this gallery" (which it will save it as a .zip file) you encounter a message that says that Imgur doesn't have a .zip archive for you to download or that it's too big and they ask for your email address so they can send you a notification when they create one (which is practically never).

A more savvy computer user would use wget or curl to download all those files as part of a Bash, Ruby, or Python script.  It's a step in the right direction, but imgur though of that and has placed restrictions on using wget or curl by only allowing the major browsers (Firefox, Chrome, Safari, Internet Explorer, Opera, etc.) to download en masse.  Fortunately, there is another way around that.

With a little hacker magic and a website called <a href="http://www.useragentstring.com/">UserAgentString.com</a>, you can use wget or curl to tell imgur you are not using wget or curl and bypass the filter. You can use the same user agent string (UAS) as many times as you want or you can grab a new one to be extra wiley as the script will save your faux UAS to a hidden file. (~/.scragur).

Unless the gallery contains animated GIFs (which thanks to the hidden JSON table, there is a field that indicates if a GIF is animated), files will be grouped together in an archive.  But rather than grouped together as a .zip file full of files that imgur randomly renames and are saved using the random name (which when saved using imgur's .zip method will save the files unsequentially), scragur, will rename files sequentially AND save them in a more reasonable format: .cbr or .cbz, Comic Book Archives.  Technically a Comic Book Archive is a photo album/scrapbook that you can read using a PDF reader like evince and manipulate using an archive manager.  No worries about accidently deleting files like in a regular file manager. 

Features
========
* Download individual files or full galleries without running into the message prompt saying "Sorry, it's too big" or "Send us your email and we'll get back to you".
* Use random user-agent strings to tell Imgur you're not using curl or wget.
* Save archives in Comic Book Archive Formats (.cbz, .cbr) for browsing files in evince.
* Discrete downloading. (Download all the files in a gallery without flooding your browser history with each file.)
* Sequential renaming.  Download images in the order that they appear by renaming them with a sequential order rather than imgur's random file name.)


Requirements
============
This script is primarily set to run on Linux or Unix-like operating systems.  But you'll probably want to install the following items from your software distribution.

* bash
* sed
* awk (or gawk)
* wget
* curl

Eventually, most of this will be replaced with something Ruby can do.  And curl.

FAQ
===
Q. Why can't I just download an imgur gallery directly?

A. Imgur has a reasonable argument for not allowing wget and curl to download so easily.  It's because a lot of website adminstrators don't like webscraping.  In the case of imgur, which also allows users to upvote/downvote galleries, is likely to prevent bots from gaming their system.

Q. What is webscraping?

A. Webscraping is kind of like performing a git clone.  You make a duplicate copy of the content you want to download.  However, there are sites that do not like it when users do that.  Some people consider webscraping "stealing" in the sense of how people "stole" music online using Peer-to-Peer networks back in the late 1990s/early 2000s from sites like Napster or Kazaa.  Though calling webscraping "stealing" isn't the right word, especially since when you post content on a public network like the Internet, it is available in a public forum for anyone to download.  The real problem with webscraping is that people can potentially plagarize by stating that the content they took is their own (which is stealing) or adding a watermark--even a watermark to cover the orignal creator's watermark (which is also theft)--or the most egregious and problematic issue with webscraping: creating a fake website that looks like the real website that they stole so that they can lure computer users who don't have the street smarts to check the URL, especially if it is supposted to be a secure website that should be using HTTPS and have that little safety lock indicating the security credentials.

Q. When is it OK to webscrape?

A. Webscraping should be done responsibly and for the purpose of historical archive.  Many of the "Web 1.0" pages that I grew up with have disappeared, including an entire website I wrote on GeoCities back in 2000.  But you still see where there used to be sites that used to user pages every once in a while when a URL points you do a webpage that has a Xoom.com address or a Webring page or if your really lucky some page that has Gopher or Usenet protocol preceeding the address.  (Now that's old!)  Right now, I'm on the hunt for a set of images that were part of a St. Louis City and County map from 1860 that was on a genealogy website until about six months ago.  That's how fragile content is online.  One day it is there, the next day "404: File Not Found", and the folks at <a href="https://archive.org/">the Wayback Machine</a> or <a href="http://archiveteam.org/">Archive Team</a> might not have a backup.  The Internet is full of data treasures, many of which are not as explored like they were back in the Web's halcyon days.

Q. When is is NOT OK to webscrape?

A. Are you some L33t n00b script kiddie who wants to impress your so-called "hacker friends" you met online (who may either be an FBI informant or lecherous creep) who is trying to make a name for yourself by stealing content and calling it your own or trying to make a fake website to commit egregious computer fraud?  Well, don't.  Firstly, that's not how it works.  And secondly, you are not "l33t", "kw3l", or "teh k1n9 pwn3r".  Also, the world/Internet has enough people like <a href="https://www.youtube.com/watch?v=BijChf8ROJU">Eric "eBaum" Bauman</a> stealing content and calling it their own as well as really shady people who clone websites to steal personal information.  The scrager project is not for that purpose nor do I condone such illict practices.  So if by chance you abuse my project to break the law, I'm in no way responsible for your ride in the back of the "FBI Partyvan".  Don't get 'vanned.  Webscrape responsibly and don't be a skiddie or an eBaum.

Project Status
==============
2014-07-21: It's been a while since I've worked on this project so for right now, I'm just using this repository to gather all the files that I know of and put them someplace where I can download and edit them later.  There are a few previous versions of the scripts I'm posting here, but for the momment the goal is to collect all my scripts and make them awesome again.

