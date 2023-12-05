# 🚀 NGINX - Site Manager

This script simplifies the process of managing NGINX sites by providing a command-line interface for common operations such as enabling/disabling, listing, and editing site configurations. This script was designed for Ubuntu. If you want to modify it to make it work for other flavors as well, feel free.

## 🛠️ Usage

```bash
./nginx-sm.sh [options]
```

## ⚙️ Options

- `-e, --enable`: Enable a site by enabling its configuration file.
- `-d, --disable`: Disable a site by disabling its configuration file.
- `-l, --list`: List all available sites and their status.
- `-ed, --edit`: Edit the configuration file of a site.

## 📖 Examples

```bash
./nginx-sm.sh --enable example.com     # Enable the site example.com
./nginx-sm.sh --list                   # List all available sites
./nginx-sm.sh --edit example.com        # Edit the configuration of example.com
```

## 📚 Dependencies

- NGINX web server must be installed and running.
- The script requires sudo privileges to modify NGINX configuration files.

---

Copyright (c) 2023 nobody
Licensed under the MIT License.
