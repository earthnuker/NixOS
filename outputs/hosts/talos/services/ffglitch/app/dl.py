from yt_dlp import YoutubeDL
import sys
import os
import json
import random
import selectors
import subprocess as SP


def longer_than_a_minute(info, *, incomplete):
    duration = info.get("duration")
    if duration and duration < 60:
        return "The video is too short"


def get_vid():

    with YoutubeDL(
        {
            "playlistrandom": True,
            "max_filesize": 200 * 1024 * 1024,  # 200 MB
            "match_filter": longer_than_a_minute,
            "format": "bestvideo[width<=1000]",
            "progress_with_newline": True,
            "progress_delta": 3,
            "quiet": True,
            "progress": True,
        }
    ) as ytdl:
        while True:
            num = str(random.randint(0, 9999)).zfill(4)
            info = ytdl.extract_info(f"ytsearch:IMG_{num}", process=False)
            entries = list(info["entries"])
            random.shuffle(entries)
            for vid in entries:
                try:
                    meta = ytdl.extract_info(vid["id"], download=True)
                except Exception as e:
                    print(f"Error getting video: {e}")
                    continue
                if dl := meta.get("requested_downloads"):
                    return dict(id=vid["id"], path=dl[0]["filename"])


def main():
    print(json.dumps(get_vid()))

if __name__ == "__main__":
    main()
