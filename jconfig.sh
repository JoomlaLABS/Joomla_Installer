INSTALL_PATH="/home/joomla/public_html"
DIR_TO_KEEP=(".well-known" "cgi-bin" ".not_remove_dir" "not_remove_dir")
FILE_TO_KEEP=(".htaccess" "delete.sh" ".not_remove_file" "not_remove_file")
TABLE_TO_KEEP=("aaa_do_not_remove1" "aaa_do_not_remove2")

SITE_NAME="Joomla! Demo" # Name of the website
ADMIN_USER="Joomla Demo" # Real name of the Super User account
ADMIN_USERNAME="Superuser" # Username of your Super User account
ADMIN_PASSWORD="**********" # Password of your Super User account
ADMIN_EMAIL="demo@joomla.org" # Email address of the website's Super User account

DB_TYPE="mysqli" # Database type. Supported by Joomla: mysql (=MySQL (PDO)), mysqli (=MySQLi), pgsql (=PostgreSQL (PDO)) [default: "mysqli"]
DB_HOST="localhost" # Database host [default: "localhost"]
DB_USER="demo_joomla" # Database username
DB_PASS="**********" # Database password
DB_NAME="demo_joomla_db" # Database name [default: "joomla_db"]
DB_ENCRYPTION=0 # Encryption for the database connection. Values: 0=None, 1=One way, 2=Two way [default:"0"]

DB_SSLKEY="" # SSL key for the database connection. Requires encryption to be set to 2
DB_SSLCERT="" # Path to the SSL certificate for the database connection. Requires encryption to be setto 2
DB_SSLVERIFYSERVERCERT="" #  Verify SSL certificate for database connection. Values: 0=No, 1=Yes. Requires encryption to be set to 1 or 2 [default: "0"]
DB_SSLCA="" #  Path to CA file to verify encryption against
DB_SSLCIPHER="" #  Supported Cipher Suite (optional)
PUBLIC_FOLDER="" #  Relative or absolute path to the public folder [default: ""]

# Additional users to create after installation (optional)
# Format: "username|name|email|password|usergroup1,usergroup2"
# usergroup: Super Users, Administrator, Manager, etc.
# Leave empty or comment out to skip user creation
ADDITIONAL_USERS=(
#     "test|User Test|test@test.com|**********|Super Users"
    "johndoe|John Doe|john.doe@example.com|**********|Manager,Editor"
)
