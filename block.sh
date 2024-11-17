#!/bin/bash

# Print the 'Made by' message when the script is executed
echo 'Made by Taylor Christian Newsome'

# Update package lists and install required dependencies
echo "Installing necessary packages..."
sudo apt-get update -y
sudo apt-get install -y iptables firewalld lsb-release

# Detect log file path based on system type
if [ -f /var/log/auth.log ]; then
  LOG_FILE="/var/log/auth.log"
elif [ -f /var/log/secure ]; then
  LOG_FILE="/var/log/secure"
else
  echo "Unsupported log file location. Aborting."
  exit 1
fi

# Function to block IP using iptables or firewalld
block_ip() {
  local ip="$1"
  echo "Blocking IP: $ip"
  
  # Check if iptables is available
  if command -v iptables &> /dev/null; then
    sudo iptables -A INPUT -s "$ip" -j DROP
  # Check if firewalld is available
  elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip' reject"
    sudo firewall-cmd --reload
  else
    echo "No supported firewall found (iptables or firewalld). Unable to block IP."
    exit 1
  fi
}

# Create the monitor script
echo "#!/bin/bash
# Path to the SSH auth log file
LOG_FILE=\"$LOG_FILE\"

# Function to block IP using iptables or firewalld
block_ip() {
  local ip=\$1
  echo \"Blocking IP: \$ip\"
  
  # Check if iptables is available
  if command -v iptables &> /dev/null; then
    sudo iptables -A INPUT -s \"\$ip\" -j DROP
  # Check if firewalld is available
  elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-rich-rule=\"rule family='ipv4' source address='\$ip' reject\"
    sudo firewall-cmd --reload
  else
    echo \"No supported firewall found (iptables or firewalld). Unable to block IP.\"
    exit 1
  fi
}

# Monitor the auth.log file for failed SSH login attempts
tail -F \"\$LOG_FILE\" | while read line; do
  # Check if the line contains an authentication failure for root or invalid users
  if echo \"\$line\" | grep -q \"Failed password\"; then
    # Extract the IP address from the log line
    ip=\$(echo \"\$line\" | awk '{print \$0}' | grep -oP '(?<=from )(\d+\.\d+\.\d+\.\d+)')
    
    # Block the IP if it is not already blocked
    if [[ -n \"\$ip\" ]]; then
      block_ip \"\$ip\"
    fi
  fi
done" | sudo tee /usr/local/bin/block_brute_force.sh > /dev/null

# Make the script executable
sudo chmod +x /usr/local/bin/block_brute_force.sh

# Create the systemd service file
echo "[Unit]
Description=Block SSH Brute Force Attacks
After=network.target

[Service]
ExecStart=/usr/local/bin/block_brute_force.sh
Restart=always
User=root
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=block_brute_force

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/block_brute_force.service > /dev/null

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable block_brute_force.service
sudo systemctl start block_brute_force.service

# Check the status of the service to confirm it's running
sudo systemctl status block_brute_force.service

echo "Brute force protection is now active. The service is running in the background."
