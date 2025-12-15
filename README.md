# TTMediaBot Docker Helper

This repository provides `tthelper.sh`, a command-line helper script designed to run **TTMediaBot** inside Docker without requiring users to build Docker images manually.
The script automatically pulls the prebuilt TTMediaBot image from Docker Hub, creates isolated bot instances, and manages containers in a clean and convenient way.

---

## What is TTMediaBot?

TTMediaBot is an audio playback bot developed for **TeamTalk**, a VoIP and conferencing system commonly used for voice chat, streaming, and accessible communication.

Key features of TTMediaBot include:

* Playing audio from YouTube, local files, streaming URLs, and other services.
* Controlling playback using TeamTalk chat commands.
* Supporting playlists, seeking, volume control, and fading.
* Integrating with multiple streaming providers such as Yandex, VK, and YouTube.
* Extensible Python-based architecture.

TTMediaBot is created and maintained by **gumerov-amir**, and the original repository can be found here:
[https://github.com/gumerov-amir/TTMediaBot](https://github.com/gumerov-amir/TTMediaBot)

The script in this repository does not modify the original TTMediaBot project; it simply provides an automated and user-friendly Docker-based runtime environment.

---

## Features

* No manual image build required.
* Automatically installs Docker (Debian/Ubuntu) if missing.
* Automatically pulls the TTMediaBot image from Docker Hub.
* Supports multiple bot instances, each with separate configuration.
* Simple commands:

  * `new`, `run`, `stop`, `logs`, `ls`, `pull`, `ps`
* Supports version-based image selection via `TTMB_TAG`.
* Automatically applies correct file ownership for runtime safety.
* Support for resource limiting (CPU/Memory).


---

## Requirements

* Linux environment (tested on Debian and Ubuntu).
* Root or sudo access.
* systemd (used for controlling Docker service).
* Internet connection to pull the Docker image.
* Docker installed (or allow script to install it automatically).

---

## Installation

### Clone the repository

```bash
git clone https://github.com/MuhammadGagah/ttmediabot-docker-helper.git
cd ttmediabot-docker-helper
```

### Make the script executable

```bash
chmod +x tthelper.sh
```

---

## Quick Start

### Pull the Docker image (optional)

```bash
sudo ./tthelper.sh pull
```

This step is optional.
If the image does not exist locally, it will be pulled automatically when running a bot.

Default image:

```
mgagah21/ttmediabot:latest
```

---

## Creating a New Bot Instance

```bash
sudo ./tthelper.sh new
```

You will be asked for:

* Bot folder name (also the container name)
* Nickname
* Gender
* TeamTalk hostname
* TCP/UDP ports
* Username and password (optional)
* Channel and password

After completion, a folder will be created:

```
my_bot/
  config.json
  cookies.txt
```

Paste your cookies when prompted and press Ctrl+D.

---

## Running a Bot

```bash
sudo ./tthelper.sh run my_bot
```

The script will:

* Ensure Docker is running
* Ensure the image exists (auto-pull if needed)
* Fix internal folder permissions
* Start the bot container with:

  * host networking
  * volume mount: `./my_bot:/home/ttbot/data`

The container continues running in the background.

---

## Viewing Logs

```bash
sudo ./tthelper.sh logs my_bot
```

Press Ctrl+C to exit log monitoring.

---

## Stopping a Bot

```bash
sudo ./tthelper.sh stop my_bot
```

Stops and removes the container but keeps your folder and config.

---

## Limiting Resources via Docker

You can limit the CPU and Memory usage for a bot using the `limit` command.

```bash
sudo ./tthelper.sh limit my_bot
```

You will be prompted to enter:
* **CPU Limit**: e.g., `0.5` (half a core) or empty to unset
* **Memory Limit**: e.g., `512m` (512 MB) or empty to unset

This creates a `limit.txt` file in the bot folder containing the Docker flags. The script automatically applies these limits whenever you run the bot.

---


## Listing Bot Folders

```bash
sudo ./tthelper.sh ls
```

Example output:

```
Bot folders next to this script:
my_bot
music_test
another_bot
```

---

## Listing Containers Using The Image

```bash
sudo ./tthelper.sh ps
```

---

## Using Specific Image Versions

Default tag:

```
latest
```

Override using `TTMB_TAG`:

### Running version v19.0

```bash
sudo TTMB_TAG=v19.0 ./tthelper.sh run my_bot
```

### Pulling version v19.0

```bash
sudo TTMB_TAG=v19.0 ./tthelper.sh pull
```

This allows testing new versions without affecting existing setups.

---

## Command Summary

```
./tthelper.sh new              Create a new bot folder
./tthelper.sh run <folder>     Run a bot container
./tthelper.sh stop <name>      Stop and remove a bot container
./tthelper.sh logs <name>      Show logs of a bot
./tthelper.sh ls               List bot folders
./tthelper.sh pull             Pull or verify the TTMediaBot image
./tthelper.sh ps               List containers using the image
./tthelper.sh limit <folder>   Set resource limits (CPU/Memory)


Environment:
TTMB_TAG                       Override image tag (default: latest)
```

---

## Recommended Repository Structure

```
ttmediabot-docker-helper/
  tthelper.sh
  README.md
  LICENSE
  my_bot/
    config.json
    cookies.txt
  another_bot/
    config.json
    cookies.txt
```

---

## Contributing

Contributions of any kind are welcome.

### Create an Issue

Use the GitHub Issues tab to:

* Report bugs
* Suggest improvements
* Request new features
* Ask questions

### Submit a Pull Request

1. Fork this repository
2. Create a new branch
3. Make your changes
4. Push to your fork
5. Open a Pull Request with a clear description

---

## License

This project is licensed under the MIT License.
