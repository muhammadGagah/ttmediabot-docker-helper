#!/bin/bash
set -eu

export DOCKER_BUILDKIT=1
IMAGE_REPO="mgagah21/ttmediabot"
IMAGE_TAG="${TTMB_TAG:-latest}"
IMAGE_NAME="${IMAGE_REPO}:${IMAGE_TAG}"

command_exists() { command -v "$1" >/dev/null 2>&1; }

need_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "Please run this script as root (use sudo)."
    exit 1
  fi
}

detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
  else
    echo "Unable to detect operating system."
    exit 1
  fi
}

install_docker() {
  if command_exists docker; then
    echo "Docker already installed."
    return
  fi
  echo "Installing Docker..."
  detect_os
  if [[ "$OS" == "debian" || "$OS" == "ubuntu" ]]; then
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${OS}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS} \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
    echo "Docker installed."
  else
    echo "Unsupported OS ($OS). Please install Docker manually."
    exit 1
  fi
}

ensure_docker_running() {
  if ! systemctl is-active --quiet docker; then
    echo "Starting Docker..."
    systemctl start docker
  fi
}

ensure_image_exists() {
  if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Image $IMAGE_NAME not found locally, pulling..."
    docker pull "$IMAGE_NAME"
  else
    echo "Image $IMAGE_NAME already available locally."
  fi
}

create_bot_dir() {
  local BOT_NAME NICKNAME GENDER HOSTNAME TCP_PORT UDP_PORT USERNAME PASSWORD CHANNEL CHANNEL_PASSWORD
  read -rp "New bot folder (container name): " BOT_NAME
  if [[ -z "${BOT_NAME}" ]]; then
    echo "Bot name cannot be empty."; exit 1
  fi
  local BOT_DIR="./${BOT_NAME}"
  if [[ -d "$BOT_DIR" ]]; then
    echo "Error: directory '$BOT_DIR' already exists."; exit 1
  fi
  mkdir -p "$BOT_DIR"

  read -rp "Nickname (e.g. TTMediaBot): " NICKNAME
  read -rp "Gender (m/f/n): " GENDER
  read -rp "TeamTalk hostname (default: localhost): " HOSTNAME; HOSTNAME=${HOSTNAME:-localhost}
  read -rp "TCP port (default: 10333): " TCP_PORT; TCP_PORT=${TCP_PORT:-10333}
  read -rp "UDP port (default: 10333): " UDP_PORT; UDP_PORT=${UDP_PORT:-10333}
  read -rp "Username (optional): " USERNAME
  read -rp "Password (optional): " PASSWORD
  read -rp "Channel (default: /): " CHANNEL; CHANNEL=${CHANNEL:-/}
  read -rp "Channel password (optional): " CHANNEL_PASSWORD

cat > "$BOT_DIR/config.json" <<EOL
{
    "config_version": 0,
    "general": {
        "language": "en",
        "send_channel_messages": false,
        "cache_file_name": "TTMediaBotCache.dat",
        "blocked_commands": [],
        "delete_uploaded_files_after": 300,
        "time_format": "%H:%M",
        "start_commands": []
    },
    "sound_devices": {
        "output_device": 1,
        "input_device": 5
    },
    "player": {
        "default_volume": 50,
        "max_volume": 100,
        "volume_fading": true,
        "volume_fading_interval": 0.025,
        "seek_step": 5,
        "player_options": {}
    },
    "teamtalk": {
        "hostname": "${HOSTNAME}",
        "tcp_port": ${TCP_PORT},
        "udp_port": ${UDP_PORT},
        "encrypted": false,
        "nickname": "${NICKNAME}",
        "status": "",
        "gender": "${GENDER}",
        "username": "${USERNAME}",
        "password": "${PASSWORD}",
        "channel": "${CHANNEL}",
        "channel_password": "${CHANNEL_PASSWORD}",
        "license_name": "",
        "license_key": "",
        "reconnection_attempts": -1,
        "reconnection_timeout": 10,
        "users": {
            "admins": [
                "admin"
            ],
            "banned_users": []
        },
        "event_handling": {
            "load_event_handlers": false,
            "event_handlers_file_name": "event_handlers.py"
        }
    },
    "services": {
        "default_service": "yt",
        "vk": {
            "enabled": true,
            "token": ""
        },
        "yam": {
            "enabled": true,
            "token": ""
        },
        "yt": {
            "enabled": true,
            "cookiefile_path": "/home/ttbot/data/cookies.txt"
        }
    },
    "logger": {
        "log": true,
        "level": "INFO",
        "format": "%(levelname)s [%(asctime)s]: %(message)s in %(threadName)s file: %(filename)s line %(lineno)d function %(funcName)s",
        "mode": "FILE",
        "file_name": "TTMediaBot.log",
        "max_file_size": 0,
        "backup_count": 0
    },
    "shortening": {
        "shorten_links": false,
        "service": "clckru",
        "service_params": {}
    }
}
EOL

  echo "Paste your cookies below (Press CTRL+D to save):"
  cat > "$BOT_DIR/cookies.txt"

  echo "Bot folder created at: $BOT_DIR"
  echo "Run it with: $0 run ${BOT_NAME}"
}

