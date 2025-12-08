#!/bin/bash

# scripts/manage-services.sh

# Get the absolute path to the project root (one level up from scripts/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"

# Function to start the proxy
start_proxy() {
    echo "------------------------------------------------"
    echo "Starting Nginx Proxy Manager..."
    echo "------------------------------------------------"
    if [ -f "$DOCKER_DIR/proxy/docker-compose.yml" ]; then
        docker compose -f "$DOCKER_DIR/proxy/docker-compose.yml" up -d
        if [ $? -eq 0 ]; then
            echo "✅ Proxy started successfully."
        else
            echo "❌ Failed to start Proxy."
            exit 1
        fi
    else
        echo "❌ Proxy configuration not found at $DOCKER_DIR/proxy/docker-compose.yml"
        exit 1
    fi
}

# Function to start all other services
start_services() {
    echo "------------------------------------------------"
    echo "Starting other application services..."
    echo "------------------------------------------------"
    
    # Iterate through all subdirectories in docker/
    for dir in "$DOCKER_DIR"/*/; do
        dirname=$(basename "$dir")
        
        # Skip proxy (already started)
        if [ "$dirname" == "proxy" ]; then
            continue
        fi

        if [ -f "$dir/docker-compose.yml" ]; then
            echo "🚀 Starting $dirname..."
            docker compose -f "$dir/docker-compose.yml" up -d
        else
            echo "⚠️  No docker-compose.yml found in $dirname, skipping."
        fi
    done
    echo "------------------------------------------------"
    echo "✅ All services startup sequence completed."
    echo "------------------------------------------------"
}

# Function to stop all services except proxy
stop_services() {
    echo "------------------------------------------------"
    echo "Stopping all services (EXCEPT Nginx Proxy)..."
    echo "------------------------------------------------"
    
    for dir in "$DOCKER_DIR"/*/; do
        dirname=$(basename "$dir")
        
        # Skip proxy
        if [ "$dirname" == "proxy" ]; then
            echo "🛡️  Skipping Proxy (keeping it alive)..."
            continue
        fi

        if [ -f "$dir/docker-compose.yml" ]; then
            echo "🛑 Stopping $dirname..."
            docker compose -f "$dir/docker-compose.yml" down
        fi
    done
    echo "------------------------------------------------"
    echo "✅ Services stopped."
    echo "------------------------------------------------"
}

# Function to stop EVERYTHING including proxy
stop_all() {
    echo "------------------------------------------------"
    echo "Stopping ALL services (INCLUDING Proxy)..."
    echo "------------------------------------------------"
    
    for dir in "$DOCKER_DIR"/*/; do
        dirname=$(basename "$dir")
        if [ -f "$dir/docker-compose.yml" ]; then
            echo "🛑 Stopping $dirname..."
            docker compose -f "$dir/docker-compose.yml" down
        fi
    done
}

# Main logic
case "$1" in
    start)
        # Ensure proxy is up first, then others
        start_proxy
        # Optional: wait a moment for network creation if needed
        sleep 2
        start_services
        ;;
    stop-apps)
        stop_services
        ;;
    stop-all)
        stop_all
        ;;
    restart-apps)
        stop_services
        start_services
        ;;
    *)
        echo "Usage: $0 {start|stop-apps|stop-all|restart-apps}"
        echo ""
        echo "Commands:"
        echo "  start         - Starts Proxy first, then all other services."
        echo "  stop-apps     - Stops all services but KEEPS Proxy running."
        echo "  stop-all      - Stops EVERYTHING including Proxy."
        echo "  restart-apps  - Restarts all apps (stops them, then starts them), keeps Proxy running."
        exit 1
        ;;
esac
