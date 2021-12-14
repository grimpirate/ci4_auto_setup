# CodeIgniter 4 PowerShell Setup Script
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
## Requirements
* Windows
* XAMPP
* PS > Set-ExecutionPolicy RemoteSigned
