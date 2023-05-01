#!/bin/bash

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

# Variables
INSTALL_PATH="/home/joomlasviluppo/public_html"
DIR_TO_KEEP=(".well-known" "cgi-bin" ".not_remove_dir" "not_remove_dir")
FILE_TO_KEEP=("joomla_installer.sh" ".not_remove_file" "not_remove_file")
TABLE_TO_KEEP=("do_not_remove1" "do_not_remove2")

# Joomla Update Server
# stable        => https://update.joomla.org/core/sts/extension_sts.xml
# test          => https://update.joomla.org/core/test/extension_test.xml
# nightly-major => https://update.joomla.org/core/nightlies/next_major_extension.xml
# nightly-minor => https://update.joomla.org/core/nightlies/next_minor_extension.xml
# nightly-patch => https://update.joomla.org/core/nightlies/next_patch_extension.xml
JOOMLA_SERVER="https://update.joomla.org/core/nightlies/next_minor_extension.xml"

SITE_NAME="Joomla! Demo" # The name of your Joomla site
ADMIN_USER="Joomla Demo" # The real name of your Super User
ADMIN_USERNAME="Superuser" # The username for your Super User account
ADMIN_PASSWORD="**********" # The password for your Super User account
ADMIN_EMAIL="demo@joomla.org" # The email address of the website Super User

DB_TYPE="mysqli" # Database type. Supported: mysql (=MySQL (PDO)), mysqli (=MySQLi), pgsql (=PostgreSQL (PDO))
DB_HOST="localhost" # Database host
DB_USER="demo_joomla" # Database username
DB_PASS="**********" # Database password
DB_NAME="demo_joomla_db" # Database name
DB_PREFIX="$(get_random_prefix 5)" # Prefix for the database tables
DB_ENCRYPTION=0 # Encryption for the database connection. Values: 0=None, 1=One way, 2=Two way

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


# Retrieve the package url of the latest joomla version
print_title "Retrieve latest Joomla version"
php_code="\$context  = stream_context_create(array('http' => array('header' => 'Accept: application/xml')));
\$url = '${JOOMLA_SERVER}'; // Retrieve the Joomla! Core update servers
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
\$downloadurl = str_replace('Update_Package.zip', 'Full_Package.zip', \$downloadurl); // Transform the url of the update packages into the url of the installation package
echo \$downloadurl;"
downloadurl=$(/usr/local/bin/php -r "${php_code}")
filename=$(basename $downloadurl)
echo "Download URL: $downloadurl"
print_result " [OK] Latest version is $filename." "succes"


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
  --db-encryption=$DB_ENCRYPTION


# Post installation steps
# https://docs.joomla.org/J4.x:CLI_Update
# https://magazine.joomla.org/all-issues/june-2022/joomla-4-a-powerful-cli-application

# Install extensions
/usr/local/bin/php $INSTALL_PATH/cli/joomla.php extension:install \
  --url="https://github.com/joomla-extensions/patchtester/releases/download/4.2.1/com_patchtester_4.2.1.zip"
/usr/local/bin/php $INSTALL_PATH/cli/joomla.php extension:install \
  --url="https://downloads.joomla.org/it/language-packs/translations-joomla4/downloads/joomla4-italian/4-3-0-1/it-it_joomla_lang_full_4-3-0v1-zip"
# Add users
/usr/local/bin/php $INSTALL_PATH/cli/joomla.php user:add \
  --username="test" \
  --name="User Test" \
  --password="test123" \
  --email="test@test.com" \
  --usergroup="Administrator" # usergroup (separate multiple groups with comma ",")
# Displays the current value of a configuration option
#php cli/joomla.php config:get
