#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Detect PHP command (use 'php' from PATH instead of hardcoded path)
PHP_CMD="php"
if ! command -v "$PHP_CMD" &> /dev/null; then
    # Try fallback to /usr/local/bin/php
    if [ -x "/usr/local/bin/php" ]; then
        PHP_CMD="/usr/local/bin/php"
        echo "Warning: 'php' not found in PATH. Using fallback: $PHP_CMD"
    else
        echo "Error: PHP is not installed or not in PATH."
        exit 1
    fi
fi

# Function to display correct usage of the script
show_usage() {
    echo "Usage: $0 [-u <URL_ZIP>|-url <URL_ZIP>] [-s <URL_XML|URL_JSON>|-server <URL_XML|URL_JSON>] [-c <CHANNEL>|-channel <CHANNEL>] [-t <STABILITY>|-stability <STABILITY>] [-l <LANGUAGE>|-language <LANGUAGE>] [--patchtester]"
    echo "  -u, -url <URL_ZIP>:           Specify the direct URL of the Joomla! ZIP package to download."
    echo "                                  e.g. https://github.com/joomla/joomla-cms/releases/download/5.1.0-alpha4/Joomla_5.1.0-alpha4-Alpha-Full_Package.zip"
    echo "                                  e.g. https://developer.joomla.org/nightlies/Joomla_5.1.0-beta1-dev-Development-Full_Package.zip"
    echo "  -s, -server <URL_XML|URL_JSON>: Specify the URL of the update server (XML or JSON)."
    echo "                                  XML servers (Joomla 4.x/5.x):"
    echo "                                    e.g. https://update.joomla.org/core/sts/extension_sts.xml"
    echo "                                    e.g. https://update.joomla.org/core/j4/default.xml"
    echo "                                    e.g. https://update.joomla.org/core/j5/default.xml"
    echo "                                    e.g. https://update.joomla.org/core/test/extension_test.xml"
    echo "                                    e.g. https://update.joomla.org/core/nightlies/next_major_extension.xml"
    echo "                                  JSON servers (Joomla 6.x+):"
    echo "                                    e.g. https://update.joomla.org/cms/targets.json"
    echo "  -c, -channel <CHANNEL>:       Specify the channel (only for JSON servers, e.g., 5.x, 6.x)."
    echo "  -t, -stability <STABILITY>:   Specify the stability (only for JSON servers, e.g., stable, rc, alpha)."
    echo "  -l, -language <LANGUAGE>:     Specify the language for Joomla! installation."
    echo "                                  e.g. it-IT"
    echo "  --patchtester:                Install Joomla! Patch Tester extension."
    exit 1
}

# Initializing variables
download_url=""
update_server_url=""
channel=""
stability=""
install_patchtester=false # Flag to indicate whether to install Patch Tester extension
has_warnings=false # Track if any warnings occurred during installation

# Checking the arguments passed to the script
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u | -url)
            download_url="$2"
            # Validate URL format
            if [[ ! "$download_url" =~ ^https?:// ]]; then
                echo "Error: Invalid URL format for -u parameter. Must start with http:// or https://"
                exit 1
            fi
            shift 2
            ;;
        -s | -server)
            update_server_url="$2"
            # Validate URL format
            if [[ ! "$update_server_url" =~ ^https?:// ]]; then
                echo "Error: Invalid URL format for -s parameter. Must start with http:// or https://"
                exit 1
            fi
            shift 2
            ;;
        -c | -channel)
            channel="$2"
            shift 2
            ;;
        -t | -stability)
            stability="$2"
            shift 2
            ;;
        -l | -language)
            language="$2"
            # Validate language format (e.g., en-GB, it-IT)
            if [[ ! "$language" =~ ^[a-z]{2}-[A-Z]{2}$ ]]; then
                echo "Error: Invalid language format. Expected format: xx-XX (e.g., en-GB, it-IT)"
                exit 1
            fi
            shift 2
            ;;
        --patchtester)
            install_patchtester=true
            shift
            ;;
        *)
            show_usage
            ;;
    esac
done

