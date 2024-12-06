# X-UI Backup System 🚀

A robust automated backup solution for X-UI databases with Telegram integration. This system consists of two components: a Download Server (Foreign) and an Upload Server (Iranian), working together to securely transfer and backup your X-UI database files.

## 🌟 Features

- **Automated Backups**: Scheduled database backups at customizable intervals
- **Secure File Transfer**: API key authentication for secure server communication
- **Telegram Integration**: Instant notifications with detailed backup information
- **Rate Limiting**: Built-in protection against abuse
- **Logging**: Comprehensive logging system for troubleshooting
- **Easy Management**: Simple installation and configuration process

## 🛠️ System Requirements

### Download Server (Foreign)
- Python 3.x
- Flask
- Flask-Limiter
- Requests
- Systemd-compatible Linux system

### Upload Server (Iranian)
- Python 3.x
- Requests
- Cron (for scheduling)
- Systemd-compatible Linux system

## 📦 Installation

### 1. Download Server Setup

```bash
# Run the script and select option 1
# You will need to provide:
- Telegram Bot Token
- Telegram Chat ID
```

### 2. Upload Server Setup

```bash
# Run the script and select option 2
# You will need to provide:
- Download Server IP
- API Key (generated during Download Server setup)
- Backup frequency (in hours)
```

## ⚙️ Configuration

### Download Server
- Maximum file size: 16MB
- Allowed file types: .db
- Rate limit: 5 requests per minute
- Port: 5000

### Upload Server
- Automated backups via cron
- Systemd service for reliability
- Configurable backup frequency

## 🔒 Security Features

- API Key Authentication
- Rate Limiting
- File Type Validation
- Secure File Handling
- Automatic File Cleanup

## 📱 Telegram Notifications

Each backup notification includes:
- Host Name
- Host IP
- Date and Time
- Database File

## 🔄 Management Commands

### Update Telegram Settings
```bash
# Run the script and select option 3
# Update bot token and chat ID
```

### Uninstall System
```bash
# Run the script and select option 4
# Removes all components and configurations
```

## 📝 Logging

- Download Server: `server.log`
- Upload Server: `client.log`
- Systemd journal logs available via `journalctl`

## ⚠️ Important Notes

1. Keep your API key secure
2. Store backup copies in multiple locations
3. Regularly verify backup integrity
4. Monitor system logs for any issues
5. Ensure stable network connectivity

## 🔧 Troubleshooting

1. Check system logs:
   ```bash
   journalctl -u dl.service  # Download server logs
   journalctl -u up.service  # Upload server logs
   ```

2. Verify service status:
   ```bash
   systemctl status dl.service
   systemctl status up.service
   ```

3. Common issues:
   - Network connectivity problems
   - Invalid API key
   - File permission issues
   - Telegram bot configuration errors

## 🤝 Support

For issues and feature requests, please contact the system administrator or create an issue in the repository.

## 🔐 Security Recommendations

1. Use strong API keys
2. Regular security audits
3. Keep systems updated
4. Monitor access logs
5. Implement firewall rules
