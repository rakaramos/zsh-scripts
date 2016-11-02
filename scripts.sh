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
            mkdir pngs gifs
            ffmpeg -i "$1" -r 5 pngs/frame_%04d.png
            sips -s format gif pngs/*.png --out gifs/
            cd gifs
            if [ -z "$2" ]
                then
                    gifsicle *.gif --colors=256 --optimize=3 --delay=3 --loopcount > ../animation.gif
                else
                    gifsicle *.gif --colors=256 --optimize=3 --delay=3 --loopcount --resize "$2" > ../animation.gif
            fi
            cd ..
            rm -rf pngs gifs
    else
        echo "Use video file as first parameter"
    fi
}