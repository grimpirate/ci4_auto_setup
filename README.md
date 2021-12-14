# CodeIgniter 4 PowerShell Setup Script
## Requirements
* Windows
* XAMPP
* PHP added to PATH
* PS > Set-ExecutionPolicy RemoteSigned
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
