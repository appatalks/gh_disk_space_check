## Check Disk Space Script <br> for GitHub Enterprise Server (GHES) 

> [!NOTE]
> #### This script is independently maintained and is not [supported](https://docs.github.com/en/enterprise-server@3.13/admin/monitoring-managing-and-updating-your-instance/monitoring-your-instance/setting-up-external-monitoring) by GitHub.

Use (`disk_check.sh`) to quickly monitor disk space usage on a GitHub Enterprise Server ([GHES](https://docs.github.com/en/enterprise-server@3.13/admin/all-releases)).

## Features

- Displays the server time at run time.
- Provides filesystem and inode information.
- Reports the largest directories (to 5 levels deep).
- Reports the largest files and the largest files older than 30 days.
- Excludes some directories from scans, ie. (`/proc` and `/data/user/docker/overlay2`).

## Getting Started

### One-Liner to Run the Script

You can run the script directly from GitHub without cloning the repository. Use the following one-liner:

```sh
time bash <(curl -sL https://github.com/appatalks/gh_disk_space_check/raw/main/disk_check.sh)
```

### Optional add to ```cron```

To run the script every ```15 minutes``` as the "**admin**" user, follow these steps:

1. Download the script to `/home/admin`:

    ```sh
    curl -sL https://github.com/appatalks/gh_disk_space_check/raw/main/disk_check.sh -o /home/admin/disk_check.sh
    chmod +x /home/admin/disk_check.sh
    ```

2. Open the crontab for the ```admin``` user:

    ```sh
    crontab -e
    ```

3. Add the following line to the crontab:

    ```sh
    */15 * * * * bash /home/admin/disk_check.sh >> /home/admin/disk_check.log 2>&1
    ```

    This will run the script every 15 minutes and append the output to `/home/admin/disk_check.log`. <br>
    Remeber to remove from cron and purge the log when no longer required. Or risk running out of disk space!!

## Author

- appatalks

## Credit

This script was adapted from Rackspace's documentation on troubleshooting low disk space for a Linux cloud server:
https://docs.rackspace.com/docs/troubleshooting-low-disk-space-for-a-linux-cloud-server

## License

This project is licensed under the [GPL-3.0 license](https://github.com/appatalks/gh_disk_space_check/blob/50fff770e07c4b07178ae2939eab82fb45d4f92c/LICENSE).

