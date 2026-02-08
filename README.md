# TTMediaBot Docker Helper

This repository provides `tthelper.sh`, a command-line helper script designed to run **TTMediaBot** inside Docker without requiring users to build Docker images manually.
The script automatically pulls the prebuilt TTMediaBot image from Docker Hub, creates isolated bot instances, and manages containers in a clean and convenient way.

---

## What is TTMediaBot?

TTMediaBot is an audio playback bot developed for **TeamTalk**, a VoIP and conferencing system commonly used for voice chat, streaming, and accessible communication.

Key features of TTMediaBot include:
*   Playing audio from YouTube, local files, streaming URLs, and other services.
*   Controlling playback using TeamTalk chat commands.
*   Supporting playlists, seeking, volume control, and fading.
*   Extensible Python-based architecture.

TTMediaBot is created and maintained by **gumerov-amir**, and the original repository can be found here:
[https://github.com/gumerov-amir/TTMediaBot](https://github.com/gumerov-amir/TTMediaBot)

The script in this repository does not modify the original TTMediaBot project, it simply provides an automated and user-friendly Docker-based runtime environment.

---

## Features

*   **No manual image build required**: Automatically pulls the prebuilt image.
*   **Easy Setup**: Installs Docker (Debian/Ubuntu) if missing.
*   **Multi-Bot Support**: Run multiple bots with separate configurations and cookies.
*   **Resource Control**: Limit CPU and Memory usage per bot.
*   **Simple Commands**: Intuitive commands to create, run, and manage bots.

---

## Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/MuhammadGagah/ttmediabot-docker-helper.git
    cd ttmediabot-docker-helper
    ```

2.  **Make the script executable**:
    ```bash
    chmod +x tthelper.sh
    ```

---

## User Guide

### 1. Create a New Bot
Use the `new` command to create a config folder.

```bash
sudo ./tthelper.sh new
```
*   You will be asked for bot details (nickname, server, ports, etc.).
*   Paste your cookies when prompted.
*   **Safe Creation**: The folder and config files are only created *after* you finish entering all information.

### 2. Run a Bot
Use the `run` command to start a bot using an **existing configuration folder**.

```bash
sudo ./tthelper.sh run <folder_name>
```
*   **Example**: `sudo ./tthelper.sh run my_bot`
*   **Function**:
    *   Finds the folder (e.g., `my_bot`) in the current directory.
    *   Creates and starts a Docker container with the same name.
    *   Mounts the folder so the bot uses your `config.json` and `cookies.txt`.

### 3. Manage Bots
*   **Stop a bot**:
    ```bash
    sudo ./tthelper.sh stop <container_name>
    ```
    Stops and removes the container. Your config and data folder remain safe.

*   **View logs**:
    ```bash
    sudo ./tthelper.sh logs <container_name>
    ```
    Press `Ctrl+C` to exit.

*   **List all bot folders**:
    ```bash
    sudo ./tthelper.sh ls
    ```

*   **List running containers**:
    ```bash
    sudo ./tthelper.sh ps
    ```

### 4. Manage Cookies
Update `cookies.txt` easily without manually editing files.

*   **Update one bot**:
    ```bash
    sudo ./tthelper.sh cks <folder_name>
    ```
    Paste new cookies and press `Ctrl+D`.

*   **Update ALL bots**:
    ```bash
    sudo ./tthelper.sh cks-all
    ```
    Updates cookies for **every** bot folder associated with the image.

### 5. Updates & Maintenance
*   **Update Bot Dependencies**:
    ```bash
    sudo ./tthelper.sh update
    ```
    Updates `pip` requirements in **all running bots** and restarts them.

*   **Limit Resources** (CPU/RAM):
    ```bash
    sudo ./tthelper.sh limit <folder_name>
    ```
    Sets limits (e.g., `0.5` CPU, `512m` RAM). Applied automatically on the next `run`.

*   **Update Docker Image**:
    ```bash
    sudo ./tthelper.sh pull
    ```
    Downloads the latest version of `mgagah21/ttmediabot`.

---

## Contributing
Contributions are welcome! Please open an issue or pull request on [GitHub](https://github.com/MuhammadGagah/ttmediabot-docker-helper).

## License
This project is licensed under the MIT License.
