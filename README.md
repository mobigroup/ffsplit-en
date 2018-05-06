# ffsplit-en

I use this script to prepare videos (including downloaded YouTube videos) for my smart TV.

# Licence

This software released into the public domain. Initially it's based on public domain script
http://grapsus.net/blog/post/A-script-for-splitting-videos-using-ffmpeg

# Use as

To split video file abc.mkv for 30-minutes (1800 seconds) fragments use this command:

`ffsplit.sh abc.mkv 1800 abc-part-%04d.mkv`
