# Joomla_Installer
Bash script to automatically install Joomla! with advanced features for version management, language installation, and extension compatibility.

## Features
- ✅ Automatic Joomla! installation from direct URL or update server
- ✅ Auto-detection of Joomla version (4.x, 5.x, 6.x)
- ✅ Automatic language pack installation with version compatibility
- ✅ Joomla! Patch Tester extension with automatic compatibility check
- ✅ Automatic creation of additional users with custom usergroups
- ✅ Smart cleanup of existing installation (preserves specified files/directories/tables)
- ✅ Database management with selective table preservation
- ✅ Colored output with clear success/warning/error messages
- ✅ Input validation (URL format, language code)
- ✅ Error handling with detailed feedback

## Requirements
- **PHP** (command-line): Available in PATH or at `/usr/local/bin/php`
- **wget**: For downloading packages
- **unzip**: For extracting Joomla packages
- **MySQL/MariaDB** or **PostgreSQL**: Database server
- **Bash**: Shell environment

## Configuration & Installation
1. **Populate `jconfig.sh`** with your configuration:
   - Installation path
   - Database credentials
   - Admin user details
   - Additional users (optional)
   - Files/directories/tables to preserve during cleanup
   
2. **Upload files** to your server:
   - `joomla_installer.sh`
   - `jconfig.sh`

3. **Set permissions**:
   ```bash
   chmod 755 joomla_installer.sh
   chmod 644 jconfig.sh
   ```

4. **Convert line endings** (if uploaded from Windows):
   ```bash
   dos2unix joomla_installer.sh jconfig.sh
   # or
   sed -i 's/\r$//' joomla_installer.sh jconfig.sh
   ```

## Usage

### Basic Syntax
```bash
./joomla_installer.sh [-u <URL_ZIP>|-url <URL_ZIP>] [-s <URL_XML>|-server <URL_XML>] [-l <LANGUAGE>|-language <LANGUAGE>] [--patchtester]
```

### Parameters
- **`-u, -url <URL_ZIP>`**: Direct URL of the Joomla! ZIP package
  - Example: `https://github.com/joomla/joomla-cms/releases/download/5.1.0-alpha4/Joomla_5.1.0-alpha4-Alpha-Full_Package.zip`
  - Example: `https://developer.joomla.org/nightlies/Joomla_5.1.0-beta1-dev-Development-Full_Package.zip`

- **`-s, -server <URL_XML>`**: URL of the XML update server (auto-selects latest version)
  - Example: `https://update.joomla.org/core/j4/default.xml` (Joomla 4.x stable)
  - Example: `https://update.joomla.org/core/j5/default.xml` (Joomla 5.x stable)
  - Example: `https://update.joomla.org/core/sts/extension_sts.xml` (Short Term Support)
  - Example: `https://update.joomla.org/core/test/extension_test.xml` (Testing)
  - Example: `https://update.joomla.org/core/nightlies/next_major_extension.xml` (Nightly builds)
  - Example: `https://update.joomla.org/core/nightlies/next_minor_extension.xml`
  - Example: `https://update.joomla.org/core/nightlies/next_patch_extension.xml`

- **`-l, -language <LANGUAGE>`**: Language code for installation (format: `xx-XX`)
  - Example: `it-IT` (Italian)
  - Example: `en-GB` (English)
  - Example: `fr-FR` (French)
  - Example: `de-DE` (German)
  - **Note**: Automatically selects correct language server based on Joomla version

- **`--patchtester`**: Install Joomla! Patch Tester extension
  - **Note**: Automatically selects compatible version based on installed Joomla version

### Examples

#### Install Joomla 5 from direct URL with Italian language and Patch Tester
```bash
./joomla_installer.sh -url "https://github.com/joomla/joomla-cms/releases/download/5.1.0-alpha4/Joomla_5.1.0-alpha4-Alpha-Full_Package.zip" -language "it-IT" --patchtester
```

#### Install latest Joomla 5.x stable with Italian language
```bash
./joomla_installer.sh -server "https://update.joomla.org/core/j5/default.xml" -language "it-IT"
```

#### Install latest Joomla 4.x stable with Patch Tester
```bash
./joomla_installer.sh -server "https://update.joomla.org/core/j4/default.xml" --patchtester
```

#### Install latest nightly build (English only)
```bash
./joomla_installer.sh -server "https://update.joomla.org/core/nightlies/next_major_extension.xml"
```

## How It Works

### Installation Process
1. **Cleanup**: Removes all files and folders except those specified in `jconfig.sh`
2. **Download**: Retrieves Joomla package from URL or update server
3. **Extract**: Unzips the package to the installation path
4. **Database Cleanup**: Drops all tables except those specified in `jconfig.sh`
5. **Installation**: Runs Joomla CLI installer with configured parameters
6. **Language** (optional): Installs and sets default language
7. **Patch Tester** (optional): Installs compatible Patch Tester extension
8. **Additional Users** (optional): Creates configured users with custom usergroups
9. **Final Report**: Shows success or warnings summary

### Version Detection
- Extracts version from filename (e.g., `Joomla_4.4.14-Stable` → `4.4.14`)
- Automatically determines major version for language server selection
- For Joomla < 5.0.0: Skips `--public-folder` parameter (not supported)
- For Joomla ≥ 5.0.0: Adds `--public-folder` parameter

