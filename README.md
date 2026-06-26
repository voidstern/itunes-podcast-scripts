# iTunes Podcast Maintenance Scripts

I've started using iPods again, but I was missing many of the features commonly found in modern podcast players. I have an old MacBook on macOS Mojave specifically for iTunes, since the newer Apple Podcasts app no longer synchronizes playback state correctly through Finder to iPods. 

These scripts provide those missing features to an iTunes-based podcast syncing workflow.

## Features

- **Playback Speed Modification:** Speeds up podcast audio files (configurable per podcast).
- **Intro/Outro Trimming:** Removes a configurable number of seconds from the start and/or end of each episode before applying the speed change.
- **Updating Duration:** Updates the track duration within iTunes after the file has been sped up.
- **Cover Art Embedding:** Searches for and embeds the podcast cover art directly into the MP3 files.
- **Podcast "Stations":** Updates "station" playlists containing only the oldest `X` episodes of given podcasts.
- **Partially Played:** Maintains "partially played/started" podcast and audiobook playlists so you can easily pick up where you left off.
- **iPod Sync Preparation:** Marks deletable episodes as played, syncs loved status to ratings for iPod compatibility, and syncs connected iPods.

## Installation and Requirements

*   **OS:** macOS Mojave (latest version possible with iTunes, *not* the modern Apple Music/Podcasts apps).
*   **Location:** 
    1. Place this `Scripts` folder right next to your `iTunes` folder (usually `~/Music/Scripts` next to `~/Music/iTunes`).
    2. Create a folder named `Stations` inside your `Music` folder (`~/Music/Stations`).
*   **Dependencies:** A pre-built `ffmpeg` binary is included in the `Bash/` folder and used automatically. If you already have `ffmpeg` installed in your `PATH`, that will be used instead. `bc` must be available in your `PATH` (standard on macOS).

### Smart Playlists Setup

The scripts do not directly move files into playlists. Instead, they modify the **"grouping"** attribute of the podcast tracks in iTunes. You will need to manually create the following Smart Playlists in iTunes (you only need to do this once):

1.  **Station Playlists**
    For each station you want, create a smart playlist with the rules:
    *   `Grouping` is `[Station Name]`
    *   `Plays` is `0` (or `Unplayed` is `true`)
    *   `Media Kind` is `Podcast`
2.  **Partially Played / Started Playlist**
    Create a smart playlist with the rules:
    *   `Grouping` is `Started`
    *   `Plays` is `0` (or `Unplayed` is `true`)
    *   `Media Kind` is `Podcast`

### Configuring Stations

In the `~/Music/Stations` folder, create a `.txt` file for each station. The name of the file will become the grouping name (and the name of your smart playlist). 

Inside the text file, write the names of the podcasts exactly as they appear in iTunes. To limit the number of episodes included for a specific podcast, append `|` and the number of episodes (e.g., to keep only the oldest 3).

**Example `My Station.txt`:**
```text
The Daily|3
Tech News Today|5
A Very Long Podcast
```

### Configuring Adjustments (`adjustments.conf`)

To customise how audio files are processed for a specific podcast, create an `adjustments.conf` file directly inside the podcast's designated folder within `iTunes Media/Podcasts/`.

The following options are supported:

| Key | Default | Description |
|-----|---------|-------------|
| `speed` | `2.0` | Playback speed multiplier applied by `atempo`. |
| `intro` | `0` | Seconds to cut from the **beginning** of the episode (measured in original, pre-speedup time). |
| `outro` | `0` | Seconds to cut from the **end** of the episode (measured in original, pre-speedup time). |

**Example `adjustments.conf`:**
```text
speed=1.5
intro=30
outro=60
```

This would skip the first 30 seconds and the last 60 seconds of each episode, then speed the remainder up to 1.5×.

## Running the Scripts

The primary entry point is the `run_maintainance.sh` script, which wraps `maintainance.sh` with higher-level modes:

```bash
./run_maintainance.sh [OPTIONS] [MODE]
```

### Modes (One is Required)
*   **`-a`, `--all`**: Run maintenance on everything (both files and iTunes updates). It forces a podcast refresh and runs `-c -a -m -d -p -b -l -g -s -e -i`.
*   **`-f`, `--files`**: Run maintenance on **Files only** (`-c -a -m`).
    *   *Tip: I often run this through a network share from my modern Mac after subscribing to a new podcast with many episodes. `ffmpeg` runs much faster on modern hardware than on the old MacBook, even over the network.*
