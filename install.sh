#!/bin/bash
clear

echo " 
▀▄▀ ▄▄ █░█ █   █▄▄ ▄▀█ █▀▀ █▄▀ █░█ █▀█
█░█ ░░ █▄█ █   █▄█ █▀█ █▄▄ █░█ █▄█ █▀▀"



function install_on_download_server() {
  # Install necessary dependencies
  apt update && apt install -y python3 python3-pip && python3 -m ensurepip
  python3 -m pip install flask flask_limiter requests

  # Ask for Telegram bot token and chat ID
 echo -e "\n\e[1;34mPlease enter your Telegram bot token:\e[0m"
read -p "-> " TELEGRAM_BOT_TOKEN

echo -e "\n\e[1;34mPlease enter your Telegram chat ID:\e[0m"
read -p "-> " TELEGRAM_CHAT_ID

  # Generate random API_KEY
  API_KEY=$(python3 -c "import secrets; print(secrets.token_hex(16))")

  # Create dl.py file
  cat <<EOT > /root/dl.py
from flask import Flask, request, abort
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import os
import requests
from datetime import datetime
import logging

app = Flask(__name__)

# Logging configuration
logging.basicConfig(filename='server.log', level=logging.INFO, format='%(asctime)s %(message)s')

# File upload configuration
UPLOAD_FOLDER = './uploads'
ALLOWED_EXTENSIONS = {'db'}
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # Max file size (16 MB)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# Ensure upload folder exists
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# Authentication settings
API_KEY = "$API_KEY"

# Rate limiting configuration
limiter = Limiter(get_remote_address, app=app)

# Telegram settings
TELEGRAM_BOT_TOKEN = '$TELEGRAM_BOT_TOKEN'
TELEGRAM_CHAT_ID = '$TELEGRAM_CHAT_ID'

def allowed_file(filename):
    """Check file type"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.before_request
def authenticate():
    """Authenticate requests"""
    token = request.headers.get('Authorization')
    if token != API_KEY:
        logging.warning(f"Unauthorized access attempt from {request.remote_addr}")
        abort(401)  # Unauthorized

@app.route('/upload', methods=['POST'])
@limiter.limit("5 per minute")  # Limit to 5 requests per minute
def upload_file():
    """Receive file and send to Telegram"""
    if 'file' not in request.files:
        return {"error": "No file part in the request"}, 400

    file = request.files['file']
    if file.filename == '':
        return {"error": "No selected file"}, 400

    if not allowed_file(file.filename):
        return {"error": "Invalid file type"}, 400

    file_path = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)

    try:
        # Save file
        file.save(file_path)

        # Get additional information
        host_name = request.form.get('host_name', 'Unknown Host')
        host_ip = request.form.get('host_ip', 'Unknown IP')

        # Generate caption for Telegram
        current_time = datetime.now()
        caption = f"""\
💻 Host: {host_name} ({host_ip})
--------------
📅 Date: {current_time.strftime('%Y-%m-%d')}
--------------
⌚️ Time: {current_time.strftime('%H:%M:%S')}"""

        # Send file to Telegram
        with open(file_path, 'rb') as f:
            response = requests.post(
                f'https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendDocument',
                data={'chat_id': TELEGRAM_CHAT_ID, 'caption': caption},
                files={'document': f}
            )

        # Check result
        if response.status_code == 200:
            os.remove(file_path)  # Delete file after successful send
            logging.info(f"File {file.filename} successfully sent to Telegram with caption.")
            return {"message": "File sent to Telegram successfully"}, 200
        else:
            logging.error(f"Failed to send file to Telegram: {response.text}")
            return {"error": f"Failed to send file to Telegram: {response.text}"}, 500

    except Exception as e:
        logging.error(f"Error processing file {file.filename}: {str(e)}")
        return {"error": str(e)}, 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOT

  # Set up systemd service for dl.py
  cat <<EOT > /etc/systemd/system/dl.service
[Unit]
Description=Download Server Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/dl.py
WorkingDirectory=/root
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOT

  # Enable and start the service
  systemctl enable dl.service
  systemctl start dl.service

  # Clear the screen and display API_KEY with better formatting
  clear
  echo -e "\n\e[1;32m==========================\e[0m"
  echo -e "\e[1;33m     Your API KEY:\e[0m"
  echo -e "\e[1;32m==========================\e[0m"
  echo -e "\e[1;36m$API_KEY\e[0m"
  echo -e "\e[1;32m==========================\e[0m"
  echo "\nPlease save this API_KEY."
  echo "You will need it when installing on the Upload Server (Iranian)."

  # Save API_KEY to use in upload server script
  echo "$API_KEY" > /root/api_key.txt
}


function update_telegram_settings() {
  read -p "Please enter your new Telegram bot token: " TELEGRAM_BOT_TOKEN
  read -p "Please enter your new Telegram chat ID: " TELEGRAM_CHAT_ID

  # Update Telegram settings in up.py
  sed -i "s|TELEGRAM_BOT_TOKEN = '.*'|TELEGRAM_BOT_TOKEN = '$TELEGRAM_BOT_TOKEN'|" /root/dl.py
  sed -i "s|TELEGRAM_CHAT_ID = '.*'|TELEGRAM_CHAT_ID = '$TELEGRAM_CHAT_ID'|" /root/dl.py

  # Restart the service
  systemctl restart dl.service

  echo "Telegram settings updated successfully."
}

function install_on_upload_server() {
  # Check if any existing cron job exists and remove it
existing_cron_job=$(crontab -l 2>/dev/null | grep 'up.py')
if [ -n "$existing_cron_job" ]; then
  echo -e "\e[1;33mExisting cron job found. Removing it before proceeding with installation...\e[0m"
  crontab -l 2>/dev/null | grep -v 'up.py' | crontab -
fi

  # Install necessary dependencies
  apt update && apt install -y python3 python3-pip && python3 -m ensurepip
  python3 -m pip install requests

echo -e "\n\e[1;34mPlease enter the Download Server IP:\e[0m"
read -p "-> " external_server_ip

echo -e "\n\e[1;34mPlease enter the API KEY:\e[0m"
read -p "-> " API_KEY

  # Create up.py file
  cat <<EOT > /root/up.py
import requests
import socket
import logging

# Configuration
SERVER_URL = 'http://$external_server_ip:5000/upload'
FILE_PATH = '/etc/x-ui/x-ui.db'
API_KEY = '$API_KEY'

# Logging setup
logging.basicConfig(filename='client.log', level=logging.INFO, format='%(asctime)s %(message)s')

def send_file():
    """Send file to external server with server details"""
    try:
        headers = {'Authorization': API_KEY}
        host_name = socket.gethostname()
        host_ip = socket.gethostbyname(host_name)

        data = {
            'host_name': host_name,
            'host_ip': host_ip
        }

        with open(FILE_PATH, 'rb') as file:
            response = requests.post(SERVER_URL, files={'file': file}, data=data, headers=headers)

        if response.status_code == 200:
            logging.info(f"File {FILE_PATH} sent successfully: {response.json()}")
            print("File sent successfully.")
        else:
            logging.error(f"Failed to send file: {response.status_code}, {response.text}")
            print(f"Failed to send file: {response.status_code}, {response.text}")

    except Exception as e:
        logging.error(f"Error while sending file: {str(e)}")
        print(f"Error: {e}")

if __name__ == "__main__":
    send_file()
EOT


  # Install necessary dependencies
  python3 -m pip install requests
  echo "Upload server setup completed."


  # Set up cron job
  read -p "Enter how many hours between each run for the cron job: " hours_frequency
  cron_frequency="0 */$hours_frequency * * *"
  (crontab -l 2>/dev/null; echo "$cron_frequency python3 $(pwd)/up.py") | crontab -

  # Set up systemd service for up.py
  cat <<EOT > /etc/systemd/system/up.service
[Unit]
Description=Upload Server Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/up.py
WorkingDirectory=/root
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOT

  # Enable and start the service
  systemctl daemon-reload
  systemctl enable up.service
  systemctl start up.service

  echo "Cron job and service set successfully."


function uninstall_script() {
  # Remove created files
  rm -f dl.py up.py server.log client.log api_key.txt

  # Kill running Flask server if exists
  pkill -f "python3 dl.py"

  # Remove cron job
  crontab -l | grep -v "$(pwd)/up.py" | crontab -

  # Remove systemd services
  systemctl stop dl.service
  systemctl disable dl.service
  rm -f /etc/systemd/system/dl.service

  systemctl stop up.service
  systemctl disable up.service
  rm -f /etc/systemd/system/up.service

  echo "Uninstallation completed."
}

# Main menu
echo -e "\n\e[1;33m==============================\e[0m"
echo -e "\e[1;33m       Main Menu       \e[0m"
echo -e "\e[1;33m==============================\e[0m"
echo -e "\e[1;32m1. Install on Download Server (Foreign)\e[0m"
echo -e "\e[1;32m2. Install on Upload Server (Iranian)\e[0m"
echo -e "\e[1;32m3. Update Telegram Settings\e[0m"
echo -e "\e[1;32m4. Uninstall Script\e[0m"
echo -e "\e[1;32m5. Exit\e[0m"
echo -e "\n\e[1;34mEnter your choice:\e[0m"
read -p "-> " choice

case $choice in
  1)
    install_on_download_server
    ;;
  2)
    install_on_upload_server
    ;;
  3)
    update_telegram_settings
    ;;
  4)
    uninstall_script
    ;;
  5)
    exit 0
    ;;
  *)
    echo "Invalid option. Exiting."
    exit 1
    ;;
esac
