#!/bin/bash
# Alexey Pechnikov: chnged ffmpeg command line to produce the chunks (it's compatible to mkv files too)
# http://grapsus.net/blog/post/A-script-for-splitting-videos-using-ffmpeg
# we need to prepare some input files like to
# ffmpeg -i Sinbad.Legenda.semi.morej.2003.ts -map 0:0 -map 0:2 -c:v libx264 -profile:v high -level:v 4.0 -c:a copy Sinbad.Legenda.semi.morej.2003.mkv

# Written by Alexis Bezverkhyy <alexis@grapsus.net> in 2011
# This is free and unencumbered software released into the public domain.
# For more information, please refer to <http://unlicense.org/>
 
function usage {
        echo "Usage : ffsplit.sh input.file chunk-duration [output-filename-format]"
        echo -e "\t - input file may be any kind of file reconginzed by ffmpeg"
        echo -e "\t - chunk duration must be in seconds"
        echo -e "\t - output filename format must be printf-like, for example myvideo-part-%04d.avi"
        echo -e "\t - if no output filename format is given, it will be computed\
 automatically from input filename"
}
 
IN_FILE="$1"
OUT_FILE_FORMAT="$3"
typeset -i CHUNK_LEN
CHUNK_LEN="$2"

#VBAND=$(ffprobe "$IN_FILE" 2>&1 | grep Video | tr '()' '#' | tr -d ' ' | cut -d '#' -f2 | head -n 1)
VBAND=$(ffprobe "$IN_FILE" 2>&1 | grep Video | head -n 1 | sed 's/.*\#\([0-9]\{1,2\}:[0-9]\{1,2\}\).*/\1/')
#ABAND=$(ffprobe "$IN_FILE" 2>&1 | grep Audio | grep eng | tr '()' '#' | tr -d ' ' | cut -d '#' -f2 | head -n 1)
AINFO=$(ffprobe "$IN_FILE" 2>&1 | grep Audio | grep eng | xargs)
# when we couldn't find "eng" audio track then we use last audio track instead
if [ "$AINFO" = "" ]
then
    AINFO=$(ffprobe "$IN_FILE" 2>&1 | grep Audio | tail -n 1 | xargs)
fi
#ACODEC=$(echo "$AINFO" | cut -d ' ' -f4)
ACODEC=$(echo "$AINFO" | sed 's/.*udio: \([a-z0-9]*\).*/\1/')
ABAND=$(echo "$AINFO" | sed 's/.*\#\([0-9]\{1,2\}:[0-9]\{1,2\}\).*/\1/')
# copy video and audio as is when we can't define these
if [ "$VBAND" = "" ] || [ "$ABAND" = "" ]
then
    OPTS="-codec copy"
else
    # extract 1st video plus 1st eng audio
    OPTS="-map $VBAND -map $ABAND -vcodec copy"
    # dts is not supported on my smart tv
    if [ "$ACODEC" = "dts" ]
    then
        OPTS="$OPTS -acodec ac3"
    else
        OPTS="$OPTS -acodec copy"
    fi
fi
# this additional option is required often for .ts files
#echo ... | rev | cut -c1-3 | rev
EXT=$(echo -n "$IN_FILE" | tail -c 3)
if [ "$EXT" = "ts" ]
then
    PREOPTS="-fflags +genpts"
else
    PREOPTS=""
fi

DURATION_HMS=$(ffmpeg -i "$IN_FILE" 2>&1 | grep Duration | cut -f 4 -d ' ')
DURATION_H=$(echo "$DURATION_HMS" | cut -d ':' -f 1)
DURATION_M=$(echo "$DURATION_HMS" | cut -d ':' -f 2)
DURATION_S=$(echo "$DURATION_HMS" | cut -d ':' -f 3 | cut -d '.' -f 1)
DURATION_S="10#$DURATION_S"
DURATION=$((( DURATION_H * 60 + DURATION_M ) * 60 + DURATION_S))

if [ "$DURATION" = '0' ]
then
        echo "Invalid input video"
        usage
        exit 1
fi
 
if [ "$CHUNK_LEN" = "0" ]
then
        echo "Invalid chunk size"
        usage
        exit 2
fi
 
if [ -z "$OUT_FILE_FORMAT" ]
then
        FILE_EXT=$(echo "$IN_FILE" | sed 's/^.*\.\([a-zA-Z0-9]\+\)$/\1/')
        FILE_NAME=$(echo "$IN_FILE" | sed 's/^\(.*\)\.[a-zA-Z0-9]\+$/\1/')
        OUT_FILE_FORMAT="${FILE_NAME}-%03d.${FILE_EXT}"
        echo "Using default output file format : $OUT_FILE_FORMAT"
fi
 
N='1'
OFFSET='0'
N_FILES=$((DURATION / CHUNK_LEN + 1))

while [ "$OFFSET" -lt "$DURATION" ]
do
        OUT_FILE=$(printf "$OUT_FILE_FORMAT" "$N")
        echo "writing $OUT_FILE ($N/$N_FILES)..."
#        ffmpeg -err_detect ignore_err -i "$IN_FILE" $OPTS -ss "$OFFSET" -t "$CHUNK_LEN" "$OUT_FILE"
        ffmpeg $PREOPTS -i "$IN_FILE" $OPTS -ss "$OFFSET" -t "$CHUNK_LEN" "$OUT_FILE"
        N=$((N+1))
        OFFSET=$((OFFSET + CHUNK_LEN))
done
