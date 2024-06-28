#!/bin/bash
#
# Disk Space Check Script
# for GitHub Enterprise Server (GHES) 
#
# Author: appatalks
# License: GPL-3.0 license
# Adapted from Rackspace's documentation on troubleshooting low disk space:
# https://docs.rackspace.com/docs/troubleshooting-low-disk-space-for-a-linux-cloud-server

# Function to display the server time
display_server_time() {
    echo -e "\n== Server Time: =="
    date
}

# Function to display filesystem information
display_filesystem_info() {
    echo -e "\n== Filesystem Information: =="
    sudo df -PTh / | column -t
}

# Function to display inode information
display_inode_info() {
    echo -e "\n== Inode Information: =="
    sudo df -PTi / | column -t
}

# Function to display the largest directories in the given path
display_largest_directories_root() {
    local path=$1
    echo -e "\n== Largest Directories in ${path}: =="
    sudo du -hcx --max-depth=5 ${path} 2>/dev/null | grep -v '/data' | grep -P '^([0-9]\.*)*G(?!.*(\btotal\b|\./$))' | sort -rnk1,1 | head -15 | column -t
}

display_largest_directories_data() {
    local path=$1
    echo -e "\n== Largest Directories in ${path}: =="
    sudo du -hcx --max-depth=5 ${path} 2>/dev/null | grep -v '^/data/docker-images' | grep -P '^([0-9]\.*)*G(?!.*(\btotal\b|\./$))' | sort -rnk1,1 | head -15 | column -t
}

# Function to display the largest files in the given path
display_largest_files_root() {
    local path=$1
    echo -e "\n== Largest Files in ${path}: =="
    sudo find ${path} -mount -ignore_readdir_race -type f -not -path "/data/*" -exec du {} + 2>/dev/null | sort -rnk1,1 | head -10 | awk 'BEGIN{ CONVFMT="%.2f";}{ $1=( $1 / 1024 )"M"; print; }' | column -t
}

display_largest_files_data() {
    local path=$1
    echo -e "\n== Largest Files in ${path}: =="
    sudo find ${path} -mount -ignore_readdir_race -type f -not -path "/data/docker-images/*" -exec du {} + 2>/dev/null | sort -rnk1,1 | head -10 | awk 'BEGIN{ CONVFMT="%.2f";}{ $1=( $1 / 1024 )"M"; print; }' | column -t
}

# Function to display the largest files older than 30 days in the given path
display_largest_files_older_than_30_days_root() {
    local path=$1
    echo -e "\n== Largest Files Older Than 30 Days in ${path}: =="
    sudo find ${path} -mount -ignore_readdir_race -type f -mtime +30 -not -path "/data/*" -exec du {} + 2>/dev/null | sort -rnk1,1 | head -10 | awk 'BEGIN{ CONVFMT="%.2f";}{ $1=( $1 / 1024 )"M"; print; }' | column -t
}

display_largest_files_older_than_30_days_data() {
    local path=$1
    echo -e "\n== Largest Files Older Than 30 Days in ${path}: =="
    sudo find ${path} -mount -ignore_readdir_race -type f -mtime +30 -not -path "/data/docker-images/*" -exec du {} + 2>/dev/null | sort -rnk1,1 | head -10 | awk 'BEGIN{ CONVFMT="%.2f";}{ $1=( $1 / 1024 )"M"; print; }' | column -t
}

# Main function to call all other functions
main() {
    display_server_time
    display_filesystem_info
    display_inode_info

    # Separate scans for root path
    echo -e "\n-- Scans for Root Path (/) --"
    display_largest_directories_root /
    display_largest_files_root /
    display_largest_files_older_than_30_days_root /

    # Separate scans for /data path
    echo -e "\n-- Scans for /data Path --"
    display_largest_directories_data /data
    display_largest_files_data /data
    display_largest_files_older_than_30_days_data /data
}

# Execute the main function
main