### Extension Compatibility
The script intelligently checks extension compatibility using `targetplatform` information from manifest XML files. For example, Patch Tester with pattern `[45].[01234]` is compatible with:
- Joomla 4.0, 4.1, 4.2, 4.3, 4.4
- Joomla 5.0, 5.1, 5.2, 5.3, 5.4

## Configuration File (`jconfig.sh`)

### Example Configuration
```bash
INSTALL_PATH="/home/user/public_html"
DIR_TO_KEEP=(".well-known" "cgi-bin")
FILE_TO_KEEP=(".htaccess" "robots.txt")
TABLE_TO_KEEP=("backup_table1" "backup_table2")

# Site Configuration
SITE_NAME="My Joomla Site"
ADMIN_USER="Administrator"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="SecurePassword123"
ADMIN_EMAIL="admin@example.com"

# Database Configuration
DB_TYPE="mysqli"              # mysqli, mysql (PDO), pgsql (PDO)
DB_HOST="localhost"
DB_USER="db_username"
DB_PASS="db_password"
DB_NAME="db_name"
DB_ENCRYPTION=0               # 0=None, 1=One way, 2=Two way
PUBLIC_FOLDER=""              # For Joomla 5.x+

# Additional Users (optional)
# Format: "username|name|email|password|usergroup1,usergroup2"
ADDITIONAL_USERS=(
    "editor|Editor User|editor@example.com|password123|Editor"
    "manager|Manager User|manager@example.com|password123|Manager"
    "multi|Multi Group User|multi@example.com|password123|Manager,Editor"
)
```

### User Configuration

The `ADDITIONAL_USERS` array allows you to automatically create users during installation. Each entry follows this format:
```bash
"username|full name|email|password|usergroup1,usergroup2,..."
```

**Available Usergroups**:
- `Super Users` - Full administrative access
- `Administrator` - Administrative access without super user privileges
- `Manager` - Content and media management
- `Editor` - Content editing capabilities
- `Author` - Content creation
- `Registered` - Basic registered user
- `Guest` - Public access (default)

**Examples**:
```bash
# Single usergroup
"john|John Doe|john@example.com|SecurePass123|Manager"

# Multiple usergroups (comma-separated, no spaces)
"jane|Jane Smith|jane@example.com|SecurePass456|Manager,Editor"

# Comment out users to skip creation
# "test|Test User|test@example.com|test123|Registered"
```

**Note**: If `ADDITIONAL_USERS` is not defined or commented out in `jconfig.sh`, the script will skip user creation without errors.

## Output Messages

### Success Messages (Green)
- `[OK]` - Operation completed successfully

### Warning Messages (Yellow)
- `[WARNING]` - Non-critical issue (installation can continue)
- Common warnings:
  - Failed to install language pack
  - Failed to install Patch Tester
  - Failed to change default language
  - Failed to add additional user

### Error Messages (Red)
- `[ERROR]` - Critical error (installation stops)
- Common errors:
  - Download failed
  - Unzip failed
  - Database cleanup failed
  - Joomla installation failed
  - Unable to detect version from filename

## Troubleshooting

### "Permission denied" error
```bash
chmod +x joomla_installer.sh
```

### "bad interpreter: No such file or directory"
Line endings issue (CRLF instead of LF):
```bash
dos2unix joomla_installer.sh
# or
sed -i 's/\r$//' joomla_installer.sh
```

### "PHP is not installed or not in PATH"
Install PHP CLI or create symlink:
```bash
# Check if PHP exists
which php
# If not in PATH but exists elsewhere:
ln -s /path/to/php /usr/local/bin/php
```

### Language installation fails
- Verify language code format (`xx-XX`)
- Check internet connection
- Language may not be available for that Joomla version

### Patch Tester installation fails
- May not be compatible with installed Joomla version
- Check manifest URL is accessible
- Verify internet connection

### User creation fails
- Check username format (alphanumeric, no spaces)
- Verify email format is valid
- Ensure usergroup names are correct (case-sensitive)
- Password must meet Joomla's requirements
- Username may already exist in database

## Advanced Features

### Selective Cleanup
Configure in `jconfig.sh`:
- **`DIR_TO_KEEP`**: Directories to preserve (e.g., `.well-known` for SSL)
- **`FILE_TO_KEEP`**: Files to preserve (e.g., `.htaccess` for rewrite rules)
- **`TABLE_TO_KEEP`**: Database tables to preserve (e.g., backup tables)

### Random Table Prefix
Each installation generates a random 5-character prefix starting with a letter (e.g., `a3x9z_`) for enhanced security.

### Additional Users Creation
Automatically creates users after installation with:
- Custom usernames and full names
- Email addresses
- Passwords
- Multiple usergroups support (comma-separated)
- Skips empty or commented lines in configuration

### Exit Codes
- `0`: Success
- `1`: Error (with detailed message)

## TO DO
- [ ] Support for additional extensions
- [ ] Bulk extension installation from configuration

## Demo
https://github.com/JoomlaLABS/Joomla_Installer/assets/906604/0343d9b6-c12b-49dd-986f-fb0446a63611

## License
This project is licensed under the GNU General Public License v2.0 - see the [LICENSE](LICENSE) file for details.

## Credits
Developed by JoomlaLABS
