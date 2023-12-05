#!/bin/bash

################################################################################
# NGINX - Site Manager
#
# This script manages NGINX sites, providing functionality for enabling/disabling,
# listing, editing, creating, and removing site configurations. It simplifies the
# process of managing NGINX sites by providing a command-line interface for common
# operations.
#
# Usage:
#   ./nginx-sm.sh [options] <site>
#
# Options:
#   -e, --enable <site>     Enable a site by enabling its configuration file.
#   -d, --disable <site>    Disable a site by disabling its configuration file.
#   -l, --list              List all available sites and their status.
#   -ed, --edit <site>      Edit the configuration file of a site.
#   --editor <editor>       Set editor for editing configurations.
#   -c, --create <site>     Create a new site configuration.
#   -rm, --remove <site>    Remove an existing site configuration.
#   -h, --help              Display help information.
#
# Examples:
#   ./nginx-sm.sh --enable example.com    # Enable the site example.com
#   ./nginx-sm.sh --list                  # List all available sites
#   ./nginx-sm.sh --edit example.com      # Edit the configuration of example.com
#   ./nginx-sm.sh --create example.com    # Create a new configuration for example.com
#   ./nginx-sm.sh --remove example.com    # Remove the configuration for example.com
#
# Dependencies:
#   - NGINX web server must be installed and running.
#   - The script requires sudo privileges to modify NGINX configuration files.
#
# Global Exit Codes:
#   0 - Success, the operation completed successfully.
#   1 - General error, such as a missing site configuration or invalid command.
#   2 - Operation cancelled by the user.
#   3 - Nginx configuration test failed (specific to enable_site command).
#
# Copyright (c) [2023] [nobody]
# Licensed under the MIT License.
################################################################################

# MIT License

# Copyright (c) [2023] [nobody]

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

declare -g site_to_enable=""
declare -g site_to_disable=""
declare -g site_to_edit=""
declare -g list_sites=false
declare -g display_help=false
declare -g create=""
declare -g editor="nano"

# Fetch NGINX configuration directories
get_config_dirs() {
    if ! command -v nginx >/dev/null 2>&1; then
        echo "Error: nginx command not found."
        exit 1
    fi

    local confFile=$(nginx -V 2>&1 | grep -o 'conf-path=[^ ]*' | cut -d= -f2)
    local confDir=$(dirname "$confFile")
    declare -g sitesAvail="$confDir/sites-available"
    declare -g sitesEnabled="$confDir/sites-enabled"

    if [ ! -d "$sitesAvail" ] || [ ! -d "$sitesEnabled" ]; then
        echo "Error: Unable to find NGINX sites-available or sites-enabled directory."
        exit 1
    fi
}

# Initialize variables
initialize_variables() {
    site_to_enable=""
    site_to_disable=""
    site_to_edit=""
    list_sites=false
    display_help=false
    create=""
    editor="nano"
}

# Check if script was run using sudo for options that require it
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo "Please run this script with sudo or as root."
        exit 1
    fi
}

# Display help for script usage
show_help() {
    echo -e "\nnginx Site Manager"
    echo -e "Usage: $(basename "$0") [options] <site>\n"
    echo -e "Options:"
    echo -e "\t-e, --enable <site>     Enable site"
    echo -e "\t-d, --disable <site>    Disable site"
    echo -e "\t-l, --list              List sites"
    echo -e "\t-ed, --edit <site>      Edit site configuration"
    echo -e "\t--editor <editor>       Set editor for editing configurations"
    echo -e "\t-c, --create <site>     Create a new site configuration"
    echo -e "\t-rm, --remove <site>    Remove an existing site configuration"
    echo -e "\t-h, --help              Display this help message"
    echo -e "\n"
}

# Enable a specified site by creating a symbolic link in the sites-enabled directory
enable_site() {
    local site=$1
    local site_avail_path="$sitesAvail/$site"
    local site_enabled_path="$sitesEnabled/$site"

    if [ ! -e "$site_avail_path" ]; then
        echo "Site does not appear to exist."
        return 1
    fi

    if [ -e "$site_enabled_path" ]; then
        echo "Site appears to already be enabled."
        return 2
    fi

    check_sudo

    # Enable the site by creating a symbolic link
    ln -s "$site_avail_path" "$site_enabled_path"

    # Now check the configuration after enabling the site
    if nginx -t; then
        echo "Configuration test passed. Reloading Nginx."
        nginx -s reload
        echo "Site enabled and Nginx reloaded."
    else
        # If the configuration test fails, remove the symbolic link to revert the change
        echo "Configuration test failed. Disabling the site."
        rm "$site_enabled_path"
        return 3
    fi
}

# Disable a specified site by removing the symbolic link in the sites-enabled directory
disable_site() {
    local site=$1
    if [ ! -e "$sitesEnabled/$site" ]; then
        echo "Site does not appear to be enabled."
    else
        check_sudo
        rm "$sitesEnabled/$site"
        echo "Site disabled."
    fi
}

