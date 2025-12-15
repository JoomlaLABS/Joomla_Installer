# Joomla_Installer

![Joomla Installer Banner](https://via.placeholder.com/1200x300/1c3d5a/ffffff?text=Joomla!+Automated+Installer)

![GitHub all releases](https://img.shields.io/github/downloads/JoomlaLABS/Joomla_Installer/total?style=for-the-badge&color=blue)
![GitHub release (latest by SemVer)](https://img.shields.io/github/downloads/JoomlaLABS/Joomla_Installer/latest/total?style=for-the-badge&color=blue)
![GitHub release (latest by SemVer)](https://img.shields.io/github/v/release/JoomlaLABS/Joomla_Installer?sort=semver&style=for-the-badge&color=blue)

[![License](https://img.shields.io/badge/license-GPL%202.0%2B-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green?logo=gnu-bash)](https://www.gnu.org/software/bash/)

## Description

Joomla_Installer is a powerful Bash script that revolutionizes the Joomla! deployment process by completely automating installation from the command line. Built for developers, site administrators, and DevOps professionals who need rapid, repeatable Joomla installations without manual intervention.

Perfect for creating development environments, staging servers, automated testing pipelines, and production deployments with complete control over database configuration, language selection, extension installation, and user management.

## ✨ Key Features

### 🚀 Automated Installation
- **One-Command Deployment**: Complete Joomla installation with a single command
- **Zero Manual Steps**: No GUI interaction required
- **Repeatable Process**: Perfect for CI/CD pipelines and automated testing
- **Smart Version Detection**: Automatically adapts to Joomla 4.x, 5.x, and 6.x features

### 🌍 Multi-Version Support
- **Joomla 4.x/5.x**: XML update server support with automatic latest version selection
- **Joomla 6.x**: JSON/TUF update server support with advanced filtering
- **Channel Filtering**: Select specific Joomla series (5.x, 6.x)
- **Stability Filtering**: Choose between stable, RC, and alpha releases
- **Version Auto-Detection**: Adapts installation parameters based on detected version

### 🔧 Advanced Configuration
- **Language Installation**: Automatic language pack download and installation with version compatibility
- **Extension Support**: Install Joomla! Patch Tester with automatic compatibility checking
- **User Management**: Bulk user creation with custom usergroups from configuration file
- **Database Control**: Selective table preservation during cleanup
- **Smart Cleanup**: Preserves specified files and directories during re-installation

### 🎯 Intelligent Package Resolution
- **Multi-Pattern URL Testing**: Tests 4 different URL patterns for maximum compatibility
- **Auto-Format Detection**: XML vs JSON server automatic detection
- **Fallback Mechanisms**: Multiple download sources for reliability
- **Compatibility Checking**: Extension targetplatform validation against Joomla version

### 🎨 Developer Experience
- **Colored Output**: Joomla-style colored result boxes (success, warning, error)
- **Detailed Logging**: Clear progress indication for each installation step
- **Input Validation**: URL format and language code validation
- **Error Handling**: Comprehensive error checking with set -euo pipefail
- **PHPDoc-Style Comments**: Well-documented helper functions

## 📋 Requirements

- **Bash**: 4.0 or higher
- **PHP CLI**: Available in PATH or at `/usr/local/bin/php`
- **wget**: For downloading packages
- **unzip**: For extracting Joomla packages
- **MySQL/MariaDB** or **PostgreSQL**: Database server
- **Server Permissions**: Write access to installation directory

## 🚀 Installation

### Quick Start

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

## 💻 Usage

### Basic Syntax

```bash
./joomla_installer.sh [-u <URL_ZIP>|-url <URL_ZIP>] [-s <URL_XML|URL_JSON>|-server <URL_XML|URL_JSON>] [-c <CHANNEL>|-channel <CHANNEL>] [-t <STABILITY>|-stability <STABILITY>] [-l <LANGUAGE>|-language <LANGUAGE>] [--patchtester]
```

### Parameters

- **`-u, -url <URL_ZIP>`**: Direct URL of the Joomla! ZIP package
  - Example: `https://github.com/joomla/joomla-cms/releases/download/5.1.0-alpha4/Joomla_5.1.0-alpha4-Alpha-Full_Package.zip`
  - Example: `https://developer.joomla.org/nightlies/Joomla_5.1.0-beta1-dev-Development-Full_Package.zip`

- **`-s, -server <URL_XML|URL_JSON>`**: URL of the update server (XML for Joomla 4.x/5.x, JSON for 6.x+)
  - **XML servers** (Joomla 4.x/5.x):
    - Example: `https://update.joomla.org/core/j4/default.xml` (Joomla 4.x stable)
    - Example: `https://update.joomla.org/core/j5/default.xml` (Joomla 5.x stable)
    - Example: `https://update.joomla.org/core/sts/extension_sts.xml` (Short Term Support)
    - Example: `https://update.joomla.org/core/test/extension_test.xml` (Testing)
    - Example: `https://update.joomla.org/core/nightlies/next_major_extension.xml` (Nightly builds)
    - Example: `https://update.joomla.org/core/nightlies/next_minor_extension.xml`
    - Example: `https://update.joomla.org/core/nightlies/next_patch_extension.xml`
  - **JSON servers** (Joomla 6.x+ with TUF format):
    - Example: `https://update.joomla.org/cms/targets.json` (Unified update server)

- **`-c, -channel <CHANNEL>`**: Channel filter (only for JSON servers)
  - Example: `5.x` (Joomla 5 series)
  - Example: `6.x` (Joomla 6 series)
  - **Note**: Ignored for XML servers

- **`-t, -stability <STABILITY>`**: Stability filter (only for JSON servers)
  - Example: `stable` (Stable releases)
  - Example: `rc` (Release Candidates)
  - Example: `alpha` (Alpha releases)
  - **Note**: Ignored for XML servers

- **`-l, -language <LANGUAGE>`**: Language code for installation (format: `xx-XX`)
  - Example: `it-IT` (Italian)
  - Example: `en-GB` (English)
  - Example: `fr-FR` (French)
  - Example: `de-DE` (German)
  - **Note**: Automatically selects correct language server based on Joomla version

- **`--patchtester`**: Install Joomla! Patch Tester extension
  - **Note**: Automatically selects compatible version based on installed Joomla version

### Examples

#### Install Joomla 5 from direct URL with Italian language
```bash
./joomla_installer.sh \
  -url "https://github.com/joomla/joomla-cms/releases/download/5.1.0-alpha4/Joomla_5.1.0-alpha4-Alpha-Full_Package.zip" \
  -language "it-IT" \
  --patchtester
```

#### Install latest Joomla 5.x stable
```bash
./joomla_installer.sh \
  -server "https://update.joomla.org/core/j5/default.xml" \
  -language "it-IT"
```

#### Install Joomla 6.x stable from JSON server
```bash
./joomla_installer.sh \
  -server "https://update.joomla.org/cms/targets.json" \
  -channel "6.x" \
  -stability "stable"
```

#### Install Joomla 6.x alpha (latest development)
```bash
./joomla_installer.sh \
  -server "https://update.joomla.org/cms/targets.json" \
  -channel "6.x" \
  -stability "alpha"
```

#### Install latest Joomla 4.x with Patch Tester
```bash
./joomla_installer.sh \
  -server "https://update.joomla.org/core/j4/default.xml" \
  --patchtester
```

#### Install latest Joomla from JSON server (any channel, any stability)
```bash
./joomla_installer.sh \
  -server "https://update.joomla.org/cms/targets.json"
```

#### Install latest nightly build (English only)
```bash
./joomla_installer.sh \
  -server "https://update.joomla.org/core/nightlies/next_major_extension.xml"
```

## ⚙️ Configuration File (`jconfig.sh`)

### Basic Configuration

```bash
# Installation Path
INSTALL_PATH="/home/user/public_html"

# Items to preserve during cleanup
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
```

### User Management Configuration

```bash
# Additional Users (optional)
# Format: "username|full name|email|password|usergroup1,usergroup2"
ADDITIONAL_USERS=(
    "editor|Editor User|editor@example.com|password123|Editor"
    "manager|Manager User|manager@example.com|password123|Manager"
    "multi|Multi Group User|multi@example.com|password123|Manager,Editor"
)
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

## 🔄 How It Works

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

### Server Type Detection

The script automatically detects the update server type:

**XML Servers (Joomla 4.x/5.x)**:
- Traditional XML manifest format
- Selects the latest available version
- Channel and stability parameters are ignored

**JSON/TUF Servers (Joomla 6.x+)**:
- Modern JSON format with TUF (The Update Framework) security
- Supports filtering by channel (`5.x`, `6.x`) and stability (`stable`, `rc`, `alpha`)
- Tests 4 URL patterns for package availability
- Intelligent sorting: channel → stability → version

### URL Pattern Testing (JSON only)

1. **Full_Package variant**: Converts `Update_Package.zip` to `Full_Package.zip`
2. **update.joomla.org format**: Extracts version from downloads.joomla.org URLs
3. **GitHub releases**: Converts GitHub Update packages to Full packages
4. **Alternative formats**: Tests dash-separated version formats

### Version Detection
- Extracts version from filename (e.g., `Joomla_4.4.14-Stable` → `4.4.14`)
- Automatically determines major version for language server selection
- For Joomla < 5.0.0: Skips `--public-folder` parameter (not supported)
- For Joomla ≥ 5.0.0: Adds `--public-folder` parameter

### Extension Compatibility
The script intelligently checks extension compatibility using `targetplatform` information from manifest XML files. For example, Patch Tester with pattern `[45].[01234]` is compatible with:
- Joomla 4.0, 4.1, 4.2, 4.3, 4.4
- Joomla 5.0, 5.1, 5.2, 5.3, 5.4

## 📊 Output Messages

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

## 🛠️ Troubleshooting

### Permission denied error
```bash
chmod +x joomla_installer.sh
```

### Bad interpreter error
Line endings issue (CRLF instead of LF):
```bash
dos2unix joomla_installer.sh
# or
sed -i 's/\r$//' joomla_installer.sh
```

### PHP is not installed or not in PATH
```bash
# Check if PHP exists
which php
# If not in PATH but exists elsewhere:
ln -s /path/to/php /usr/local/bin/php
```

### JSON server returns no packages
- Verify channel format (e.g., `5.x`, `6.x`)
- Check stability value (`stable`, `rc`, `alpha`)
- Try without filters to see all available packages
- Ensure internet connection can reach `update.joomla.org`

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

## 🏗️ Technical Details

### Function Architecture

**Core Functions**:
- `get_joomla_package_url()` - Auto-detects server type and routes to appropriate parser
- `get_package_from_xml()` - Handles XML servers (Joomla 4.x/5.x)
- `get_package_from_json()` - Handles JSON/TUF servers (Joomla 6.x+) with filtering
- `get_extension_package_url()` - Handles extension updates with compatibility checking

**Utility Functions**:
- `get_joomla_version()` - Extracts semantic version from filename
- `get_joomla_major_version()` - Extracts major version for language server selection
- `get_random_prefix()` - Generates secure database table prefix
- `print_title()` - Formatted section titles
- `print_result()` - Joomla-style colored result boxes

All functions include PHPDoc-style comments with parameter and return type documentation.

### Security Features

- **Selective Cleanup**: Preserves specified directories, files, and database tables
- **Random Table Prefix**: 5-character prefix starting with a letter (e.g., `a3x9z_`)
- **Input Validation**: URL format and language code validation
- **Error Handling**: Comprehensive error checking with `set -euo pipefail`
- **Exit Codes**: `0` for success, `1` for errors

## 🔥 Advanced Features

### Selective Cleanup
Configure in `jconfig.sh`:
- **`DIR_TO_KEEP`**: Directories to preserve (e.g., `.well-known` for SSL)
- **`FILE_TO_KEEP`**: Files to preserve (e.g., `.htaccess` for rewrite rules)
- **`TABLE_TO_KEEP`**: Database tables to preserve (e.g., backup tables)

### Automatic Server Type Detection
The script automatically detects whether the update server is XML or JSON based on the URL extension:
- `.xml` → Uses XML parser for Joomla 4.x/5.x
- `.json` → Uses JSON/TUF parser for Joomla 6.x+
- No manual configuration required

### Multi-Pattern URL Testing (JSON only)
For JSON servers, the script tests multiple URL patterns to find working download links:
1. **Full_Package variant**: Converts `Update_Package.zip` to `Full_Package.zip`
2. **update.joomla.org format**: Extracts version from downloads.joomla.org URLs
3. **GitHub releases**: Converts GitHub Update packages to Full packages
4. **Alternative formats**: Tests dash-separated version formats

This ensures maximum compatibility even when URLs change or redirect.

### Additional Users Creation
Automatically creates users after installation with:
- Custom usernames and full names
- Email addresses
- Passwords
- Multiple usergroups support (comma-separated)
- Skips empty or commented lines in configuration

### Final Result Display
The installation result shows the actual Joomla package name (e.g., "Joomla_5.4.1-Stable" or "Joomla_6.0.0-alpha1") instead of generic "Joomla", providing clear confirmation of which version was installed.

All functions include PHPDoc-style comments with parameter and return type documentation.

### Security Features

- **Selective Cleanup**: Preserves specified directories, files, and database tables
- **Random Table Prefix**: 5-character prefix starting with a letter (e.g., `a3x9z_`)
- **Input Validation**: URL format and language code validation
- **Error Handling**: Comprehensive error checking with `set -euo pipefail`
- **Exit Codes**: `0` for success, `1` for errors

## 📝 TO DO
- [ ] Support for additional extensions
- [ ] Bulk extension installation from configuration

## 🎬 Demo
https://github.com/JoomlaLABS/Joomla_Installer/assets/906604/0343d9b6-c12b-49dd-986f-fb0446a63611

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### 🔄 How to Contribute

1. **🍴 Fork** the repository
2. **🌿 Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **✨ Make** your changes following our coding standards
4. **🧪 Add** tests if applicable
5. **💾 Commit** your changes (`git commit -m 'Add some amazing feature'`)
6. **🚀 Push** to the branch (`git push origin feature/amazing-feature`)
7. **📮 Submit** a pull request

### 📋 Guidelines

- Follow Bash best practices and ShellCheck recommendations
- Write clear, concise commit messages
- Test your changes on multiple Joomla versions (4.x, 5.x, 6.x)
- Update documentation as needed
- Add PHPDoc-style comments for new functions
- Maintain backward compatibility where possible

## 📄 License

This project is licensed under the **GNU General Public License v2.0** - see the [LICENSE](LICENSE) file for details.

```
GNU GENERAL PUBLIC LICENSE
Version 2, June 1991

Copyright (C) 2023-2025 Joomla!LABS

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
```

## 👥 Project Information

### 🏢 Project Owner

**Joomla!LABS** - [https://joomlalabs.com](https://joomlalabs.com)

[![Email](https://img.shields.io/badge/Email-info%40joomlalabs.com-red?style=for-the-badge&logo=gmail&logoColor=white)](mailto:info@joomlalabs.com)

*Joomla!LABS is the company that owns and maintains this project.*

### 👨‍💻 Contributors

**Luca Racchetti** - Lead Developer

[![Email](https://img.shields.io/badge/Email-Razzo1987%40gmail.com-red?style=for-the-badge&logo=gmail&logoColor=white)](mailto:Razzo1987@gmail.com)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Luca%20Racchetti-blue?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/razzo/)
[![GitHub](https://img.shields.io/badge/GitHub-Razzo1987-black?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Razzo1987)

*Full-Stack Developer passionate about creating modern, efficient web applications and tools for the Joomla! community*

## 🆘 Support

### 💬 Get Help

Need help? We're here for you!

- 🐛 Found a bug? [Open an issue](https://github.com/JoomlaLABS/Joomla_Installer/issues/new?labels=bug&template=bug_report.md)
- 💡 Have a feature request? [Open an issue](https://github.com/JoomlaLABS/Joomla_Installer/issues/new?labels=enhancement&template=feature_request.md)
- ❓ Questions? [Start a discussion](https://github.com/JoomlaLABS/Joomla_Installer/discussions)
- 📧 Direct contact: [Razzo1987@gmail.com](mailto:Razzo1987@gmail.com)

## 💝 Donate

If you find this project useful, consider supporting its development:

[![Sponsor on GitHub](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa?style=for-the-badge&logo=github)](https://github.com/sponsors/JoomlaLABS)
[![Buy me a beer](https://img.shields.io/badge/🍺%20Buy%20me%20a-beer-FFDD00?style=for-the-badge&labelColor=FFDD00&color=FFDD00)](https://buymeacoffee.com/razzo)

Your support helps maintain and improve this project!

---

**Made with ❤️ for the Joomla! Community**

**⭐ If this project helped you, please consider giving it a star! ⭐**