# Checking whether one and only one of the two parameters is specified
if [[ -z $download_url && -z $update_server_url ]]; then
    echo "Error: Please specify one of the two parameters."
    show_usage
elif [[ ! -z $download_url && ! -z $update_server_url ]]; then
    echo "Error: Please specify only one of the two parameters."
    show_usage
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Helper Functions

# Generate a random alphanumeric prefix for database tables
# The prefix starts with a letter followed by random alphanumeric characters and ends with underscore
# @param $1 - Length of the prefix (excluding the trailing underscore)
# @return string - Random prefix (e.g., "a3x9z_")
function get_random_prefix() { # The table prefix must start with a letter, optionally be followed by alphanumeric characters and by an underscore
  local length=$1
  chars=( {a..z} {0..9} )
  first_char=${chars[RANDOM % 26]}
  rest_of_string=""
    for ((i=1; i<$length; i++)); do
      rest_of_string="${rest_of_string}${chars[RANDOM % 36]}"
    done
  echo "$first_char${rest_of_string}_"
}

# Print a formatted section title with yellow color and underline
# @param $1 - Title text to display
# @return void - Outputs formatted title to stdout
function print_title() {
  local text=$1
  color="33" # Yellow (comment style)
  printf '\n'
  printf '\033[%sm' $color
  printf '%s\n' "$text"
  printf "%0.s=" $(seq 1 ${#text})
  printf '\033[0m\n'
}

# Print a formatted result message with colored background box (Joomla-style)
# @param $1 - Message text to display
# @param $2 - Message type: "success"|"error"|"warning" (determines background color)
# @return void - Outputs formatted message box to stdout
function print_result() {
  local text=$1
  local type=$2
  padding_length=$((120 - ${#text}))
  color="0" # Reset/remove all modifier
  
  # Joomla-style colors (text color on colored background):
  # success: black text on green background
  # error: white text on red background
  # warning: black text on yellow background
  if [ "$type" == "success" ] || [ "$type" == "succes" ]; then
    color="30;42"  # Black on green background
  fi
  if [ "$type" == "error" ]; then
    color="37;41" # White on red background
  fi
  if [ "$type" == "warning" ] || [ "$type" == "warn" ]; then
    color="30;43" # Black on yellow background
  fi
  
  printf '\n'
  printf '\033[%sm' $color
  printf '%*s\n' 120
  printf ' %s%*s\n' "$text" $((padding_length - 1))
  printf '%*s\n' 120
  printf '\033[0m\n'
  printf '\n'
}

# Get the download URL for a Joomla extension from its XML update server
# Supports compatibility filtering based on target Joomla version using targetplatform
# @param $1 - Extension update server URL (XML format)
# @param $2 - (Optional) Joomla version for compatibility check (e.g., "4.4.14" or "5.1.0")
# @return string - Download URL of the latest compatible extension version
# @exit 1 - If no compatible version is found
function get_extension_package_url() {
  local EXTENSION_SERVER=$1
  local COMPATIBILITY="${2:-}"  # Optional: Joomla version to check compatibility (e.g., "4.4.14" or "5.1.0")
  
  php_code="\$context  = stream_context_create(array('http' => array('header' => 'Accept: application/xml')));
  \$url = '${EXTENSION_SERVER}'; // Retrieve the extension update server
  \$xml = file_get_contents(\$url, false, \$context);
  \$xml = simplexml_load_string(\$xml);
  \$max_version = \"0.0.0\";
  \$downloadurl = null;
  \$compatibility = '${COMPATIBILITY}';
  
  foreach(\$xml->update as \$update) {
    \$is_compatible = true;
    
    // Check compatibility if specified
    if (!empty(\$compatibility) && isset(\$update->targetplatform)) {
      \$is_compatible = false;
      foreach(\$update->targetplatform as \$platform) {
        if ((string)\$platform['name'] === 'joomla') {
          \$version_pattern = (string)\$platform['version'];
          // Convert pattern like '[45].[01234]' to regex
          \$regex_pattern = '/^' . str_replace('.', '\\\\.', \$version_pattern) . '/';
          if (preg_match(\$regex_pattern, \$compatibility)) {
            \$is_compatible = true;
            break;
          }
        }
      }
    }
    
    // Only consider compatible versions
    if (\$is_compatible && version_compare(\$update->version, \$max_version, '>')) {
      \$max_version = \$update->version;
      \$downloadurl = \$update->downloads->downloadurl;
    }
  }
  
  if (\$downloadurl === null) {
    exit(1); // No compatible version found
  }
  
  echo \$downloadurl;"
  
  downloadurl=$("$PHP_CMD" -r "${php_code}")
  echo "$downloadurl"
}

# Get Joomla core package URL from XML update server (Joomla 4.x/5.x)
# Retrieves the latest version available from the XML manifest
# @param $1 - Joomla update server URL (XML format)
# @return string - Download URL of the latest Joomla package
# @exit 1 - If no package is found or server is unreachable
function get_package_from_xml() {
  local UPDATE_SERVER=$1
  
  php_code="\$context = stream_context_create(array('http' => array('header' => 'Accept: application/xml')));
  \$url = '${UPDATE_SERVER}';
  \$xml = file_get_contents(\$url, false, \$context);
  \$xml = simplexml_load_string(\$xml);
  \$max_version = \"0.0.0\";
  \$downloadurl = null;
  
  foreach(\$xml->update as \$update) {
    if (version_compare(\$update->version, \$max_version, '>')) {
      \$max_version = \$update->version;
      \$downloadurl = \$update->downloads->downloadurl;
    }
  }
  
  if (\$downloadurl === null) {
    exit(1);
  }
  
  echo \$downloadurl;"
  
  downloadurl=$("$PHP_CMD" -r "${php_code}")
  echo "$downloadurl"
}

# Get Joomla core package URL from JSON/TUF update server (Joomla 6.x+)
# Supports filtering by channel and stability, tests multiple URL patterns for availability
# Implements intelligent sorting: channel > stability > version
# @param $1 - Joomla update server URL (JSON/TUF format)
# @param $2 - (Optional) Channel filter (e.g., "5.x", "6.x")
# @param $3 - (Optional) Stability filter (e.g., "stable", "rc", "alpha")
# @return string - Download URL of the best matching Joomla package
# @exit 1 - If no matching package is found or server is unreachable
function get_package_from_json() {
  local UPDATE_SERVER=$1
  local CHANNEL="${2:-}"
  local STABILITY="${3:-}"
  
  php_code="\$context = stream_context_create(array('http' => array('header' => 'Accept: application/json')));
  \$url = '${UPDATE_SERVER}';
  \$json = file_get_contents(\$url, false, \$context);
  \$data = json_decode(\$json, true);
  
  if (!isset(\$data['signed']['targets'])) {
    exit(1);
  }
  
  \$targets = \$data['signed']['targets'];
  \$packages = array();
  \$filterChannel = strtolower('${CHANNEL}');
  \$filterStability = strtolower('${STABILITY}');
  
  foreach (\$targets as \$filename => \$target) {
    if (!isset(\$target['custom'])) {
      continue;
    }
    
    \$custom = \$target['custom'];
    \$channel = isset(\$custom['channel']) ? strtolower(\$custom['channel']) : '';
    \$stability = isset(\$custom['stability']) ? strtolower(\$custom['stability']) : '';
    \$version = isset(\$custom['version']) ? \$custom['version'] : '';
    
    // Apply filters if specified
    if (!empty(\$filterChannel) && \$channel !== \$filterChannel) {
      continue;
    }
    if (!empty(\$filterStability) && \$stability !== \$filterStability) {
      continue;
    }
    
    // Get download URLs and test them
    \$downloads = isset(\$custom['downloads']) ? \$custom['downloads'] : array();
    if (empty(\$downloads)) {
      continue;
    }
    
    \$validUrl = null;
    foreach (\$downloads as \$download) {
      if (!isset(\$download['url'])) {
        continue;
      }
      
      \$url = \$download['url'];
      if (!filter_var(\$url, FILTER_VALIDATE_URL)) {
        continue;
      }
      
      // Test multiple URL patterns
      \$urlsToTest = array();
      
      // Pattern 1: Full_Package variant
      \$fullPackageUrl = str_replace('Update_Package.zip', 'Full_Package.zip', \$url);
      \$urlsToTest[] = \$fullPackageUrl;
      
      // Pattern 2: update.joomla.org format
      if (strpos(\$url, 'downloads.joomla.org') !== false) {
        if (preg_match('/\/(\\d+-\\d+-\\d+)\//', \$url, \$matches)) {
          \$versionPath = str_replace('-', '.', \$matches[1]);
          \$updateUrl = \"https://update.joomla.org/releases/\$versionPath/Joomla_\$versionPath-Stable-Full_Package.zip\";
          \$urlsToTest[] = \$updateUrl;
        }
      }
      
      // Pattern 3: GitHub releases
      if (strpos(\$url, 'github.com') !== false) {
        \$githubUrl = str_replace('-Update_Package.zip', '-Full_Package.zip', \$url);
        if (\$githubUrl !== \$url) {
          \$urlsToTest[] = \$githubUrl;
        }
      }
      
      // Pattern 4: Alternative dash format
      \$altUrl = preg_replace('/Joomla_(\\d+)\\.(\\d+)\\.(\\d+)/', 'Joomla_$1-$2-$3', \$fullPackageUrl);
      if (\$altUrl !== \$fullPackageUrl) {
        \$urlsToTest[] = \$altUrl;
      }
      
      // Test URLs
      foreach (\$urlsToTest as \$testUrl) {
        \$headers = @get_headers(\$testUrl, 1);
        if (\$headers && (strpos(\$headers[0], '200') !== false || strpos(\$headers[0], '302') !== false)) {
          \$validUrl = \$testUrl;
          break;
        }
      }
      
      if (\$validUrl) {
        break;
      }
    }
    
    if (\$validUrl) {
      // Stability priority for sorting
      \$stabilityPriority = 0;
      switch (\$stability) {
        case 'stable':
          \$stabilityPriority = 3;
          break;
        case 'rc':
        case 'release candidate':
          \$stabilityPriority = 2;
          break;
        case 'alpha':
          \$stabilityPriority = 1;
          break;
      }
      
      \$packages[] = array(
        'version' => \$version,
        'url' => \$validUrl,
        'channel' => \$channel,
        'stability' => \$stability,
        'stability_priority' => \$stabilityPriority
      );
    }
  }
  
  if (empty(\$packages)) {
    exit(1);
  }
  
  // Sort by channel, stability, then version
  usort(\$packages, function(\$a, \$b) {
    \$channelCompare = version_compare(\$b['channel'], \$a['channel']);
    if (\$channelCompare !== 0) {
      return \$channelCompare;
    }
    \$stabilityCompare = \$b['stability_priority'] - \$a['stability_priority'];
    if (\$stabilityCompare !== 0) {
      return \$stabilityCompare;
    }
    return -1 * version_compare(\$a['version'], \$b['version']);
  });
  
  echo \$packages[0]['url'];"
  
  downloadurl=$("$PHP_CMD" -r "${php_code}")
  echo "$downloadurl"
}

# Get Joomla core package URL with automatic server type detection
# Detects XML vs JSON format by file extension and routes to appropriate parser
# @param $1 - Joomla update server URL (XML or JSON format)
# @param $2 - (Optional) Channel filter (only for JSON servers, e.g., "5.x", "6.x")
# @param $3 - (Optional) Stability filter (only for JSON servers, e.g., "stable", "rc", "alpha")
# @return string - Download URL of the Joomla package
# @note Warns if channel/stability parameters are used with XML servers (they will be ignored)
function get_joomla_package_url() {
  local UPDATE_SERVER=$1
  local CHANNEL="${2:-}"
  local STABILITY="${3:-}"
  
  # Detect server type by URL pattern
  if [[ "$UPDATE_SERVER" =~ \.json$ ]]; then
    # JSON server (Joomla 6.x+)
    if [[ -n "$CHANNEL" || -n "$STABILITY" ]]; then
      get_package_from_json "$UPDATE_SERVER" "$CHANNEL" "$STABILITY"
    else
      get_package_from_json "$UPDATE_SERVER"
    fi
  else
    # XML server (Joomla 4.x/5.x)
    if [[ -n "$CHANNEL" || -n "$STABILITY" ]]; then
      echo "Warning: channel and stability parameters are ignored for XML servers." >&2
    fi
    get_package_from_xml "$UPDATE_SERVER"
  fi
}

# Extract the major version number from a Joomla package filename
# @param $1 - Joomla package filename (e.g., "Joomla_5.1.0-alpha4.zip")
# @return string - Major version number (e.g., "5")
# @exit 1 - If version cannot be detected from filename
function get_joomla_major_version() {
  local filename=$1
  # Extract version from filename (e.g., Joomla_5.1.0-alpha4 -> 5)
  if [[ $filename =~ Joomla[_-]([0-9]+)\. ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    print_result "[ERROR] Unable to detect Joomla major version from filename: $filename" "error"
    exit 1
  fi
}

# Extract the full semantic version from a Joomla package filename
# @param $1 - Joomla package filename (e.g., "Joomla_5.1.0-alpha4.zip")
# @return string - Full semantic version (e.g., "5.1.0")
# @exit 1 - If version cannot be detected from filename
function get_joomla_version() {
  local filename=$1
  # Extract full version from filename (e.g., Joomla_5.1.0-alpha4 -> 5.1.0)
  if [[ $filename =~ Joomla[_-]([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    print_result "[ERROR] Unable to detect Joomla version from filename: $filename" "error"
    exit 1
  fi
}

# Load configuration parameters from config.sh file
source jconfig.sh
DB_PREFIX="$(get_random_prefix 5)" # Prefix for the database tables [default: "gtlzk_"]

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Remove all files and folders including 'hidden' files like .htaccess or folder like '.well-known'
print_title "Cleanup installation path"
# Check if installation directory exists
if [ ! -d "$INSTALL_PATH" ]; then
    print_result "[ERROR] Installation path does not exist: $INSTALL_PATH" "error"
    exit 1
fi
echo "Direcories to keep: ${DIR_TO_KEEP[*]}"
echo "Files to keep: ${FILE_TO_KEEP[*]}"
for d in $(find $INSTALL_PATH -mindepth 1 -maxdepth 1 -type d); do
  if [[ ! " ${DIR_TO_KEEP[*]} " =~ " $(basename ${d}) " ]]; then
    rm -r "$d"
    printf '\e[36;49mremoved dir :\e[0m %s\n' "$d"
  fi
done
for f in $(find $INSTALL_PATH -mindepth 1 -maxdepth 1 -type f); do
  if [[ ! " ${FILE_TO_KEEP[*]} " =~ " $(basename ${f}) " ]]; then
    rm "$f"
    printf '\e[36;49mremoved file:\e[0m %s\n' "$f"
  fi
done
print_result "[OK] Removed all directories and files." "succes"



# Retrieve the Joomla package from url or update server
print_title "Retrieve Joomla package"
# If direct download URL is specified
if [[ ! -z $download_url ]]; then
    echo "Downloading from direct URL: $download_url"
    downloadurl=$download_url
fi
# If update server URL is specified
if [[ ! -z $update_server_url ]]; then
    echo "Extracting download URL from update server: $update_server_url"
    if [[ -n "$channel" || -n "$stability" ]]; then
        echo "Channel: ${channel:-any}, Stability: ${stability:-any}"
    fi
    downloadurl=$(get_joomla_package_url "${update_server_url}" "${channel}" "${stability}" | sed 's/Update_Package.zip/Full_Package.zip/g')
fi
filename=$(basename $downloadurl)
print_result "[OK] Joomla version $filename." "succes"



# Download the Full_Package zip file
print_title "Download the Full_Package zip file"
if ! wget "$downloadurl" -O "$INSTALL_PATH/$filename"; then
    print_result "[ERROR] Failed to download $filename." "error"
    exit 1
fi
print_result "[OK] $filename downloaded." "succes"



# Unzip the Full_Package zip file
print_title "Unzip the Full_Package zip file"
if ! unzip -q -o "$INSTALL_PATH/$filename" -d "$INSTALL_PATH"; then
    print_result "[ERROR] Failed to unzip $filename." "error"
    exit 1
fi
rm "$INSTALL_PATH/$filename"
print_result "[OK] $filename unzipped." "succes"



# Empty the DB from all the tables present
print_title "Cleanup DataBase"
php_code="\$dbconn;
if('$DB_TYPE' == 'mysqli') {
  \$dbconn = new mysqli('$DB_HOST', '$DB_USER', '$DB_PASS', '$DB_NAME');
} else if('$DB_TYPE' == 'mysql' || '$DB_TYPE' == 'pgsql') {
  \$dbconn = new PDO('$DB_TYPE:host=$DB_HOST;dbname=$DB_NAME', '$DB_USER', '$DB_PASS');
}
\$dbconn->query('SET foreign_key_checks = 0');
if (\$result = \$dbconn->query('SHOW TABLES')) {
  if('$DB_TYPE' == 'mysqli') {
    while(\$row = \$result->fetch_array(MYSQLI_NUM)) {
      if(!in_array(\$row[0], explode(' ', '${TABLE_TO_KEEP[*]}')))
        \$dbconn->query('DROP TABLE IF EXISTS '.\$row[0]);
    }
  } else if('$DB_TYPE' == 'mysql' || '$DB_TYPE' == 'pgsql') {
    while(\$row = \$result->fetch_array(FETCH_NUM)) {
      if(!in_array(\$row[0], explode(' ', '${TABLE_TO_KEEP[*]}')))
        \$dbconn->query('DROP TABLE IF EXISTS '.\$row[0]);
    }
  }
}
\$dbconn->query('SET foreign_key_checks = 1');
\$dbconn->close();"
if ! "$PHP_CMD" -r "${php_code}"; then
    print_result "[ERROR] Failed to cleanup database." "error"
    exit 1
fi
echo "Tables to keep: ${TABLE_TO_KEEP[*]}"
print_result "[OK] Dropped all tables from $DB_NAME." "succes"



# Install Joomla from the CLI
# https://docs.joomla.org/J4.x:Joomla_CLI_Installation
# https://github.com/joomla/joomla-cms/pull/38325
print_title "Install Joomla from CLI"

# Detect Joomla version
joomla_version=$(get_joomla_version "$filename")
echo "Detected Joomla version: $joomla_version"

# Build installation command
install_cmd=("$PHP_CMD" "$INSTALL_PATH/installation/joomla.php" "install" \
  --site-name="$SITE_NAME" \
  --admin-user="$ADMIN_USER" \
  --admin-username="$ADMIN_USERNAME" \
  --admin-password="$ADMIN_PASSWORD" \
  --admin-email="$ADMIN_EMAIL" \
  --db-type="$DB_TYPE" \
  --db-host="$DB_HOST" \
  --db-user="$DB_USER" \
  --db-pass="$DB_PASS" \
  --db-name="$DB_NAME" \
  --db-prefix="$DB_PREFIX" \
  --db-encryption=$DB_ENCRYPTION)

# Add public-folder parameter only for Joomla 5.0.0 and above
if "$PHP_CMD" -r "exit(version_compare('$joomla_version', '5.0.0', '>=') ? 0 : 1);"; then
    install_cmd+=(--public-folder="$PUBLIC_FOLDER")
    echo "Adding --public-folder parameter (Joomla >= 5.0.0)"
else
    echo "Skipping --public-folder parameter (Joomla < 5.0.0)"
fi

# Execute installation
if ! "${install_cmd[@]}"; then
    print_result "[ERROR] Joomla installation failed." "error"
    exit 1
fi
print_result "[OK] Joomla installed successfully." "succes"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Post installation steps
# https://docs.joomla.org/J4.x:CLI_Update
# https://magazine.joomla.org/all-issues/june-2022/joomla-4-a-powerful-cli-application

# Install Joomla language
if [[ "$language" ]]; then
    print_title "Install Joomla language"
    
    # Detect Joomla major version for language server
    joomla_major=$(get_joomla_major_version "$filename")
    echo "Installing ${language} language for Joomla ${joomla_major}.x"
    
    # Build language server URL based on major version
    lang_server_url="https://update.joomla.org/language/details${joomla_major}/${language}_details.xml"
    echo "Language server: $lang_server_url"
    
    # Get language package URL
    if ! lang_pkg="$(get_extension_package_url "$lang_server_url")"; then
        has_warnings=true
        print_result "[WARNING] Failed to retrieve language package for ${language}." "warning"
    else
        echo "Language package: $lang_pkg"
        
        # Install language extension
        if ! "$PHP_CMD" "$INSTALL_PATH/cli/joomla.php" extension:install --url="$lang_pkg"; then
            has_warnings=true
            print_result "[WARNING] Failed to install language ${language}." "warning"
        else
            print_result "[OK] Language ${language} installed." "success"

            # Change the Default language
            print_title "Change Default language"
            TABLE="${DB_PREFIX}extensions"
            php_code="\$dbconn;
            if('$DB_TYPE' == 'mysqli') {
              \$dbconn = new mysqli('$DB_HOST', '$DB_USER', '$DB_PASS', '$DB_NAME');
            } else if('$DB_TYPE' == 'mysql' || '$DB_TYPE' == 'pgsql') {
              \$dbconn = new PDO('$DB_TYPE:host=$DB_HOST;dbname=$DB_NAME', '$DB_USER', '$DB_PASS');
            }
            \$dbconn->query('UPDATE $TABLE SET params = \'{\"administrator\":\"${language}\",\"site\":\"${language}\"}\' WHERE name = \'com_languages\'');
            \$dbconn->close();"
            if ! "$PHP_CMD" -r "${php_code}"; then
                has_warnings=true
                print_result "[WARNING] Failed to change default language." "warning"
            else
                print_result "[OK] Default language changed to ${language}." "succes"
            fi
        fi
    fi
fi



# Install Joomla! Patch Tester extension if '--patchtester' flag is present
if [[ "$install_patchtester" == true ]]; then
    print_title "Install Joomla! Patch Tester"
    echo "Checking compatibility with Joomla $joomla_version"
    echo "Manifest server: https://raw.githubusercontent.com/joomla-extensions/patchtester/master/manifest.xml"
    
    if ! ext_pkg="$(get_extension_package_url https://raw.githubusercontent.com/joomla-extensions/patchtester/master/manifest.xml "$joomla_version")"; then
        has_warnings=true
        print_result "[WARNING] Failed to retrieve Patch Tester package URL." "warning"
    else
        echo "Patch Tester package: $ext_pkg"
        
        if ! "$PHP_CMD" "$INSTALL_PATH/cli/joomla.php" extension:install --url="$ext_pkg"; then
            has_warnings=true
            print_result "[WARNING] Failed to install Patch Tester extension." "warning"
        else
            print_result "[OK] Patch Tester extension installed." "succes"
        fi
    fi
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Add additional users if configured

if [ -v ADDITIONAL_USERS ] && [ ${#ADDITIONAL_USERS[@]} -gt 0 ]; then
    print_title "Add Additional Users"
    
    for user_data in "${ADDITIONAL_USERS[@]}"; do
        # Skip empty lines or comments
        [[ -z "$user_data" || "$user_data" =~ ^#.* ]] && continue
        
        # Parse user data (format: username|name|email|password|usergroup)
        IFS='|' read -r username name email password usergroup <<< "$user_data"
        
        echo "Adding user: $username ($name)"
        
        if ! "$PHP_CMD" "$INSTALL_PATH/cli/joomla.php" user:add \
            --username="$username" \
            --name="$name" \
            --password="$password" \
            --email="$email" \
            --usergroup="$usergroup"; then
            has_warnings=true
            print_result "[WARNING] Failed to add user: $username" "warning"
        else
            print_result "[OK] User added: $username" "success"
        fi
    done
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Final installation result
print_title "Installation Result"

joomla_name="${filename%-Full_Package.zip}"

if [ "$has_warnings" = true ]; then
    print_result "[WARNING] $joomla_name installation completed with warnings. Please review the output above for details." "warning"
else
    "$PHP_CMD" "$INSTALL_PATH/cli/joomla.php" config:get
    print_result "[SUCCESS] $joomla_name installation completed successfully!" "success"
fi

exit 0
