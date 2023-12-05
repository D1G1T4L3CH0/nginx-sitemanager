# 🚀 NGINX - Site Manager

This script simplifies the process of managing NGINX sites by providing a command-line interface for common operations such as enabling/disabling, listing, editing, creating, and removing site configurations. This script was designed for Ubuntu. If you want to modify it to make it work for other flavors as well, feel free.

## 🛠️ Usage

```bash
./nginx-sm.sh [options]
```

## ⚙️ Options

- `-e, --enable`: Enable a site by enabling its configuration file.
- `-d, --disable`: Disable a site by disabling its configuration file.
- `-l, --list`: List all available sites and their status.
- `-ed, --edit`: Edit the configuration file of a site.
- `-c, --create`: Create a new configuration file for a site.
- `-r, --remove`: Remove a site's configuration file.

## 📖 Examples

```bash
./nginx-sm.sh --enable example.com     # Enable the site example.com
./nginx-sm.sh --list                   # List all available sites
./nginx-sm.sh --edit example.com       # Edit the configuration of example.com
./nginx-sm.sh --create example.com     # Create a new configuration for example.com
./nginx-sm.sh --remove example.com     # Remove the configuration for example.com
```

## 📚 Dependencies

- NGINX web server must be installed and running.
- The script requires sudo privileges to modify NGINX configuration files.

## Exit Codes

The script uses the following exit codes to indicate the result of an operation:

- `0`: Success - The operation completed successfully.
- `1`: General error - For example, site configuration file not found, or the specified site does not exist in either available or enabled directories.
- `2`: User cancellation - The user aborted the operation (specific to the `remove_site` command).
- `3`: Nginx configuration test failed - This is specific to the `enable_site` command and indicates that Nginx has failed the configuration test after attempting to enable a site.

---

Copyright (c) 2023 nobody
Licensed under the MIT License.
