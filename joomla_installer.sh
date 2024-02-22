#!/bin/bash

# Function to display correct usage of the script
show_usage() {
    echo "Usage: $0 [-u <URL_ZIP>|-url <URL_ZIP>] [-s <URL_XML>|-server <URL_XML>] [-l <LANGUAGE>|-language <LANGUAGE>] [--patchtester]"
    echo "  -u, -url <URL_ZIP>:       Specify the direct URL of the Joomla! ZIP package to download."
    echo "                              e.g. https://github.com/joomla/joomla-cms/releases/download/5.1.0-alpha4/Joomla_5.1.0-alpha4-Alpha-Full_Package.zip"
    echo "                              e.g. https://developer.joomla.org/nightlies/Joomla_5.1.0-beta1-dev-Development-Full_Package.zip"
    echo "  -s, -server <URL_XML>:    Specify the URL of the XML Server from which to extract the download package."
    echo "                              e.g. https://update.joomla.org/core/sts/extension_sts.xml"
    echo "                              e.g. https://update.joomla.org/core/j4/default.xml"
    echo "                              e.g. https://update.joomla.org/core/j5/default.xml"
    echo "                              e.g. https://update.joomla.org/core/test/extension_test.xml"
    echo "                              e.g. https://update.joomla.org/core/nightlies/next_major_extension.xml"
    echo "                              e.g. https://update.joomla.org/core/nightlies/next_minor_extension.xml"
    echo "                              e.g. https://update.joomla.org/core/nightlies/next_patch_extension.xml"
    echo "  -l, -language <LANGUAGE>: Specify the language for Joomla! installation."
    echo "                              e.g. it-IT"
    echo "  --patchtester:            Install Joomla! Patch Tester extension."
    exit 1
}

# Initializing variables
download_url=""
update_server_url=""
install_patchtester=false # Flag to indicate whether to install Patch Tester extension

# Checking the arguments passed to the script
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u | -url)
            download_url="$2"
            shift 2
            ;;
        -s | -server)
            update_server_url="$2"
            shift 2
            ;;
        -l | -language)
            language="$2"
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
function print_title() {
  local text=$1
  color="33;49" # fg=Yellow;bg=Black
  printf '\n'
  printf '\e[%sm' $color
  printf '%s\n' "$text"
  printf "%0.s=" $(seq 1 ${#text})
  printf '\e[0m\n'
}
function print_result() {
  local text=$1
  local type=$2
  padding_length=$((120 - ${#text}))
  color="0" # Reset/remove all modifier
  if [ "$type" == "succes" ]; then
    color="30;42"  # fg=Black;bg=Green
  fi
  if [ "$type" == "error" ]; then
    color="30;41" # fg=Black;bg=Red
  fi
  printf '\n'
  printf '\e[%sm' $color
  printf '%*s\n' 120
  printf '%s%*s\n' "$text" $padding_length
  printf '%*s\n' 120
  printf '\e[0m\n'
  printf '\n'
}
function get_last_package_url() {
  local JOOMLA_SERVER=$1
  php_code="\$context  = stream_context_create(array('http' => array('header' => 'Accept: application/xml')));
  \$url = '${JOOMLA_SERVER}'; // Retrieve the Joomla! update servers
  \$xml = file_get_contents(\$url, false, \$context);
  \$xml = simplexml_load_string(\$xml);
  \$max_version = \"0.0.0\";
  \$downloadurl;
  foreach(\$xml->update as \$update) {
    if(version_compare(\$update->version, \$max_version, '>')) { //Search the latest release on the update server
      \$max_version = \$update->version;
      \$downloadurl = \$update->downloads->downloadurl;
    }
  }
  echo \$downloadurl;"
  downloadurl=$(/usr/local/bin/php -r "${php_code}")
  echo "$downloadurl"
}

# Load configuration parameters from config.sh file
source jconfig.sh
DB_PREFIX="$(get_random_prefix 5)" # Prefix for the database tables [default: "gtlzk_"]

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Remove all files and folders including 'hidden' files like .htaccess or folder like '.well-known'
print_title "Cleanup installation path"
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
print_result " [OK] Removed all directories and files." "succes"



# Retrieve the Joomla package from url or update server
print_title "Retrieve Joomla package"
# If direct download URL is specified
if [[ ! -z $download_url ]]; then
    echo "Downloading from direct URL: $download_url"
    downloadurl=$download_url
fi
# If XML URL from update server is specified
if [[ ! -z $update_server_url ]]; then
    echo "Extracting download URL from XML: $update_server_url"
    downloadurl=$(get_last_package_url ${update_server_url} | sed 's/Update_Package.zip/Full_Package.zip/g')
fi
filename=$(basename $downloadurl)
print_result " [OK] Joomla version $filename." "succes"



# Download the Full_Package zip file
print_title "Download the Full_Package zip file"
wget $downloadurl -O $INSTALL_PATH/$filename
print_result " [OK] $filename downloaded." "succes"



# Unzip the Full_Package zip file
print_title "Unzip the Full_Package zip file"
unzip -q -o $INSTALL_PATH/$filename -d $INSTALL_PATH 
rm $INSTALL_PATH/$filename
print_result " [OK] $filename unzipped." "succes"



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
/usr/local/bin/php -r "${php_code}"
echo "Tables to keep: ${TABLE_TO_KEEP[*]}"
print_result " [OK] Dropped all tables from $DB_NAME." "succes"



# Install Joomla from the CLI
# https://docs.joomla.org/J4.x:Joomla_CLI_Installation
# https://github.com/joomla/joomla-cms/pull/38325
/usr/local/bin/php $INSTALL_PATH/installation/joomla.php install \
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
  --db-encryption=$DB_ENCRYPTION \
  --public-folder=$PUBLIC_FOLDER

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# Post installation steps
# https://docs.joomla.org/J4.x:CLI_Update
# https://magazine.joomla.org/all-issues/june-2022/joomla-4-a-powerful-cli-application

# Install Joomla language
if [[ "$language" ]]; then
    #echo "Installing ${language} Joomla language"
    lang_pkg="$(get_last_package_url https://update.joomla.org/language/details5/${language}_details.xml)" # TODO: details4 or details5 switch
    /usr/local/bin/php $INSTALL_PATH/cli/joomla.php extension:install \
      --url="$lang_pkg"
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
    /usr/local/bin/php -r "${php_code}"
    print_result " [OK] Default language changed" "succes"
fi



# Install Joomla! Patch Tester extension if '-patchtester' flag is present
if [[ "$install_patchtester" == true ]]; then
    #echo "Install Joomla! Patch Tester"
    ext_pkg="$(get_last_package_url https://raw.githubusercontent.com/joomla-extensions/patchtester/master/manifest.xml)"
    /usr/local/bin/php $INSTALL_PATH/cli/joomla.php extension:install \
      --url="$ext_pkg"
fi


exit 0