*   **`-t`, `--itunes`**: Run maintenance on **iTunes only** (`-d -p -b -l -g -s -e -i`).
    *   *Tip: Use this on the old MacBook after running the file-only mode over the network. This quickly updates iTunes with the changes made to the files.*
*   **`-s`, `--stations`**: Reset podcast groupings, rebuild station playlists, update started podcasts, and sync connected iPods (`-g -s -e -i`).
*   **`-i`, `--sync-ipod`**: Mark deletable episodes as played and sync connected iPods (`-p -i`).

### Additional Options
*   **`-r`, `--refresh-podcast`, `--refresh-podcasts`**: Forces iTunes to check for and download new podcast episodes prior to running the other maintenance scripts.
*   **`--recent-only`**: Runs lighter recent-podcast modes. With `--itunes`, it runs `-d -s -i`; with `--files`, it runs `-c -a`; with `--all`, it runs `-c -a -d -s -p -i` and still forces a podcast refresh.
*   **`--hours INT`**: Sets the number of hours checked by the recent podcast duration refresh (`refresh_latest.scpt`). This is passed through to `maintainance.sh`.
*   **`-w`, `--window`**: Opens a new Terminal window to run the script instead of running inline. By default, the window will close automatically when the script finishes.
    *   *Note: If the window stays open displaying "Process completed", you may need to check your Terminal settings. Go to **Terminal > Preferences > Profiles > Shell** and set "When the shell exits" to **"Close if the shell exited cleanly"**.*
*   **`-k`, `--keep-open`**: Leaves the new Terminal window open after the script finishes (only applicable when used with `-w`).

### Direct Step Runner

You can also call `maintainance.sh` directly when you want to choose the exact steps:

```bash
./maintainance.sh [STEPS] [OPTIONS]
```

Available steps can be combined:

*   **`-r`**: Refresh podcasts in iTunes.
*   **`-c`**: Load missing podcast cover artwork.
*   **`-a`**: Adjust audio files.
*   **`-m`**: Clean orphaned markers.
*   **`-d`**: Refresh recent podcast durations in iTunes.
*   **`-p`**: Mark deletable episodes as played.
*   **`-b`**: Update started audiobooks.
*   **`-l`**: Sync loved status and ratings.
*   **`-g`**: Reset podcast groupings.
*   **`-s`**: Update podcast station playlists.
*   **`-e`**: Update started podcasts.
*   **`-i`**: Sync connected iPods.

Direct options:

*   **`--hours INT`**: Set the number of hours to check for recent podcasts.
*   **`-h`, `--help`**: Show the help message.

## Automating the Scripts

To run the maintenance scripts automatically on your macOS Mojave machine, it is recommended to use **`launchd`** (the native macOS alternative to `cron`, although `cron` is also supported).

### Using `launchd` (Recommended)

`launchd` manages scripts via Property List (`.plist`) files. 

1.  Create a file named `com.user.podcastmaintenance.plist` in `~/Library/LaunchAgents/`.
2.  Add the following XML content to schedule the script to run, for example, every day at 3:00 AM (adjust the path and time as needed):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.podcastmaintenance</string>
    <key>ProgramArguments</key>
    <array>
        <!-- Use absolute paths -->
        <string>/Users/YOUR_USERNAME/Music/Scripts/run_maintainance.sh</string>
        <string>-a</string>
        <string>-w</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```
*(Remember to replace `YOUR_USERNAME` with your actual macOS username).*

3.  Load the scheduled task using the terminal:
    ```bash
    launchctl load ~/Library/LaunchAgents/com.user.podcastmaintenance.plist
    ```

### Using `cron`

If you prefer the traditional `cron` approach:

1.  Open your crontab file by running `crontab -e` in the terminal.
2.  Add a line to schedule the script. For example, to run it every day at 3:00 AM:
    ```cron
    0 3 * * * /Users/YOUR_USERNAME/Music/Scripts/run_maintainance.sh -a >> /Users/YOUR_USERNAME/Music/Scripts/cron.log 2>&1
    ```
    *(This runs it with the `-a` toggle for full maintenance and logs output).*
3.  Save and exit. macOS may ask for terminal accessibility permissions for `cron` to run the AppleScripts correctly.
