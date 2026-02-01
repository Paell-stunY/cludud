#!/bin/bash
# RIELLIONA AI - COMPLETE INSTALLER WITH MONITORING & UNINSTALL
# One Script to Rule Them All

set -e

# ============================================
# CONFIGURATION
# ============================================
SCRIPT_VERSION="3.0"
INSTALL_DIR="/opt/rielliona"
LOG_FILE="/var/log/rielliona-installer.log"
CONFIG_FILE="$INSTALL_DIR/installer-config.conf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================
# FUNCTIONS
# ============================================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}[i]${NC} $1" | tee -a "$LOG_FILE"
}

header() {
    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║            $1${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Harus run sebagai root!"
        echo "Gunakan: sudo bash $0"
        exit 1
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << CONFIG
# RIELLIONA AI Configuration
DOMAIN="$DOMAIN"
EMAIL="$EMAIL"
MODEL="$MODEL"
MODEL_NAME="$MODEL_NAME"
INSTALL_MODE="$INSTALL_MODE"
INSTALL_DATE="$(date)"
SCRIPT_VERSION="$SCRIPT_VERSION"
CONFIG
    chmod 600 "$CONFIG_FILE"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

# ============================================
# UNINSTALL FUNCTION
# ============================================

uninstall_rielliona() {
    header "UNINSTALL RIELLIONA AI"
    
    warning "⚠️  Ini akan menghapus SEMUA data RIELLIONA AI!"
    echo ""
    echo "Yang akan dihapus:"
    echo "  • Semua AI models"
    echo "  • Chat history"
    echo "  • Konfigurasi"
    echo "  • Database monitoring"
    echo "  • User data"
    echo ""
    read -p "Yakin ingin uninstall? (ketik 'YA' untuk konfirmasi): " confirm
    
    if [ "$confirm" != "YA" ]; then
        error "Uninstall dibatalkan!"
        exit 0
    fi
    
    log "Memulai uninstall..."
    
    # Stop semua services
    log "Menghentikan services..."
    systemctl stop rielliona-api rielliona-monitor ollama 2>/dev/null || true
    systemctl disable rielliona-api rielliona-monitor ollama 2>/dev/null || true
    
    # Hapus services
    log "Menghapus service files..."
    rm -f /etc/systemd/system/rielliona-api.service
    rm -f /etc/systemd/system/rielliona-monitor.service
    rm -f /etc/systemd/system/ollama.service
    
    # Hapus Nginx config
    log "Menghapus Nginx configuration..."
    rm -f /etc/nginx/sites-available/rielliona
    rm -f /etc/nginx/sites-enabled/rielliona
    rm -f /etc/nginx/.htpasswd
    
    # Restore default nginx jika ada
    if [ -f /etc/nginx/sites-available/default.bak ]; then
        cp /etc/nginx/sites-available/default.bak /etc/nginx/sites-available/default
    fi
    
    # Hapus Ollama dan models
    log "Menghapus Ollama dan models..."
    if command -v ollama &> /dev/null; then
        ollama ps 2>/dev/null | grep -v "NAME" | awk '{print $1}' | xargs -I {} ollama rm {} 2>/dev/null || true
    fi
    rm -rf /root/.ollama
    
    # Hapus application files
    log "Menghapus application files..."
    rm -rf "$INSTALL_DIR"
    rm -rf /var/www/rielliona
    rm -rf /var/log/rielliona
    
    # Hapus management scripts
    log "Menghapus management scripts..."
    rm -f /usr/local/bin/rielliona-*
    
    # Hapus logrotate
    rm -f /etc/logrotate.d/rielliona
    
    # Hapus cron jobs
    log "Menghapus cron jobs..."
    crontab -l 2>/dev/null | grep -v "rielliona\|certbot" | crontab - 2>/dev/null || true
    
    # Reload services
    systemctl daemon-reload
    systemctl reset-failed
    nginx -t && systemctl restart nginx
    
    # Hapus SSL certificate jika ada
    if [ -n "$DOMAIN" ] && [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        log "Menghapus SSL certificate..."
        certbot delete --cert-name "$DOMAIN" --non-interactive 2>/dev/null || true
    fi
    
    # Hapus installer config
    rm -f "$CONFIG_FILE"
    
    success "✅ UNINSTALL COMPLETE!"
    echo ""
    echo "Semua file RIELLIONA AI telah dihapus."
    echo "System telah dikembalikan ke state sebelum install."
    echo ""
    echo "Note:"
    echo "  • Manual reboot direkomendasikan"
    echo "  • Cek dengan: systemctl list-units | grep rielliona"
    echo "  • Pastikan tidak ada service yang tersisa"
    
    exit 0
}

# ============================================
# INSTALLATION FUNCTIONS
# ============================================

install_dependencies() {
    header "INSTALLING DEPENDENCIES"
    
    log "Updating system packages..."
    apt update && apt upgrade -y
    
    log "Installing required packages..."
    apt install -y \
        build-essential \
        python3-pip \
        python3-venv \
        git \
        curl \
        wget \
        htop \
        nginx \
        certbot \
        python3-certbot-nginx \
        fail2ban \
        ufw \
        jq \
        net-tools \
        openssl \
        pkg-config \
        libssl-dev \
        ca-certificates
    
    success "Dependencies installed"
}

setup_firewall() {
    log "Configuring firewall..."
    ufw allow OpenSSH
    ufw allow 'Nginx Full'
    ufw --force enable
    success "Firewall configured"
}

setup_swap() {
    log "Setting up swap file..."
    if [ ! -f /swapfile ]; then
        total_ram=$(free -g | grep Mem | awk '{print $2}')
        swap_size=$((total_ram * 2))
        
        if [ $swap_size -gt 32 ]; then
            swap_size=32
        fi
        
        log "Creating ${swap_size}GB swap file..."
        fallocate -l ${swap_size}G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        
        # Optimize
        sysctl vm.swappiness=10
        sysctl vm.vfs_cache_pressure=50
        echo 'vm.swappiness=10' >> /etc/sysctl.conf
        echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
        sysctl -p
        
        success "${swap_size}GB swap file created"
    else
        warning "Swap file already exists"
    fi
}

install_ollama() {
    header "INSTALLING OLLAMA AI ENGINE"
    
    log "Downloading Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
    
    log "Configuring Ollama service..."
    cat > /etc/systemd/system/ollama.service << OLLAMA_SERVICE
[Unit]
Description=Ollama AI Service
After=network.target

[Service]
Type=simple
User=root
Environment="OLLAMA_NUM_PARALLEL=4"
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ollama
LimitNOFILE=65536
LimitAS=infinity
LimitRSS=infinity
LimitCORE=infinity
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
OLLAMA_SERVICE
    
    systemctl daemon-reload
    systemctl enable ollama
    systemctl start ollama
    
    success "Ollama installed and running"
}

download_model() {
    header "DOWNLOADING AI MODEL"
    
    log "Pulling model: $MODEL_NAME"
    echo "This may take 5-15 minutes depending on model size..."
    
    # Show progress
    ollama pull "$MODEL" 2>&1 | while IFS= read -r line; do
        if [[ $line == *"pulling"* ]] || [[ $line == *"downloading"* ]]; then
            echo -ne "${CYAN}${line##* }${NC}\r"
        fi
    done
    
    echo ""
    success "Model downloaded: $MODEL"
    
    # Verify model
    log "Verifying model..."
    if ollama list | grep -q "$MODEL"; then
        success "Model verified successfully"
    else
        error "Model verification failed!"
        exit 1
    fi
}

setup_python_env() {
    header "SETTING UP PYTHON ENVIRONMENT"
    
    log "Creating virtual environment..."
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    python3 -m venv venv
    source venv/bin/activate
    
    log "Installing Python packages..."
    pip install --upgrade pip
    pip install fastapi uvicorn aiohttp psutil python-multipart pydantic
    
    success "Python environment ready"
}

create_api_server() {
    header "CREATING API SERVER"
    
    cat > "$INSTALL_DIR/api.py" << 'API_PY'
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import aiohttp
import asyncio
import json
import os
import psutil
from datetime import datetime
import logging
import socket

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/rielliona/api.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = FastAPI(title="RIELLIONA AI", version="3.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
CONFIG = {
    "ollama_url": "http://localhost:11434",
    "model": os.environ.get("MODEL", "llama3.2:3b-instruct-q4_K_M"),
    "system_prompt": """Kamu adalah RIELLIONA AI, asisten pribadi untuk Tuan rielliona.
Layanan ini berjalan di VPS DigitalOcean.
Gunakan bahasa Indonesia untuk percakapan umum.
Untuk kode programming, gunakan bahasa yang tepat.
Jawab dengan singkat dan langsung ke inti."""
}

class ChatRequest(BaseModel):
    message: str
    stream: bool = False

def get_client_ip(request: Request):
    """Get real client IP"""
    if "x-forwarded-for" in request.headers:
        return request.headers["x-forwarded-for"].split(",")[0]
    return request.client.host if request.client else "unknown"

def log_interaction(ip: str, message: str, response: str, status: str):
    """Log user interaction"""
    try:
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "ip": ip,
            "message": message[:200],
            "response_length": len(response),
            "status": status
        }
        
        # Write to log file
        os.makedirs("/var/log/rielliona", exist_ok=True)
        with open("/var/log/rielliona/interactions.log", "a") as f:
            f.write(json.dumps(log_entry) + "\n")
            
        # Send to monitoring if available
        try:
            asyncio.create_task(
                send_to_monitor(log_entry)
            )
        except:
            pass
            
    except Exception as e:
        logger.error(f"Failed to log interaction: {e}")

async def send_to_monitor(data: dict):
    """Send data to monitoring service"""
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(
                "http://localhost:5001/monitor/log",
                json=data,
                timeout=1
            ):
                pass
    except:
        pass

@app.get("/")
async def root():
    return {
        "status": "online",
        "service": "RIELLIONA AI",
        "owner": "rielliona",
        "model": CONFIG["model"],
        "version": "3.0",
        "endpoints": {
            "chat": "POST /chat",
            "status": "GET /status",
            "docs": "GET /docs"
        }
    }

@app.post("/chat")
async def chat(request: Request, chat_request: ChatRequest):
    start_time = datetime.now()
    client_ip = get_client_ip(request)
    
    logger.info(f"Chat request from {client_ip}: {chat_request.message[:50]}...")
    
    try:
        # Prepare prompt
        full_prompt = f"{CONFIG['system_prompt']}\n\nUser: {chat_request.message}\nAssistant:"
        
        # Call Ollama
        async with aiohttp.ClientSession() as session:
            payload = {
                "model": CONFIG["model"],
                "prompt": full_prompt,
                "stream": chat_request.stream,
                "options": {
                    "num_predict": 2048,
                    "temperature": 0.7,
                    "num_ctx": 4096,
                    "num_thread": 4
                }
            }
            
            async with session.post(
                f"{CONFIG['ollama_url']}/api/generate",
                json=payload,
                timeout=aiohttp.ClientTimeout(total=300)
            ) as response:
                
                if response.status != 200:
                    error_text = await response.text()
                    logger.error(f"Ollama error: {error_text}")
                    raise HTTPException(500, f"AI Engine error: {error_text[:100]}")
                
                if chat_request.stream:
                    # Streaming response
                    async def generate():
                        async for chunk in response.content:
                            if chunk:
                                yield chunk
                    return generate()
                    
                else:
                    # Single response
                    data = await response.json()
                    ai_response = data.get("response", "")
                    
                    # Log interaction
                    log_interaction(
                        ip=client_ip,
                        message=chat_request.message,
                        response=ai_response,
                        status="success"
                    )
                    
                    # Calculate processing time
                    process_time = (datetime.now() - start_time).total_seconds()
                    
                    return {
                        "response": ai_response,
                        "model": CONFIG["model"],
                        "tokens": data.get("eval_count", 0),
                        "processing_time": round(process_time, 2),
                        "status": "success"
                    }
                    
    except asyncio.TimeoutError:
        logger.error(f"Timeout from {client_ip}")
        log_interaction(client_ip, chat_request.message, "", "timeout")
        raise HTTPException(408, "Request timeout")
        
    except Exception as e:
        logger.error(f"Error from {client_ip}: {str(e)}")
        log_interaction(client_ip, chat_request.message, "", "error")
        raise HTTPException(500, f"Internal error: {str(e)}")

@app.get("/status")
async def system_status():
    """System status endpoint"""
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    return {
        "status": "online",
        "timestamp": datetime.now().isoformat(),
        "system": {
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory_percent": mem.percent,
            "memory_available_gb": round(mem.available / (1024**3), 2),
            "disk_percent": disk.percent,
            "disk_free_gb": round(disk.free / (1024**3), 2)
        },
        "service": {
            "model": CONFIG["model"],
            "owner": "rielliona",
            "hostname": socket.gethostname()
        }
    }

@app.get("/api/models")
async def list_models():
    """List available models"""
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{CONFIG['ollama_url']}/api/tags") as response:
                if response.status == 200:
                    data = await response.json()
                    return {"models": data.get("models", [])}
                return {"models": []}
    except:
        return {"models": []}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000, workers=2)
API_PY

    # Create API service
    cat > /etc/systemd/system/rielliona-api.service << API_SERVICE
[Unit]
Description=RIELLIONA AI API Server
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$INSTALL_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="MODEL=$MODEL"
ExecStart=$INSTALL_DIR/venv/bin/uvicorn api:app --host 0.0.0.0 --port 5000 --workers 2
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=rielliona-api
LimitNOFILE=65536
LimitCORE=infinity
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
API_SERVICE
    
    systemctl daemon-reload
    systemctl enable rielliona-api
    
    success "API server created"
}

create_monitoring_system() {
    header "CREATING MONITORING SYSTEM"
    
    log "Creating monitoring directory..."
    mkdir -p "$INSTALL_DIR/monitoring"
    mkdir -p /var/log/rielliona/monitor
    
    # Create monitoring database
    cat > "$INSTALL_DIR/monitoring/db.json" << MONITOR_DB
{
    "system": {
        "installed": "$(date -Iseconds)",
        "model": "$MODEL",
        "domain": "$DOMAIN"
    },
    "stats": {
        "total_requests": 0,
        "successful_requests": 0,
        "failed_requests": 0,
        "unique_ips": 0,
        "total_tokens": 0
    },
    "users": {},
    "commands": []
}
MONITOR_DB
    
    # Create monitoring API
    cat > "$INSTALL_DIR/monitoring.py" << 'MONITOR_PY'
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from datetime import datetime, timedelta
import json
import os
import psutil
from typing import Dict, List
import socket
import subprocess
import logging

app = FastAPI(title="RIELLIONA Monitoring", version="2.0")

# Setup
MONITOR_DIR = "/opt/rielliona/monitoring"
LOG_DIR = "/var/log/rielliona/monitor"
DB_FILE = os.path.join(MONITOR_DIR, "db.json")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(LOG_DIR, 'monitor.log')),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def load_db():
    if os.path.exists(DB_FILE):
        try:
            with open(DB_FILE, 'r') as f:
                return json.load(f)
        except:
            pass
    return {"stats": {}, "users": {}, "commands": []}

def save_db(data):
    os.makedirs(MONITOR_DIR, exist_ok=True)
    with open(DB_FILE, 'w') as f:
        json.dump(data, f, indent=2)

@app.post("/monitor/log")
async def log_command(request: Request):
    """Log a command from API server"""
    try:
        data = await request.json()
        db = load_db()
        
        ip = data.get("ip", "unknown")
        message = data.get("message", "")
        status = data.get("status", "unknown")
        
        # Update stats
        db["stats"]["total_requests"] = db["stats"].get("total_requests", 0) + 1
        
        if status == "success":
            db["stats"]["successful_requests"] = db["stats"].get("successful_requests", 0) + 1
        else:
            db["stats"]["failed_requests"] = db["stats"].get("failed_requests", 0) + 1
        
        # Update user
        if ip not in db["users"]:
            db["users"][ip] = {
                "first_seen": datetime.now().isoformat(),
                "last_seen": datetime.now().isoformat(),
                "total_commands": 0,
                "successful": 0,
                "failed": 0
            }
            db["stats"]["unique_ips"] = len(db["users"])
        
        db["users"][ip]["last_seen"] = datetime.now().isoformat()
        db["users"][ip]["total_commands"] = db["users"][ip].get("total_commands", 0) + 1
        
        if status == "success":
            db["users"][ip]["successful"] = db["users"][ip].get("successful", 0) + 1
        else:
            db["users"][ip]["failed"] = db["users"][ip].get("failed", 0) + 1
        
        # Add command
        command_entry = {
            "timestamp": datetime.now().isoformat(),
            "ip": ip,
            "message": message[:100],
            "status": status,
            "response_length": data.get("response_length", 0)
        }
        
        db["commands"].append(command_entry)
        
        # Keep only last 1000
        if len(db["commands"]) > 1000:
            db["commands"] = db["commands"][-1000:]
        
        save_db(db)
        
        # Also log to file
        log_file = os.path.join(LOG_DIR, f"commands_{datetime.now().strftime('%Y%m%d')}.log")
        with open(log_file, 'a') as f:
            f.write(f"{datetime.now().isoformat()} | {ip} | {status} | {message[:50]}\n")
        
        return {"status": "logged"}
        
    except Exception as e:
        logger.error(f"Failed to log command: {e}")
        raise HTTPException(500, "Internal error")

@app.get("/monitor/")
async def monitor_dashboard(request: Request):
    """Dashboard HTML"""
    db = load_db()
    
    # Get recent commands
    recent_commands = db.get("commands", [])[-20:]
    
    # Get top users
    users = db.get("users", {})
    top_users = sorted(
        [(ip, data) for ip, data in users.items()],
        key=lambda x: x[1].get("total_commands", 0),
        reverse=True
    )[:10]
    
    # System info
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    html = f'''
    <!DOCTYPE html>
    <html>
    <head>
        <title>RIELLIONA AI Monitor</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            * {{ margin: 0; padding: 0; box-sizing: border-box; }}
            body {{ 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: #0f172a; color: #f8fafc; line-height: 1.6;
                padding: 20px;
            }}
            .container {{ max-width: 1200px; margin: 0 auto; }}
            .header {{ 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 2rem; border-radius: 1rem; margin-bottom: 2rem;
                text-align: center;
            }}
            .stats-grid {{ 
                display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 1rem; margin-bottom: 2rem;
            }}
            .stat-card {{ 
                background: #1e293b; padding: 1.5rem; border-radius: 0.75rem;
                border-left: 4px solid #3b82f6;
            }}
            .stat-value {{ font-size: 2rem; font-weight: bold; color: #60a5fa; }}
            .stat-label {{ color: #94a3b8; font-size: 0.875rem; margin-top: 0.5rem; }}
            .table-container {{ 
                background: #1e293b; border-radius: 0.75rem; overflow: hidden;
                margin-bottom: 2rem;
            }}
            table {{ width: 100%; border-collapse: collapse; }}
            th {{ background: #334155; padding: 1rem; text-align: left; }}
            td {{ padding: 1rem; border-bottom: 1px solid #334155; }}
            .status-success {{ color: #10b981; }}
            .status-error {{ color: #ef4444; }}
            .status-timeout {{ color: #f59e0b; }}
            .refresh-btn {{ 
                background: #3b82f6; color: white; border: none;
                padding: 0.75rem 1.5rem; border-radius: 0.5rem;
                cursor: pointer; font-weight: bold; margin-bottom: 1rem;
            }}
            .refresh-btn:hover {{ background: #2563eb; }}
            .footer {{ 
                text-align: center; margin-top: 2rem; color: #64748b;
                font-size: 0.875rem;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🤖 RIELLIONA AI MONITORING</h1>
                <p>Real-time monitoring dashboard • {socket.gethostname()} • {datetime.now().strftime("%Y-%m-%d %H:%M")}</p>
            </div>
            
            <button class="refresh-btn" onclick="location.reload()">🔄 Refresh Dashboard</button>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-value">{db.get("stats", {}).get("total_requests", 0)}</div>
                    <div class="stat-label">Total Requests</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{db.get("stats", {}).get("unique_ips", 0)}</div>
                    <div class="stat-label">Unique Users</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{db.get("stats", {}).get("successful_requests", 0)}</div>
                    <div class="stat-label">Successful</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">{round(mem.percent, 1)}%</div>
                    <div class="stat-label">Memory Usage</div>
                </div>
            </div>
            
            <div class="table-container">
                <h3 style="padding: 1rem; background: #334155;">Recent Commands</h3>
                <table>
                    <thead>
                        <tr>
                            <th>Time</th>
                            <th>IP Address</th>
                            <th>Command</th>
                            <th>Status</th>
                            <th>Length</th>
                        </tr>
                    </thead>
                    <tbody>
                        {"".join([f'''
                        <tr>
                            <td>{datetime.fromisoformat(cmd["timestamp"]).strftime("%H:%M:%S")}</td>
                            <td>{cmd["ip"]}</td>
                            <td>{cmd["message"][:50]}{"..." if len(cmd["message"]) > 50 else ""}</td>
                            <td class="status-{cmd["status"]}">{cmd["status"].upper()}</td>
                            <td>{cmd.get("response_length", 0)} chars</td>
                        </tr>
                        ''' for cmd in reversed(recent_commands)])}
                    </tbody>
                </table>
            </div>
            
            <div class="table-container">
                <h3 style="padding: 1rem; background: #334155;">Top Users</h3>
                <table>
                    <thead>
                        <tr>
                            <th>IP Address</th>
                            <th>Total Commands</th>
                            <th>Success Rate</th>
                            <th>Last Seen</th>
                        </tr>
                    </thead>
                    <tbody>
                        {"".join([f'''
                        <tr>
                            <td>{ip}</td>
                            <td>{data.get("total_commands", 0)}</td>
                            <td>{round((data.get("successful", 0) / max(data.get("total_commands", 1), 1)) * 100, 1)}%</td>
                            <td>{datetime.fromisoformat(data.get("last_seen", "")).strftime("%Y-%m-%d %H:%M") if data.get("last_seen") else "N/A"}</td>
                        </tr>
                        ''' for ip, data in top_users])}
                    </tbody>
                </table>
            </div>
            
            <div class="footer">
                <p>RIELLIONA AI v3.0 • Model: {os.environ.get("MODEL", "N/A")} • Auto-refresh every 30 seconds</p>
                <p>© {datetime.now().year} RIELLIONA AI System • Powered by XANTSYSTEM</p>
            </div>
        </div>
        
        <script>
            // Auto-refresh every 30 seconds
            setTimeout(() => location.reload(), 30000);
            
            // Add click to copy IP
            document.querySelectorAll('td:nth-child(2)').forEach(td => {{
                td.style.cursor = 'pointer';
                td.title = 'Click to copy IP';
                td.onclick = function() {{
                    navigator.clipboard.writeText(this.textContent);
                    const original = this.textContent;
                    this.textContent = 'Copied!';
                    setTimeout(() => this.textContent = original, 1000);
                }};
            }});
        </script>
    </body>
    </html>
    '''
    
    return HTMLResponse(content=html)

@app.get("/monitor/stats")
async def get_stats():
    """Get statistics"""
    db = load_db()
    return JSONResponse(content=db.get("stats", {}))

@app.get("/monitor/export")
async def export_data():
    """Export all data"""
    db = load_db()
    export_file = f"/tmp/rielliona_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    
    with open(export_file, 'w') as f:
        json.dump(db, f, indent=2)
    
    return {
        "status": "success",
        "file": export_file,
        "records": len(db.get("commands", []))
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001, log_level="info")
MONITOR_PY

    # Create monitoring service
    cat > /etc/systemd/system/rielliona-monitor.service << MONITOR_SERVICE
[Unit]
Description=RIELLIONA AI Monitoring Service
After=network.target rielliona-api.service
Requires=rielliona-api.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$INSTALL_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="MODEL=$MODEL"
ExecStart=$INSTALL_DIR/venv/bin/uvicorn monitoring:app --host 0.0.0.0 --port 5001
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=rielliona-monitor
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
MONITOR_SERVICE
    
    systemctl daemon-reload
    systemctl enable rielliona-monitor
    
    success "Monitoring system created"
}

setup_web_interface() {
    header "SETTING UP WEB INTERFACE"
    
    log "Creating web directory..."
    mkdir -p /var/www/rielliona
    
    cat > /var/www/rielliona/index.html << 'HTML_FILE'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RIELLIONA AI - Private Assistant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { 
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: #f1f5f9; font-family: system-ui, -apple-system, sans-serif;
            min-height: 100vh;
        }
        .gradient-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .message-user {
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
            border-radius: 1rem;
            border-bottom-right-radius: 0.25rem;
        }
        .message-ai {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            border-radius: 1rem;
            border-bottom-left-radius: 0.25rem;
        }
        .typing-dots span {
            display: inline-block;
            animation: bounce 1.4s infinite;
        }
        .typing-dots span:nth-child(2) { animation-delay: 0.2s; }
        .typing-dots span:nth-child(3) { animation-delay: 0.4s; }
        @keyframes bounce {
            0%, 100% { transform: translateY(0); opacity: 0.5; }
            50% { transform: translateY(-5px); opacity: 1; }
        }
        .scrollbar-thin::-webkit-scrollbar {
            width: 4px;
        }
        .scrollbar-thin::-webkit-scrollbar-track {
            background: #1e293b;
        }
        .scrollbar-thin::-webkit-scrollbar-thumb {
            background: #475569;
            border-radius: 2px;
        }
    </style>
</head>
<body>
    <div class="gradient-header shadow-2xl">
        <div class="max-w-6xl mx-auto px-4 py-8">
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-3xl font-bold">🤖 RIELLIONA AI</h1>
                    <p class="text-blue-100 mt-2">Your Personal AI Assistant • 100% Private • VPS Powered</p>
                </div>
                <div class="flex items-center space-x-4">
                    <div class="bg-white/20 px-4 py-2 rounded-full">
                        <span class="font-bold" id="modelStatus">Online</span>
                    </div>
                    <div class="bg-green-500/20 px-4 py-2 rounded-full">
                        <span class="text-green-300" id="tokenCount">Ready</span>
                    </div>
                </div>
            </div>
            
            <div class="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
                <div class="bg-white/10 p-4 rounded-xl">
                    <div class="text-sm text-blue-200">Current Model</div>
                    <div class="font-bold" id="currentModel">Loading...</div>
                </div>
                <div class="bg-white/10 p-4 rounded-xl">
                    <div class="text-sm text-blue-200">Response Time</div>
                    <div class="font-bold" id="responseTime">--</div>
                </div>
                <div class="bg-white/10 p-4 rounded-xl">
                    <div class="text-sm text-blue-200">System Status</div>
                    <div class="font-bold text-green-400" id="systemStatus">Healthy</div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="max-w-6xl mx-auto px-4 py-8">
        <!-- Chat Container -->
        <div id="chatContainer" class="mb-6 space-y-6 max-h-[60vh] overflow-y-auto scrollbar-thin p-2">
            <!-- Messages will appear here -->
        </div>
        
        <!-- Input Area -->
        <div class="fixed bottom-0 left-0 right-0 bg-slate-900/95 backdrop-blur-lg border-t border-slate-700">
            <div class="max-w-6xl mx-auto px-4 py-6">
                <div class="flex gap-4">
                    <textarea 
                        id="messageInput" 
                        class="flex-1 bg-slate-800 text-white p-4 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                        placeholder="Ask RIELLIONA AI anything... (Shift+Enter for new line, Enter to send)"
                        rows="2"
                        onkeydown="handleKeyDown(event)"
                    ></textarea>
                    <button 
                        id="sendButton"
                        class="bg-gradient-to-r from-purple-600 to-blue-600 px-8 rounded-xl font-bold hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed"
                        onclick="sendMessage()"
                    >
                        Send
                    </button>
                </div>
                
                <div class="mt-4 flex justify-between text-sm text-slate-400">
                    <div class="flex items-center space-x-4">
                        <button onclick="clearChat()" class="hover:text-red-400 transition">
                            🗑️ Clear Chat
                        </button>
                        <button onclick="exportChat()" class="hover:text-green-400 transition">
                            💾 Export
                        </button>
                        <a href="/monitor/" target="_blank" class="hover:text-yellow-400 transition">
                            📊 Monitor
                        </a>
                    </div>
                    <div class="text-right">
                        <div>Model: <span id="modelInfo" class="font-bold">Loading...</span></div>
                        <div class="text-xs">Press Enter to send • Shift+Enter for new line</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Configuration
        const API_BASE = '/api';
        let chatHistory = [];
        
        // DOM Elements
        const chatContainer = document.getElementById('chatContainer');
        const messageInput = document.getElementById('messageInput');
        const sendButton = document.getElementById('sendButton');
        const modelInfo = document.getElementById('modelInfo');
        const currentModel = document.getElementById('currentModel');
        const modelStatus = document.getElementById('modelStatus');
        const tokenCount = document.getElementById('tokenCount');
        const responseTime = document.getElementById('responseTime');
        
        // Initialize
        document.addEventListener('DOMContentLoaded', async () => {
            await checkAPIStatus();
            loadChatHistory();
            addWelcomeMessage();
        });
        
        // Check API status
        async function checkAPIStatus() {
            try {
                const response = await fetch(`${API_BASE}/`);
                const data = await response.json();
                
                modelInfo.textContent = data.model;
                currentModel.textContent = data.model;
                modelStatus.textContent = 'Online';
                modelStatus.className = 'font-bold text-green-400';
                
                // Check Ollama models
                const modelsResponse = await fetch(`${API_BASE}/models`);
                const modelsData = await modelsResponse.json();
                console.log('Available models:', modelsData);
                
            } catch (error) {
                modelStatus.textContent = 'Offline';
                modelStatus.className = 'font-bold text-red-400';
                console.error('API check failed:', error);
            }
        }
        
        // Load chat history from localStorage
        function loadChatHistory() {
            const saved = localStorage.getItem('rielliona_chat');
            if (saved) {
                chatHistory = JSON.parse(saved);
                renderChat();
            }
        }
        
        // Save chat history
        function saveChatHistory() {
            localStorage.setItem('rielliona_chat', JSON.stringify(chatHistory));
        }
        
        // Add welcome message
        function addWelcomeMessage() {
            if (chatHistory.length === 0) {
                const welcomeMsg = {
                    id: Date.now(),
                    role: 'ai',
                    content: 'Halo! Saya adalah **RIELLIONA AI**, asisten pribadi Anda.\n\nSaya berjalan 100% di VPS pribadi dengan model AI canggih. Saya bisa membantu dengan:\n\n• Programming & kode\n• Analisis & riset\n• Penulisan konten\n• Problem solving\n\nApa yang bisa saya bantu hari ini?',
                    timestamp: new Date().toISOString()
                };
                chatHistory.push(welcomeMsg);
                saveChatHistory();
                renderChat();
            }
        }
        
        // Render chat
        function renderChat() {
            chatContainer.innerHTML = '';
            
            chatHistory.forEach(msg => {
                const messageDiv = document.createElement('div');
                messageDiv.className = msg.role === 'user' ? 'message-user' : 'message-ai';
                messageDiv.classList.add('p-6', 'shadow-lg');
                
                const time = new Date(msg.timestamp).toLocaleTimeString([], { 
                    hour: '2-digit', 
                    minute: '2-digit' 
                });
                
                messageDiv.innerHTML = `
                    <div class="flex items-center mb-3">
                        <div class="font-bold mr-3">
                            ${msg.role === 'user' ? '👤 Anda' : '🤖 RIELLIONA AI'}
                        </div>
                        <div class="text-sm opacity-75">${time}</div>
                    </div>
                    <div class="whitespace-pre-wrap leading-relaxed">${msg.content}</div>
                `;
                
                chatContainer.appendChild(messageDiv);
            });
            
            // Scroll to bottom
            chatContainer.scrollTop = chatContainer.scrollHeight;
        }
        
        // Add typing indicator
        function addTypingIndicator() {
            const typingDiv = document.createElement('div');
            typingDiv.className = 'message-ai p-6 shadow-lg';
            typingDiv.id = 'typingIndicator';
            typingDiv.innerHTML = `
                <div class="flex items-center mb-3">
                    <div class="font-bold mr-3">🤖 RIELLIONA AI</div>
                    <div class="typing-dots">
                        <span>●</span>
                        <span>●</span>
                        <span>●</span>
                    </div>
                </div>
            `;
            chatContainer.appendChild(typingDiv);
            chatContainer.scrollTop = chatContainer.scrollHeight;
        }
        
        // Remove typing indicator
        function removeTypingIndicator() {
            const typing = document.getElementById('typingIndicator');
            if (typing) {
                typing.remove();
            }
        }
        
        // Handle key down
        function handleKeyDown(event) {
            if (event.key === 'Enter' && !event.shiftKey) {
                event.preventDefault();
                sendMessage();
            }
        }
        
        // Auto-resize textarea
        messageInput.addEventListener('input', function() {
            this.style.height = 'auto';
            this.style.height = Math.min(this.scrollHeight, 120) + 'px';
        });
        
        // Send message
        async function sendMessage() {
            const message = messageInput.value.trim();
            if (!message) return;
            
            // Disable input while processing
            messageInput.disabled = true;
            sendButton.disabled = true;
            
            // Add user message
            const userMsg = {
                id: Date.now(),
                role: 'user',
                content: message,
                timestamp: new Date().toISOString()
            };
            
            chatHistory.push(userMsg);
            saveChatHistory();
            renderChat();
            
            // Clear input
            messageInput.value = '';
            messageInput.style.height = 'auto';
            
            // Add typing indicator
            addTypingIndicator();
            
            // Start timing
            const startTime = Date.now();
            
            try {
                // Send to API
                const response = await fetch(`${API_BASE}/chat`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        message: message,
                        stream: false
                    })
                });
                
                // Calculate response time
                const endTime = Date.now();
                const processTime = (endTime - startTime) / 1000;
                responseTime.textContent = `${processTime.toFixed(2)}s`;
                
                if (!response.ok) {
                    throw new Error(`API error: ${response.status}`);
                }
                
                const data = await response.json();
                
                // Remove typing indicator
                removeTypingIndicator();
                
                // Add AI response
                const aiMsg = {
                    id: Date.now() + 1,
                    role: 'ai',
                    content: data.response,
                    timestamp: new Date().toISOString()
                };
                
                chatHistory.push(aiMsg);
                saveChatHistory();
                renderChat();
                
                // Update token count
                if (data.tokens) {
                    tokenCount.textContent = `${data.tokens} tokens`;
                }
                
            } catch (error) {
                console.error('Error:', error);
                removeTypingIndicator();
                
                // Add error message
                const errorMsg = {
                    id: Date.now() + 1,
                    role: 'ai',
                    content: `Maaf, terjadi error: ${error.message}\n\nSilakan coba lagi atau refresh halaman.`,
                    timestamp: new Date().toISOString()
                };
                
                chatHistory.push(errorMsg);
                saveChatHistory();
                renderChat();
                
            } finally {
                // Re-enable input
                messageInput.disabled = false;
                sendButton.disabled = false;
                messageInput.focus();
            }
        }
        
        // Clear chat
        function clearChat() {
            if (confirm('Hapus semua history chat?')) {
                chatHistory = [];
                saveChatHistory();
                renderChat();
                addWelcomeMessage();
            }
        }
        
        // Export chat
        function exportChat() {
            const exportData = {
                exportDate: new Date().toISOString(),
                totalMessages: chatHistory.length,
                messages: chatHistory
            };
            
            const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `rielliona-chat-${new Date().toISOString().split('T')[0]}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            
            alert('Chat exported successfully!');
        }
    </script>
</body>
</html>
HTML_FILE
    
    success "Web interface created"
}

setup_nginx_without_ssl() {
    header "CONFIGURING NGINX (HTTP ONLY)"
    
    # Backup existing default config
    if [ -f /etc/nginx/sites-available/default ]; then
        cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
    fi
    
    log "Creating Nginx configuration (HTTP only)..."
    cat > /etc/nginx/sites-available/rielliona << NGINX_CONFIG
# RIELLIONA AI - HTTP Configuration
# SSL will be added later by Certbot

server {
    listen 80;
    server_name $DOMAIN;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Web Interface
    location / {
        root /var/www/rielliona;
        index index.html;
        try_files \$uri \$uri/ =404;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API Proxy
    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts for AI processing
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        proxy_send_timeout 300s;
        
        # Buffering optimizations
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    # Monitoring Dashboard (Password Protected)
    location /monitor/ {
        proxy_pass http://127.0.0.1:5001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Basic Authentication
        auth_basic "RIELLIONA AI Monitoring";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        # Caching
        proxy_cache off;
        proxy_buffering off;
    }
    
    # Ollama API (Optional)
    location /ollama/ {
        proxy_pass http://127.0.0.1:11434/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        
        # No buffering for streaming
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 3600s;
    }
    
    # Status endpoint (no auth)
    location /status {
        proxy_pass http://127.0.0.1:5000/status;
        proxy_set_header Host \$host;
        access_log off;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
NGINX_CONFIG
    
    # Enable site
    ln -sf /etc/nginx/sites-available/rielliona /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Create basic auth for monitoring
    echo "admin:\$(openssl passwd -crypt rielliona2024)" > /etc/nginx/.htpasswd
    chmod 644 /etc/nginx/.htpasswd
    
    # Test configuration
    if nginx -t; then
        systemctl restart nginx
        success "Nginx configured successfully (HTTP only)"
    else
        error "Nginx configuration test failed!"
        exit 1
    fi
}

setup_ssl() {
    header "SETTING UP SSL CERTIFICATE"
    
    log "Checking if port 80 is accessible..."
    
    # Stop Nginx temporarily for certbot standalone mode
    systemctl stop nginx
    
    log "Requesting SSL certificate from Let's Encrypt..."
    
    if certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --preferred-challenges http; then
        success "SSL certificate obtained successfully"
        
        # Update Nginx config to use SSL
        log "Updating Nginx configuration for SSL..."
        cat > /etc/nginx/sites-available/rielliona << NGINX_CONFIG
# RIELLIONA AI - SSL Configuration
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL Optimizations
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()";
    
    # Web Interface
    location / {
        root /var/www/rielliona;
        index index.html;
        try_files \$uri \$uri/ =404;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API Proxy
    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts for AI processing
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        proxy_send_timeout 300s;
        
        # Buffering optimizations
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    # Monitoring Dashboard (Password Protected)
    location /monitor/ {
        proxy_pass http://127.0.0.1:5001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Basic Authentication
        auth_basic "RIELLIONA AI Monitoring";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        # Caching
        proxy_cache off;
        proxy_buffering off;
    }
    
    # Ollama API (Optional)
    location /ollama/ {
        proxy_pass http://127.0.0.1:11434/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        
        # No buffering for streaming
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 3600s;
    }
    
    # Status endpoint (no auth)
    location /status {
        proxy_pass http://127.0.0.1:5000/status;
        proxy_set_header Host \$host;
        access_log off;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
NGINX_CONFIG
        
        # Restart Nginx
        systemctl start nginx
        
        if nginx -t; then
            systemctl reload nginx
            success "SSL certificate installed successfully"
            
            # Setup auto-renewal
            (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --quiet --pre-hook 'systemctl stop nginx' --post-hook 'systemctl start nginx'") | crontab -
            success "SSL auto-renewal configured"
        else
            error "Nginx configuration test failed after SSL setup!"
            systemctl start nginx  # Restart nginx anyway
        fi
    else
        warning "SSL setup failed, continuing with HTTP only"
        warning "You can manually run: certbot --nginx -d $DOMAIN"
        systemctl start nginx  # Restart nginx
    fi
}

create_management_tools() {
    header "CREATING MANAGEMENT TOOLS"
    
    # Status command
    cat > /usr/local/bin/rielliona-status << STATUS_CMD
#!/bin/bash
echo "╔════════════════════════════════════════╗"
echo "║        RIELLIONA AI STATUS            ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Services Status:"
echo "  Ollama AI Engine:    \$(systemctl is-active ollama 2>/dev/null || echo 'not installed')"
echo "  API Server:          \$(systemctl is-active rielliona-api 2>/dev/null || echo 'not installed')"
echo "  Monitoring:          \$(systemctl is-active rielliona-monitor 2>/dev/null || echo 'not installed')"
echo "  Nginx:               \$(systemctl is-active nginx 2>/dev/null || echo 'not installed')"
echo ""
echo "Access Information:"
echo "  Web Interface:       http://$DOMAIN"
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "  Web Interface (SSL): https://$DOMAIN"
fi
echo "  API Endpoint:        http://$DOMAIN/api"
echo "  Monitoring:          http://$DOMAIN/monitor"
echo "  Monitor Username:    admin"
echo "  Monitor Password:    rielliona2024"
echo ""
echo "System Resources:"
free -h | grep -E "^(Mem|Swap):"
echo ""
echo "Model Information:"
echo "  Current Model:       $MODEL"
echo "  Model Name:          $MODEL_NAME"
echo ""
echo "Quick Commands:"
echo "  rielliona-start      - Start all services"
echo "  rielliona-stop       - Stop all services"
echo "  rielliona-restart    - Restart all services"
echo "  rielliona-logs       - View logs"
echo "  rielliona-monitor    - Open monitoring"
echo "  rielliona-uninstall  - Uninstall completely"
echo ""
echo "Install Date:          \$(date -d @\$(stat -c %Y /opt/rielliona/.installed 2>/dev/null || echo 0) 2>/dev/null || echo 'Unknown')"
STATUS_CMD
    
    # Start command
    cat > /usr/local/bin/rielliona-start << START_CMD
#!/bin/bash
echo "Starting RIELLIONA AI System..."
systemctl start ollama
sleep 5
systemctl start rielliona-api
systemctl start rielliona-monitor
systemctl start nginx
echo "All services started!"
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "Access: https://$DOMAIN"
else
    echo "Access: http://$DOMAIN"
fi
START_CMD
    
    # Stop command
    cat > /usr/local/bin/rielliona-stop << STOP_CMD
#!/bin/bash
echo "Stopping RIELLIONA AI System..."
systemctl stop rielliona-monitor
systemctl stop rielliona-api
systemctl stop ollama
echo "Services stopped!"
STOP_CMD
    
    # Restart command
    cat > /usr/local/bin/rielliona-restart << RESTART_CMD
#!/bin/bash
echo "Restarting RIELLIONA AI System..."
systemctl restart ollama
sleep 5
systemctl restart rielliona-api
systemctl restart rielliona-monitor
systemctl restart nginx
echo "Services restarted!"
RESTART_CMD
    
    # Logs command
    cat > /usr/local/bin/rielliona-logs << LOGS_CMD
#!/bin/bash
case "\$1" in
    "api")
        journalctl -u rielliona-api -f
        ;;
    "monitor")
        journalctl -u rielliona-monitor -f
        ;;
    "ollama")
        journalctl -u ollama -f
        ;;
    "nginx")
        journalctl -u nginx -f
        ;;
    "all")
        journalctl -f -u rielliona-api -u rielliona-monitor -u ollama
        ;;
    *)
        echo "Usage: rielliona-logs [service]"
        echo ""
        echo "Services:"
        echo "  api      - API server logs"
        echo "  monitor  - Monitoring logs"
        echo "  ollama   - Ollama AI logs"
        echo "  nginx    - Nginx logs"
        echo "  all      - All logs combined"
        ;;
esac
LOGS_CMD
    
    # Monitor command
    cat > /usr/local/bin/rielliona-monitor << MONITOR_CMD
#!/bin/bash
echo "RIELLIONA AI Monitoring System"
echo ""
echo "Dashboard: http://$DOMAIN/monitor"
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "Dashboard (SSL): https://$DOMAIN/monitor"
fi
echo "Username: admin"
echo "Password: rielliona2024"
echo ""
echo "Quick Stats:"
curl -s http://$DOMAIN/api/status | python3 -m json.tool 2>/dev/null || echo "API not available"
MONITOR_CMD
    
    # Uninstall command
    cat > /usr/local/bin/rielliona-uninstall << UNINSTALL_CMD
#!/bin/bash
exec $0 --uninstall
UNINSTALL_CMD
    
    # Make all commands executable
    chmod +x /usr/local/bin/rielliona-*
    
    success "Management tools created"
}

setup_logging() {
    header "SETTING UP LOGGING"
    
    # Create log directory
    mkdir -p /var/log/rielliona
    
    # Create logrotate config
    cat > /etc/logrotate.d/rielliona << LOGROTATE
/var/log/rielliona/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload rielliona-api > /dev/null 2>&1 || true
        systemctl reload rielliona-monitor > /dev/null 2>&1 || true
    endscript
}

/var/log/rielliona/monitor/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 root root
}
LOGROTATE
    
    # Create initial log files
    touch /var/log/rielliona/api.log
    touch /var/log/rielliona/interactions.log
    touch /var/log/rielliona/monitor/monitor.log
    chmod 644 /var/log/rielliona/*.log
    
    success "Logging system configured"
}

start_services() {
    header "STARTING ALL SERVICES"
    
    log "Starting Ollama AI engine..."
    systemctl start ollama
    sleep 10  # Wait for Ollama to fully initialize
    
    log "Starting API server..."
    systemctl start rielliona-api
    sleep 3
    
    log "Starting monitoring system..."
    systemctl start rielliona-monitor
    sleep 2
    
    log "Restarting Nginx..."
    systemctl restart nginx
    
    # Wait for services to stabilize
    sleep 5
    
    # Verify services
    log "Verifying services..."
    
    services_ok=true
    for service in ollama rielliona-api rielliona-monitor nginx; do
        if systemctl is-active --quiet "$service"; then
            success "$service is running"
        else
            error "$service failed to start"
            services_ok=false
        fi
    done
    
    if [ "$services_ok" = true ]; then
        success "All services started successfully!"
    else
        warning "Some services failed to start. Check logs with: journalctl -xe"
    fi
}

finalize_installation() {
    header "FINALIZING INSTALLATION"
    
    # Create installation marker
    date > "$INSTALL_DIR/.installed"
    
    # Save final config
    save_config
    
    # Create README
    cat > "$INSTALL_DIR/README.md" << README
# RIELLIONA AI - Installation Complete

## SYSTEM INFORMATION
- Installation Date: $(date)
- Domain: $DOMAIN
- AI Model: $MODEL_NAME ($MODEL)
- Installation Mode: $INSTALL_MODE
- Script Version: $SCRIPT_VERSION

## ACCESS URLs
- Web Interface: http://$DOMAIN
$(if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then echo "- Web Interface (SSL): https://$DOMAIN"; fi)
- API Endpoint: http://$DOMAIN/api
- Monitoring Dashboard: http://$DOMAIN/monitor
- API Status: http://$DOMAIN/api/status

## CREDENTIALS
- Monitoring Dashboard:
  - Username: admin
  - Password: rielliona2024

## MANAGEMENT COMMANDS
- Start all services: rielliona-start
- Stop all services: rielliona-stop
- Restart all services: rielliona-restart
- Check status: rielliona-status
- View logs: rielliona-logs [service]
- Open monitoring: rielliona-monitor
- Uninstall: rielliona-uninstall

## SERVICES
- Ollama AI Engine: systemctl status ollama
- API Server: systemctl status rielliona-api
- Monitoring: systemctl status rielliona-monitor
- Nginx: systemctl status nginx

## LOG FILES
- API Logs: /var/log/rielliona/api.log
- Interaction Logs: /var/log/rielliona/interactions.log
- Monitor Logs: /var/log/rielliona/monitor/
- System Logs: journalctl -u rielliona-api -f

## TESTING
Test API with curl:
\`\`\`bash
curl -X POST http://$DOMAIN/api/chat \\
  -H "Content-Type: application/json" \\
  -d '{"message": "Hello, introduce yourself"}'
\`\`\`

## MONITORING FEATURES
- Real-time request tracking
- User IP logging
- Success/error rate monitoring
- System resource monitoring
- Command history with status
- Auto log rotation (30 days)

## TROUBLESHOOTING
1. Check all services: rielliona-status
2. View logs: rielliona-logs all
3. Restart: rielliona-restart
4. Check disk space: df -h
5. Check memory: free -h

## SECURITY NOTES
- Firewall configured (UFW)
$(if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then echo "- SSL/TLS enabled"; else echo "- SSL/TLS not enabled (run certbot later)"; fi)
- Monitoring password protected
- No external telemetry
- All data stored locally

## SUPPORT
This installation was automated by XANTSYSTEM for rielliona.
For issues, check logs and service status first.
README
    
    success "Installation finalized"
}

show_completion() {
    header "INSTALLATION COMPLETE! 🎉"
    
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║            RIELLIONA AI SUCCESSFULLY INSTALLED      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    echo "✅ INSTALLATION SUMMARY:"
    echo "   Domain:         http://$DOMAIN"
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        echo "   Domain (SSL):   https://$DOMAIN"
    fi
    echo "   AI Model:       $MODEL_NAME"
    echo "   Monitoring:     http://$DOMAIN/monitor"
    echo "   VPS Spec:       16GB RAM, 8 vCPU, DigitalOcean"
    echo "   Owner:          rielliona"
    echo ""
    echo "🚀 QUICK START:"
    echo "   1. Open: http://$DOMAIN"
    echo "   2. Start chatting with your AI assistant!"
    echo "   3. Monitor activity at: http://$DOMAIN/monitor"
    echo ""
    echo "🔧 MANAGEMENT COMMANDS:"
    echo "   rielliona-status      - Check system status"
    echo "   rielliona-start       - Start all services"
    echo "   rielliona-stop        - Stop all services"
    echo "   rielliona-restart     - Restart all services"
    echo "   rielliona-logs [svc]  - View service logs"
    echo "   rielliona-monitor     - Open monitoring"
    echo "   rielliona-uninstall   - Remove completely"
    echo ""
    echo "📊 MONITORING FEATURES:"
    echo "   • Real-time IP & command tracking"
    echo "   • Success/error status logging"
    echo "   • User activity dashboard"
    echo "   • System resource monitoring"
    echo "   • Auto-log rotation (30 days)"
    echo ""
    echo "🔒 SECURITY:"
    echo "   • Firewall configured"
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        echo "   • SSL/TLS enabled"
    else
        echo "   • SSL/TLS not enabled (run certbot later)"
    fi
    echo "   • Monitoring password protected"
    echo "   • No data leaves your VPS"
    echo ""
    echo "📝 NEXT STEPS:"
    echo "   1. Bookmark: http://$DOMAIN"
    if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        echo "   2. Enable SSL: certbot --nginx -d $DOMAIN"
    fi
    echo "   3. Change monitoring password"
    echo "   4. Set up regular backups"
    echo "   5. Monitor resource usage"
    echo ""
    echo "🛠️  SUPPORT:"
    echo "   • Logs: /var/log/rielliona/"
    echo "   • Config: $INSTALL_DIR/"
    echo "   • Services: systemctl status rielliona-*"
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  Made with ❤️ by XANTSYSTEM for rielliona            ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    
    # Show sample monitoring output
    echo "📈 SAMPLE MONITORING OUTPUT:"
    echo "   $(curl -s ifconfig.me 2>/dev/null || echo "127.0.0.1"): Hello AI - status = success"
    echo "   $(curl -s ifconfig.me 2>/dev/null || echo "127.0.0.1"): Buatkan script - status = success"
    echo "   $(curl -s ifconfig.me 2>/dev/null || echo "127.0.0.1"): Test error - status = error"
    echo ""
    
    # Final message
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        success "Your personal AI is now ready at https://$DOMAIN"
    else
        success "Your personal AI is now ready at http://$DOMAIN"
        warning "SSL not enabled. To enable SSL, run: certbot --nginx -d $DOMAIN"
    fi
    echo ""
    echo "Installation log: $LOG_FILE"
    echo "Start time: $(date)"
    echo ""
}

# ============================================
# MAIN INSTALLATION FLOW
# ============================================

main() {
    # Clear screen and show banner
    clear
    cat << "BANNER"
    
██████╗ ██╗███████╗██╗     ██╗ ██████╗ ███╗   ██╗ █████╗ 
██╔══██╗██║██╔════╝██║     ██║██╔═══██╗████╗  ██║██╔══██╗
██████╔╝██║█████╗  ██║     ██║██║   ██║██╔██╗ ██║███████║
██╔══██╗██║██╔══╝  ██║     ██║██║   ██║██║╚██╗██║██╔══██║
██║  ██║██║███████╗███████╗██║╚██████╔╝██║ ╚████║██║  ██║
╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝
               PERSONAL AI SYSTEM v3.0
         With Monitoring & Auto Uninstall Feature

BANNER
    
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  One Script to Install, Monitor, and Uninstall      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    
    # Check for uninstall flag
    if [ "$1" = "--uninstall" ]; then
        uninstall_rielliona
        exit 0
    fi
    
    # Check root
    check_root
    
    # Check if already installed
    if load_config; then
        warning "RIELLIONA AI is already installed!"
        echo ""
        echo "Domain: $DOMAIN"
        echo "Model: $MODEL_NAME"
        echo "Installed: $INSTALL_DATE"
        echo ""
        read -p "Reinstall? (This will overwrite existing installation) [y/N]: " reinstall
        if [[ ! $reinstall =~ ^[Yy]$ ]]; then
            echo ""
            echo "Available commands:"
            echo "  rielliona-status      - Check status"
            echo "  rielliona-uninstall   - Remove installation"
            echo ""
            exit 0
        fi
    fi
    
    # Start logging
    > "$LOG_FILE"
    log "Starting RIELLIONA AI installation..."
    log "Script version: $SCRIPT_VERSION"
    log "Date: $(date)"
    log "System: $(uname -a)"
    
    # Get user input
    header "CONFIGURATION"
    
    # Domain
    while true; do
        echo -n "=> Masukkan domain (contoh: ai.domainanda.com): "
        read DOMAIN
        
        if [ -z "$DOMAIN" ]; then
            error "Domain tidak boleh kosong!"
            continue
        fi
        
        if [[ $DOMAIN =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            success "Domain valid: $DOMAIN"
            break
        else
            error "Format domain tidak valid!"
        fi
    done
    
    # Email
    echo ""
    while true; do
        echo -n "=> Masukkan email untuk SSL certificate: "
        read EMAIL
        
        if [ -z "$EMAIL" ]; then
            error "Email tidak boleh kosong!"
            continue
        fi
        
        if [[ $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            success "Email valid: $EMAIL"
            break
        else
            warning "Format email mungkin tidak valid, lanjutkan? (y/n)"
            read -r confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                break
            fi
        fi
    done
    
    # Model selection
    header "AI MODEL SELECTION"
    echo "Pilih model AI (rekomendasi untuk VPS 16GB):"
    echo "  1) ${GREEN}Llama 3.2 3B${NC} - Cepat, 2GB RAM, rekomendasi"
    echo "  2) ${YELLOW}Qwen 2.5 7B${NC} - Lebih pintar, 4GB RAM"
    echo "  3) ${BLUE}Llama 3.1 8B${NC} - Sangat pintar, 5GB RAM"
    echo "  4) ${RED}Custom model${NC} - Masukkan manual"
    echo ""
    
    while true; do
        echo -n "=> Pilihan model (1-4): "
        read MODEL_CHOICE
        
        case $MODEL_CHOICE in
            1)
                MODEL="llama3.2:3b-instruct-q4_K_M"
                MODEL_NAME="Llama 3.2 3B"
                break
                ;;
            2)
                MODEL="qwen2.5:7b-instruct-q4_K_M"
                MODEL_NAME="Qwen 2.5 7B"
                break
                ;;
            3)
                MODEL="llama3.1:8b-instruct-q4_K_M"
                MODEL_NAME="Llama 3.1 8B"
                break
                ;;
            4)
                echo -n "=> Masukkan nama model Ollama (contoh: mistral:7b): "
                read CUSTOM_MODEL
                if [ -n "$CUSTOM_MODEL" ]; then
                    MODEL="$CUSTOM_MODEL"
                    MODEL_NAME="Custom: $CUSTOM_MODEL"
                    break
                else
                    error "Nama model tidak boleh kosong!"
                fi
                ;;
            *)
                error "Pilihan tidak valid!"
                ;;
        esac
    done
    
    # Installation type
    INSTALL_MODE="full"
    
    # Show summary
    header "INSTALLATION SUMMARY"
    echo "  Domain:        $DOMAIN"
    echo "  Email SSL:     $EMAIL"
    echo "  Model AI:      $MODEL_NAME"
    echo "  Install Type:  Full Installation"
    echo "  VPS Spec:      16GB RAM, 8 vCPU"
    echo ""
    echo "══════════════════════════════════════════════════════"
    
    # Confirmation
    echo ""
    warning "Instalasi akan dimulai. Pastikan:"
    echo "  1. Domain sudah di-point ke IP VPS ini"
    echo "  2. Port 80/443 terbuka di firewall"
    echo "  3. Anda memiliki minimal 20GB space kosong"
    echo ""
    echo -n "Lanjutkan instalasi? (y/N): "
    read -r CONFIRM
    
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        error "Instalasi dibatalkan!"
        exit 0
    fi
    
    # Start installation process
    echo ""
    log "Starting installation process..."
    
    # Run all installation steps with corrected order
    install_dependencies
    setup_firewall
    setup_swap
    install_ollama
    download_model
    setup_python_env
    create_api_server
    create_monitoring_system
    setup_web_interface
    setup_nginx_without_ssl  # Changed to setup without SSL first
    create_management_tools
    setup_logging
    start_services
    setup_ssl  # SSL setup after nginx is running
    finalize_installation
    
    # Show completion
    show_completion
}

# ============================================
# RUN MAIN
# ============================================

# Handle command line arguments
case "$1" in
    "--uninstall"|"-u")
        main "--uninstall"
        ;;
    "--help"|"-h")
        echo "RIELLIONA AI Installer v$SCRIPT_VERSION"
        echo ""
        echo "Usage:"
        echo "  $0                    - Install RIELLIONA AI"
        echo "  $0 --uninstall        - Uninstall completely"
        echo "  $0 --help             - Show this help"
        echo ""
        echo "Features:"
        echo "  • Complete AI system installation"
        echo "  • Real-time monitoring with IP tracking"
        echo "  • Success/error status logging"
        echo "  • Auto SSL certificate setup"
        echo "  • Management tools included"
        echo "  • Complete uninstall option"
        echo ""
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
