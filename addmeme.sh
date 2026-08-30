#!/bin/bash
# LQC Meme Vault uploader
# Usage:
#   ./addmeme.sh /path/to/meme.jpg [more files...]   -> add those files
#   ./addmeme.sh                                     -> just republish (after manual deletes)

REPO="$HOME/Downloads/lowqualitycat"
MEMES="$REPO/memes"

cd "$REPO" || { echo "Repo not found at $REPO"; exit 1; }

# add files passed as arguments
for f in "$@"; do
  [ -e "$f" ] || { echo "skip (not found): $f"; continue; }
  name=$(basename "$f")
  ext="${name##*.}"
  base="${name%.*}"
  shopt -s nocasematch
  if [[ "$ext" =~ ^(mov|mp4|gif|webm)$ ]]; then
    # compress video
    if command -v ffmpeg >/dev/null; then
      ffmpeg -i "$f" -vf "scale='min(1280,iw)':-2" -c:v libx264 -crf 28 -preset fast -c:a aac -b:a 96k -movflags +faststart "$MEMES/$base.mp4" -y -loglevel error \
        && echo "added video: $base.mp4"
    else
      echo "ffmpeg missing — copying video uncompressed"
      cp "$f" "$MEMES/$name"
    fi
  elif [[ "$ext" =~ ^(jpg|jpeg|png|heic|webp)$ ]]; then
    # compress image
    sips -Z 1600 -s format jpeg -s formatOptions 80 "$f" --out "$MEMES/$base.jpg" >/dev/null \
      && echo "added image: $base.jpg"
  else
    echo "skip (unsupported type): $name"
  fi
  shopt -u nocasematch
done

# rebuild list.json
ls "$MEMES" | grep -v list.json | sed 's/.*/"&"/' | paste -sd, - | awk '{print "["$0"]"}' > "$MEMES/list.json"
echo "list.json rebuilt: $(ls "$MEMES" | grep -v list.json | wc -l | tr -d ' ') files"

# publish
git add -A
git commit -m "update memes" >/dev/null 2>&1 && git push || echo "nothing new to publish"
echo "done — live in ~2 min"