run_bot_from_dir() {
  local DIR="$1"
  if [[ -z "$DIR" ]]; then
    echo "Usage: $0 run <folder_name>"; exit 1
  fi
  local BOT_DIR="./${DIR}"
  if [[ ! -d "$BOT_DIR" ]]; then
    echo "Folder '$BOT_DIR' not found (it must be next to this script)."; exit 1
  fi
  ensure_image_exists

  local NAME
  NAME="$(basename "$DIR")"

  local DOCKER_LIMITS=""
  if [[ -f "$BOT_DIR/limit.txt" ]]; then
    DOCKER_LIMITS=$(cat "$BOT_DIR/limit.txt")
    echo "Applying resource limits: $DOCKER_LIMITS"
  fi

  docker run --rm --network host -v "${BOT_DIR}:/home/ttbot/data" --user root "$IMAGE_NAME" \
    chown -R ttbot:ttbot /home/ttbot/data

  docker run -d \
    --name "$NAME" \
    --network host \
    --restart unless-stopped \
    ${DOCKER_LIMITS} \
    -v "${BOT_DIR}:/home/ttbot/data" \
    "$IMAGE_NAME"

  echo "Container '$NAME' started with host networking, using data dir: $BOT_DIR"
}

stop_bot() {
  local NAME="$1"
  if [[ -z "$NAME" ]]; then echo "Usage: $0 stop <container_name>"; exit 1; fi
  docker rm -f "$NAME" || true
  echo "Stopped (and removed) container: $NAME"
}

logs_bot() {
  local NAME="$1"
  if [[ -z "$NAME" ]]; then echo "Usage: $0 logs <container_name>"; exit 1; fi
  docker logs -f "$NAME"
}

limit_bot() {
  local NAME="$1"
  if [[ -z "$NAME" ]]; then echo "Usage: $0 limit <folder_name>"; exit 1; fi
  local BOT_DIR="./${NAME}"
  if [[ ! -d "$BOT_DIR" ]]; then echo "Folder '$BOT_DIR' not found."; exit 1; fi

  local CPU_LIMIT MEM_LIMIT
  read -rp "Enter CPU limit (e.g., 0.5 for half core, or empty to unset): " CPU_LIMIT
  read -rp "Enter Memory limit (e.g., 512m, 1g, or empty to unset): " MEM_LIMIT

  local LIMITS=""
  if [[ -n "$CPU_LIMIT" ]]; then
    LIMITS+="--cpus=${CPU_LIMIT} "
  fi
  if [[ -n "$MEM_LIMIT" ]]; then
    # If the user entered only numbers (e.g. 512), append 'm' (e.g. 512m).
    if [[ "$MEM_LIMIT" =~ ^[0-9]+$ ]]; then
      MEM_LIMIT="${MEM_LIMIT}m"
    fi
    LIMITS+="--memory=${MEM_LIMIT} "
  fi

  # Trim trailing space
  LIMITS=$(echo "$LIMITS" | xargs)

  if [[ -n "$LIMITS" ]]; then
    echo "$LIMITS" > "$BOT_DIR/limit.txt"
    echo "Limits saved to $BOT_DIR/limit.txt: $LIMITS"
  else
    if [[ -f "$BOT_DIR/limit.txt" ]]; then
      rm "$BOT_DIR/limit.txt"
      echo "Limits cleared (limit.txt removed)."
    else
      echo "No limits specified and no existing limit file to remove."
    fi
  fi
}

list_bot_dirs() {
  echo "Bot folders next to this script:"
  find . -maxdepth 1 -type d ! -name '.*' ! -name 'docker' -printf "%f\n" | tail -n +2
}

list_bot_containers() {
  echo "Containers using image $IMAGE_NAME:"
  docker ps -a --filter "ancestor=$IMAGE_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"
}

need_root
install_docker
ensure_docker_running

CMD="${1:-}"
case "${CMD}" in
  new)
    create_bot_dir
    ;;
  run)
    shift || true
    run_bot_from_dir "${1:-}"
    ;;
  stop)
    shift || true
    stop_bot "${1:-}"
    ;;
  logs)
    shift || true
    logs_bot "${1:-}"
    ;;
  ls)
    list_bot_dirs
    ;;
  pull)
    ensure_image_exists
    ;;
  ps)
    list_bot_containers
    ;;
  limit)
    shift || true
    limit_bot "${1:-}"
    ;;
  *)
    cat <<USAGE
Usage:
  $0 new              Create a new bot folder (config.json + cookies.txt)
  $0 run <folder>     Run container using folder (next to this script), container name = folder
  $0 stop <name>      Stop & remove container by name
  $0 logs <name>      Tail logs from container
  $0 ls               List bot folders adjacent to this script
  $0 pull             Pull or verify Docker image ($IMAGE_NAME)
  $0 pull             Pull or verify Docker image ($IMAGE_NAME)
  $0 ps               List containers using image $IMAGE_NAME
  $0 limit <folder>   Set resource limits (CPU/Memory) for a bot folder

Env:
  TTMB_TAG            Override image tag (default: $IMAGE_TAG)

Examples:
  sudo $0 pull
  sudo $0 new
  sudo $0 run ttbot
  sudo $0 logs ttbot
  sudo TTMB_TAG=v19.0 $0 run mybot
USAGE
    ;;
esac
