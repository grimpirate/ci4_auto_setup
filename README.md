# CodeIgniter 4 PowerShell Setup Script
## Requirements
* Windows OS
* XAMPP (Apache, MySQL, PHP)
* php added to PATH
* PS > Set-ExecutionPolicy RemoteSigned
## Required PHP Extensions - php.ini
* extension=bz2
* extension=curl
* extension=fileinfo
* extension=gettext
* extension=intl
* extension=mbstring
* extension=exif      ; Must be after mbstring as it depends on it
* extension=mysqli
* extension=pdo_mysql
## Usage
Copy ci4_setup.ps1 to the *htdocs/* directory  
Run the script to configure as described in [Managing your Applications](https://codeigniter.com/user_guide/general/managing_apps.html)
```
PS > & .\ci4_setup.ps1
```
Resultant directory structure:
```
/main
  /sub
    /app
    /public
    .env
  /vendor
  /writable
  composer.json
  composer.lock
```
