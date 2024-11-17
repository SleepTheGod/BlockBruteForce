#!/bin/bash

# Create the block brute force script
echo "#!/bin/bash

# Print the 'Made by' message when the script is executed
echo 'Made by Taylor Christian Newsome'

# Loop to check and block IPs attempting brute force attacks
while true; do
    # Extract IPs from SSH logs that have failed authentication attempts
    failed_ips=\$(grep 'Failed password' /var/log/auth.log | awk '{print \$(NF-3)}' | sort | uniq)

    # Loop through each IP address attempting to brute force
    for ip in \$failed_ips; do
        # Block the IP using iptables (you can replace this with your preferred blocking method)
        sudo iptables -A INPUT -s \$ip -j DROP
        echo 'Blocked \$ip for failed SSH attempts'
    done

    # Sleep for 60 seconds before checking again
    sleep 60
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
