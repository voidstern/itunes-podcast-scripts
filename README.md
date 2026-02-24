# iTunes Podcast Maintenance Scripts

I've started using iPods again, but I was missing many of the features commonly found in modern podcast players. I have an old MacBook on macOS Mojave specifically for iTunes, since the newer Apple Podcasts app no longer synchronizes playback state correctly through Finder to iPods. 

These scripts provide those missing features to an iTunes-based podcast syncing workflow.

## Features

- **Playback Speed Modification:** Speeds up podcast audio files (configurable per podcast).
- **Updating Duration:** Updates the track duration within iTunes after the file has been sped up.
- **Cover Art Embedding:** Searches for and embeds the podcast cover art directly into the MP3 files.
- **Podcast "Stations":** Updates "station" playlists containing only the oldest `X` episodes of given podcasts.
- **Partially Played:** Maintains a "partially played/started" playlist so you can easily pick up where you left off.

## Installation and Requirements

*   **OS:** macOS Mojave (latest version possible with iTunes, *not* the modern Apple Music/Podcasts apps).
*   **Location:** 
    1. Place this `Scripts` folder right next to your `iTunes` folder (usually `~/Music/Scripts` next to `~/Music/iTunes`).
    2. Create a folder named `Stations` inside your `Music` folder (`~/Music/Stations`).
*   **Dependencies:** Make sure `ffmpeg` is installed and available in your `PATH` (used by the file adjustment scripts).

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

### Configuring Playback Speed (`speedup.conf`)

By default, the scripts multiply the playback speed by `2.0`. To configure a custom playback speed for a specific podcast, create a `speedup.conf` file directly inside the podcast's designated folder within `iTunes Media/Podcasts/`.

**Example `speedup.conf` contents:**
```text
speed=1.5
```

## Running the Scripts

The primary entry point is the `run_maintainance.sh` script, which provides several helpful flags:

```bash
./run_maintainance.sh [OPTIONS] [MODE]
```

### Modes (One is Required)
*   **`-a`, `--all`**: Run maintenance on everything (both files and iTunes updates). It forces a refresh of podcasts.
*   **`-f`, `--files`**: Run maintenance on **Files only**.
    *   *Tip: I often run this through a network share from my modern Mac after subscribing to a new podcast with many episodes. `ffmpeg` runs much faster on modern hardware than on the old MacBook, even over the network.*
*   **`-t`, `--itunes`**: Run maintenance on **iTunes only**.
    *   *Tip: Use this on the old MacBook after running the file-only mode over the network. This quickly updates iTunes with the changes made to the files.*

### Additional Options
*   **`-r`, `--refresh-podcasts`**: Forces iTunes to check for and download new podcast episodes prior to running the other maintenance scripts.
*   **`-w`, `--window`**: Opens a new Terminal window to run the script instead of running inline.

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
