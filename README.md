# Joomla_Installer
bash script to automatically install Joomla!

Usage:
```
./joomla_installer.sh [-u <URL_ZIP>|-url <URL_ZIP>] [-s <URL_XML>|-server <URL_XML>] [-l <LANGUAGE>|-language <LANGUAGE>] [--patchtester]
  -u, -url <URL_ZIP>:       Specify the direct URL of the Joomla! ZIP package to download.
                              e.g. https://github.com/joomla/joomla-cms/releases/download/5.1.0-alpha4/Joomla_5.1.0-alpha4-Alpha-Full_Package.zip
                              e.g. https://developer.joomla.org/nightlies/Joomla_5.1.0-beta1-dev-Development-Full_Package.zip
  -s, -server <URL_XML>:    Specify the URL of the XML Server from which to extract the download package.
                              e.g. https://update.joomla.org/core/sts/extension_sts.xml
                              e.g. https://update.joomla.org/core/j4/default.xml
                              e.g. https://update.joomla.org/core/j5/default.xml
                              e.g. https://update.joomla.org/core/test/extension_test.xml
                              e.g. https://update.joomla.org/core/nightlies/next_major_extension.xml
                              e.g. https://update.joomla.org/core/nightlies/next_minor_extension.xml
                              e.g. https://update.joomla.org/core/nightlies/next_patch_extension.xml
  -l, -language <LANGUAGE>: Specify the language for Joomla! installation.
                              e.g. it-IT
  --patchtester:            Install Joomla! Patch Tester extension.
```

E.g.

`./joomla_installer.sh -url "https://github.com/joomla/joomla-cms/releases/download/5.1.0-alpha4/Joomla_5.1.0-alpha4-Alpha-Full_Package.zip" -language "it-IT" --patchtester`

`./joomla_installer.sh -server "https://update.joomla.org/core/j5/default.xml" -language "it-IT" --patchtester`
