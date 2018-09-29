 function git-fp() {
    if [ -n "$1" ]
      then
        if [ -n "$2" ]
          then
            echo "Running git fetch" "$2" "$1" "&& git pull" "$2" "$1"
            git fetch -p "$2" "$1" && git pull "$2" "$1"
          else
            echo "Running git fetch origin" "$1" "&& git pull origin" "$1"
            git fetch -p origin "$1" && git pull origin "$1"
        fi
      else
        currentBranch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
        echo "Running git fetch origin" "$currentBranch" "&& git pull origin" "$currentBranch"
        git fetch -p origin "$currentBranch" && git pull origin "$currentBranch"
    fi
}

function git-clean() {
    git fetch -p --all
    git branch --merged develop | grep -v 'release\|develop' | xargs git branch -d
}

function vidtogif() {
    if [ -n "$1" ]
        then
            INPUT="$1"
            FILENAME="${INPUT%%.*}.gif"

            mkdir pngs gifs
            ffmpeg -i "$1" -r 5 pngs/frame_%04d.png
            sips -s format gif pngs/*.png --out gifs/
            cd gifs
            if [ -z "$2" ]
                then
                    gifsicle *.gif --optimize=3 --delay=100 --loopcount > ../"$FILENAME"
                else
                    gifsicle *.gif --optimize=3 --delay=3 --loopcount --resize "$2" > ../"$FILENAME"
            fi
            cd ..
            rm -rf pngs gifs
    else
        echo "Use video file as first parameter"
    fi
}

function giftovid() {
    if [ -n "$1" ]
        then
            INPUT="$1"
            FILENAME="${INPUT%%.*}.mp4"
            ffmpeg -f gif -i $1 "$FILENAME"
    else
        echo "Use gif file as first parameter"
    fi
}

function simRecordToGif() {
    xcrun simctl io booted recordVideo ~/Desktop/video.mov; vidtogif ~/Desktop/video.mov; mv animation.gif ~/Desktop
}

function git-ffwd() {
  REMOTES="$@";
  if [ -z "$REMOTES" ]; then
    REMOTES=$(git remote);
  fi
  REMOTES=$(echo "$REMOTES" | xargs -n1 echo)
  CLB=$(git rev-parse --abbrev-ref HEAD);
  echo "$REMOTES" | while read REMOTE; do
    git remote show $REMOTE -n \
    | awk '/merges with remote/{print $5" "$1}' \
    | while read line; do
      RB=$(echo "$line"|cut -f1 -d" ");
      ARB="refs/remotes/$REMOTE/$RB";
      LB=$(echo "$line"|cut -f2 -d" ");
      ALB="refs/heads/$LB";
      NBEHIND=$(( $(git rev-list --count $ALB..$ARB 2>/dev/null) +0));
      NAHEAD=$(( $(git rev-list --count $ARB..$ALB 2>/dev/null) +0));
      if [ "$NBEHIND" -gt 0 ]; then
        if [ "$NAHEAD" -gt 0 ]; then
          echo " branch $LB is $NBEHIND commit(s) behind and $NAHEAD commit(s) ahead of $REMOTE/$RB. could not be fast-forwarded";
        elif [ "$LB" = "$CLB" ]; then
          echo " branch $LB was $NBEHIND commit(s) behind of $REMOTE/$RB. fast-forward merge";
          git merge -q $ARB;
        else
          echo " branch $LB was $NBEHIND commit(s) behind of $REMOTE/$RB. reseting local branch to remote";
          git branch -l -f $LB -t $ARB >/dev/null;
        fi
      fi
    done
  done
}

function dvdnify() {
    filesCount=$(ls | egrep -o ".m4v$" | wc -l | egrep -o "\d+")
    
    if [ $filesCount -eq 0 ]; then
        echo "No m4v files!"
        return
    fi
    
    for f in *.m4v; do
        _t=$(ffmpeg -i "$f" 2>&1 | grep "Duration" | grep -o " [0-9:.]*, " | head -n1 | tr ',' ' ' | awk -F: '{ print (($1 * 3600) + ($2 * 60) + $3)/60 }')
        times+=("$_t")
    done
    
    dvdSize=3800
    totalTime=$(echo "${times[@]}" | sed 's/ /+/g' | bc)
    bitrate=$(python -c "from math import ceil; print int(ceil($dvdSize/($totalTime * 0.0075)))")
    
    duration=$(python -c "h, m = divmod($totalTime, 60); print '%dh %02dmin' % (h, m)")
    
    echo "Duration: $duration\nBitrate: $bitrate"
    echo "Want to encode using $bitrate as bitrate? (yes/no)"
    
    read -r -s -e choice
    
    if [ $choice -eq "yes" ]; then
        echo "lets do it"
        for vid in *.m4v; do ffmpeg -threads 4 -i "$vid" -aspect 16:9 -target ntsc-dvd -b:v "$bitrate"k -minrate "$bitrate"k -maxrate "$bitrate"k -bufsize 100k -b:a 128k "${vid%.m4v}.mpg"; done
    else
        echo "Ok, bye!"
    fi
}

function mp3nify() {
  for vid in *.MTS; do ffmpeg -i "$vid" -vn -acodec libmp3lame -b:a 128k "${vid%.MTS}.mp3"; done
}