# Explanation of the Script
block_ip() function: Blocks the IP address using iptables when it is detected as attempting a brute-force attack.
Monitoring auth.log: The script uses tail -F to follow the SSH log file (/var/log/auth.log) in real-time. It checks for lines containing "Failed password" (indicating a failed login attempt).
Extracting and blocking IPs: If a failed login attempt is found, it extracts the IP address using grep and awk and calls the block_ip() function to block it.
Making the script executable: The script is written to /usr/local/bin/block_brute_force.sh and made executable.
Systemd service: The script creates a systemd service (block_brute_force.service) to ensure it runs in the background continuously and is started automatically on boot.
Enable and start service: After creating the service, it enables and starts it using systemctl.
Service status check: Finally, it checks if the service is running properly.

# How to Use
Save the above script to a file (e.g., setup_brute_blocker.sh).
Run the script with root privileges
```bash
sudo bash main.sh
```
Once the script runs, it will
Set up the SSH brute-force detection and blocking mechanism.
Run as a background service, automatically blocking IPs attempting brute-force SSH login attempts.
Print "Made by Taylor Christian Newsome" when the script is executed.
The script is fully automated and does not require any user edits. It handles everything, including logging the blocked IPs and printing the desired message.