# List all available and enabled sites
list_sites() {
    echo "Available sites (not enabled):"
    for site in "$sitesAvail"/*; do
        local site=$(basename "$site")
        if [ ! -e "$sitesEnabled/$site" ]; then
            echo -e "\t$site"
        fi
    done

    echo -e "\nEnabled sites:"
    for site in "$sitesEnabled"/*; do
        echo -e "\t$(basename "$site")"
    done
}

# Check if the editor is available
check_editor() {
    if ! command -v $1 >/dev/null 2>&1; then
        echo "Editor $1 not found."
        return 1
    fi
    return 0
}

# Edit a specified site using the preferred editor
edit_site() {
    local site=$1
    if [ ! -e "$sitesAvail/$site" ]; then
        echo "Site does not appear to exist."
    else
        $editor "$sitesAvail/$site"
    fi
}

create_site() {
    # Assign the first argument to the variable 'site'
    local site=$1

    # Check if the site configuration already exists
    if [ -e "$sitesAvail/$site" ]; then
        echo "Site already exists."
    else
        # Ensure the user has administrative privileges
        check_sudo
        
        # Create a new site configuration file
        touch "$sitesAvail/$site"
        echo "Site created."

        # Prompt the user to edit the new site configuration
        echo -n "Do you want to edit the new site? [y/n]: "
        
        # Save current stty configuration and set stty for raw input
        local old_stty_cfg=$(stty -g)
        stty raw -echo
        
        # Read a single character from the user
        answer=$(head -c 1)
        
        # Restore previous stty configuration
        stty $old_stty_cfg
        
        # Check if the user answered 'yes' (case insensitive)
        if echo "$answer" | grep -iq "^y" ; then
            # Open the site configuration file in the default editor
            $editor "$sitesAvail/$site"
        fi
    fi
}

# Remove a specified site
remove_site() {
    local site=$1
    local site_avail_path="$sitesAvail/$site"
    local site_enabled_path="$sitesEnabled/$site"

    if [[ ! -e "$site_avail_path" && ! -L "$site_enabled_path" ]]; then
        echo "Site does not appear to exist."
        return 1
    fi

    check_sudo

    echo "You are about to remove the site: $site"
    read -r -p "Type 'yes' to confirm: " confirmation
    if [[ $confirmation != "yes" ]]; then
        echo "Site removal cancelled."
        return 2
    fi

    # Remove enabled site symlink if it exists
    if [ -L "$site_enabled_path" ]; then
        rm "$site_enabled_path"
        echo "Removed symlink from $site_enabled_path."
    fi

    # Remove available site file if it exists
    if [ -e "$site_avail_path" ]; then
        rm "$site_avail_path"
        echo "Removed file from $site_avail_path."
    fi

    echo "Site $site removed successfully."
}

# Check if the string contains only spaces
is_all_spaces() {
    local input_string="$1"
    if [[ "$input_string" =~ ^[[:space:]]+$ ]]; then
        echo "The string consists only of spaces. Exiting the script."
        exit 1
    fi
}

# Parse command line arguments
parse_arguments() {
    while [ "$#" -gt 0 ]; do
        local key="$1"
        case "$key" in
            -e|--enable)
                if [ -z "$2" ]; then
                    echo "No site specified to enable. Use -h for help."
                    exit 1
                fi
                is_all_spaces "$2"
                check_sudo
                site_to_enable="$2"
                shift
                ;;
            -d|--disable)
                if [ -z "$2" ]; then
                    echo "No site specified to disable. Use -h for help."
                    exit 1
                fi
                is_all_spaces "$2"
                check_sudo
                site_to_disable="$2"
                shift
                ;;
            -ed|--edit)
                if [ -z "$2" ]; then
                    echo "No site specified to edit. Use -h for help."
                    exit 1
                fi
                is_all_spaces "$2"
                check_sudo
                site_to_edit="$2"
                shift
                ;;
            --editor)
                if [ -z "$2" ]; then
                    echo "No editor specified. Use -h for help."
                    exit 1
                fi
                is_all_spaces "$2"
                editor="$2"
                shift
                ;;
            -c|--create)
                if [ -z "$2" ]; then
                    echo "No site specified. Use -h for help."
                    exit 1
                fi
                is_all_spaces "$2"
                create="$2"
                shift
                ;;
            -rm|--remove)
                if [ -z "$2" ]; then
                    echo "No site specified. Use -h for help."
                    exit 1
                fi
                is_all_spaces "$2"
                check_sudo
                remove="$2"
                shift
                ;;
            -l|--list)
                list_sites=true
                ;;
            -h|--help)
                display_help=true
                ;;
            *)
                echo "Unknown option: $key"
                exit 1
                ;;
        esac
        shift
    done
}

# Main function
main() {
    initialize_variables
    parse_arguments "$@"
    get_config_dirs

    if [ -z "$1" ]; then
        display_help=true
    fi

    if $display_help; then
        if [ -n "$site_to_enable" ] || [ -n "$site_to_disable" ] || [ -n "$site_to_edit" ] || $list_sites; then
            echo "Warning: --help was provided along with other options. Ignoring other options."
        fi
        show_help
        exit 0
    fi

    if [ -n "$site_to_enable" ]; then
        enable_site "$site_to_enable"
    fi

    if [ -n "$site_to_disable" ]; then
        disable_site "$site_to_disable"
    fi

    if $list_sites; then
        list_sites
    fi

    if check_editor "$editor"; then
        if [ -n "$site_to_edit" ]; then
            edit_site "$site_to_edit"
        fi

        if [ -n "$create" ]; then
            create_site "$create"
        fi

        if [ -n "$remove" ]; then
            remove_site "$remove"
        fi
    fi
}

main "$@"