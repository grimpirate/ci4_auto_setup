# CodeIgniter 4 PowerShell Setup Script
Copy ci4_setup.ps1 to the *htdocs/* directory  
Run the script to configure as described in [Managing your Applications](https://codeigniter.com/user_guide/general/managing_apps.html)
```
PS > & .\ci_setup.ps1
```
Resultant directory structure:
```
/root
  /app
    /app
    /public
    .env
  /vendor
  /writable
  composer.json
  composer.lock
```
