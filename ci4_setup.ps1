<#
	CodeIgniter 4 Setup Script

	https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/
#>

$php = Read-Host 'PHP executable {C:\xampp\php\php.exe}'
if([string]::IsNullOrWhiteSpace($php))
{
	$php = 'C:\xampp\php\php.exe'
}

if((Read-Host "Configure php.ini? [y/n]") -match "[yY]")
{
	$ini = "$(Split-Path -Path $php)\php.ini"
	((Get-Content -Path $ini -Raw) -replace ';extension=bz2', 'extension=bz2') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=curl', 'extension=curl') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=fileinfo', 'extension=fileinfo') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=gettext', 'extension=gettext') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=intl', 'extension=intl') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=json', 'extension=json') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=mbstring', 'extension=mbstring') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=exif', 'extension=exif') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=mysqli', 'extension=mysqli') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=pdo_mysql', 'extension=pdo_mysql') | Set-Content -Path $ini
	((Get-Content -Path $ini -Raw) -replace ';extension=pdo_sqlite', 'extension=pdo_sqlite') | Set-Content -Path $ini
	Write-Host "Extension(s): bz2, curl, fileinfo, gettext, intl, mbstring, exif, mysqli, pdo_mysql, pdo_sqlite" -ForegroundColor yellow
}

$main = Read-Host "Root directory name {main}"
if([string]::IsNullOrWhiteSpace($main))
{
	$main = 'main'
}
$sub = Read-Host "Application subdirectory name {sub}"
if([string]::IsNullOrWhiteSpace($sub))
{
	$sub = 'sub'
}

$url = "http://localhost/$main/$sub/public"
$vu = ''
$vi = ''
if((Read-Host "Configure Apache Virtual Host? [y/n]") -match "[yY]")
{
	$vf = Read-Host 'httpd-vhosts.conf file {C:\xampp\apache\conf\extra\httpd-vhosts.conf}'
	if([string]::IsNullOrWhiteSpace($vf))
	{
		$vf = 'C:\xampp\apache\conf\extra\httpd-vhosts.conf'
	}
	$vu = Read-Host 'Virtual Host ServerName {ignitercode.com}'
	if([string]::IsNullOrWhiteSpace($vu))
	{
		$vu = 'ignitercode.com'
	}
	$vi = Read-Host 'Virtual Host IP {127.0.0.255}'
	if([string]::IsNullOrWhiteSpace($vi))
	{
		$vi = '127.0.0.255'
	}
	Add-Content -Path $vf -Value @"


## CodeIgniter 4 PowerShell Setup Script
<VirtualHost $vi>
    DocumentRoot `"$(Get-Location)\$main\$sub\public`"
    ServerName $vu
</VirtualHost>

"@ -PassThru
}

$threshold
try
{
	$threshold = [Int32]::Parse((Read-Host "CodeIgniter logging threshold 0 - 9 {9}"))
	if(($threshold -lt 0) -or ($threshold -gt 9))
	{
		$threshold = 9
	}
}
catch
{
	$threshold = 9
}
$timezone = Read-Host "CodeIgniter app timezone {America/New_York}"
if([string]::IsNullOrWhiteSpace($timezone))
{
	$timezone = 'America/New_York'
}

$log = "$(Get-Location)\$main\writable\logs"

New-Item -Path . -Name $main -ItemType 'directory'
Push-Location -Path $main -PassThru

Invoke-WebRequest -Uri 'https://getcomposer.org/installer' -OutFile .\composer-setup.php
if((Get-FileHash .\composer-setup.php -Algorithm SHA384).Hash -eq '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8')
{
	Write-Host 'Installer verified'
}
else
{
	Write-Host 'Installer corrupt'
	Remove-Item .\composer-setup.php
}
& $php composer-setup.php
Remove-Item .\composer-setup.php
& $php composer.phar require codeigniter4/framework --no-dev

New-Item -Path . -Name $sub -ItemType 'directory'

Copy-Item -Path .\vendor\codeigniter4\framework\app -Destination .\$sub -Recurse
Copy-Item -Path .\vendor\codeigniter4\framework\public -Destination .\$sub -Recurse
Copy-Item -Path .\vendor\codeigniter4\framework\writable -Destination . -Recurse

Copy-Item -Path .\vendor\codeigniter4\framework\env -Destination .\$sub\.env
Copy-Item -Path .\vendor\codeigniter4\framework\phpunit.xml.dist -Destination .
Copy-Item -Path .\vendor\codeigniter4\framework\spark -Destination .

((Get-Content -Path .\$sub\app\Config\Paths.php -Raw) -replace '/../../system', '/../../../vendor/codeigniter4/framework/system') | Set-Content -Path .\$sub\app\Config\Paths.php
((Get-Content -Path .\$sub\app\Config\Paths.php -Raw) -replace '/../../writable', '/../../../writable') | Set-Content -Path .\$sub\app\Config\Paths.php
((Get-Content -Path .\$sub\app\Config\Paths.php -Raw) -replace '/../../tests', '/../../../tests') | Set-Content -Path .\$sub\app\Config\Paths.php

# Composer setup and additional packages install
((Get-Content -Path .\$sub\app\Config\Constants.php -Raw) -replace 'vendor/autoload.php', '../vendor/autoload.php') | Set-Content -Path .\$sub\app\Config\Constants.php

$package = Read-Host "Composer package to install [library/package]"
while(-not ([string]::IsNullOrWhiteSpace($package)))
{
	php composer.phar require $package
	$package = Read-Host "Composer package to install [library/package]"
}
#php composer.phar require guzzlehttp/guzzle
#php composer.phar require caseyamcl/guzzle_retry_middleware
#php composer.phar require tecnickcom/tcpdf
#php composer.phar require sendgrid/sendgrid

Remove-Item .\composer.phar

((Get-Content -Path .\$sub\.env -Raw) -replace '# CI_ENVIRONMENT = production', 'CI_ENVIRONMENT = development') | Set-Content -Path .\$sub\.env
((Get-Content -Path .\$sub\.env -Raw) -replace "# app.baseURL = ''", "app.baseURL = '$url'") | Set-Content -Path .\$sub\.env

((Get-Content -Path .\$sub\app\Config\Logger.php -Raw) -replace 'threshold = 4;', "threshold = $threshold;") | Set-Content -Path .\$sub\app\Config\Logger.php

((Get-Content -Path .\$sub\app\Config\App.php -Raw) -replace 'America/Chicago', $timezone) | Set-Content -Path .\$sub\app\Config\App.php

<#
((Get-Content -Path .\$sub\app\Config\Routes.php -Raw) -replace 'routes->get', @"
routes->resource('api');
`$routes->get
"@) | Set-Content -Path .\$sub\app\Config\Routes.php

Out-File -FilePath .\$sub\app\Controllers\Api.php -Encoding ASCII -InputObject @"
<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class Api extends ResourceController
{
	protected `$format = "json";

	public function index()
	{
		return `$this->failTooManyRequests();
		//return `$this->failUnauthorized();
		//return `$this->failForbidden();
		//return `$this->failNotFound();
		//return `$this->failValidationError();
		//return `$this->failResourceExists();
		//return `$this->failResourceGone();
	}
}
"@

Out-File -FilePath .\$sub\app\Controllers\Home.php -Encoding ASCII -InputObject @"
<?php

namespace App\Controllers;

use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;
use GuzzleHttp\HandlerStack;
use GuzzleRetry\GuzzleRetryMiddleware;
use GuzzleHttp\Client;

class Home extends BaseController
{
	public function index()
	{
		try
		{
			`$stack = HandlerStack::create();
			`$stack->push(GuzzleRetryMiddleware::factory([
				'retry_on_status' => [400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,421,422,423,424,425,426,428,429,431,451,500,501,502,503,504,505,506,507,508,510,511],
				'max_retry_attempts' => 3,
				'on_retry_callback' => function(int `$attemptNumber, float `$delay, RequestInterface &`$request, array &`$options, ?ResponseInterface `$response) {
					
					log_message('info', sprintf(
						"Retrying request to %s.  Server responded with %s.  Will wait %s seconds.  This is attempt #%s",
						`$request->getUri()->getPath(),
						`$response->getStatusCode(),
						number_format(`$delay, 2),
						`$attemptNumber
					));
				}
			]));
			(new Client(['handler' => `$stack]))->get('$url/api');
		}
		catch(\Exception `$e)
		{
			log_message('error', '{exception}', ['exception' => `$e]);
		}
		return view('welcome_message');
	}
}
"@
#>

((Get-Content -Path .\$sub\app\Views\welcome_message.php -Raw) -replace '<h1>Go further</h1>', @"
<h1>Go further</h1>

		<h2>
			<svg aria-hidden="true" focusable="false" data-prefix="fas" data-icon="terminal" class="svg-inline--fa fa-terminal" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512"><path fill="currentColor" d="M256 256c0-8.188-3.125-16.38-9.375-22.62l-192-192C48.38 35.13 40.19 32 32 32C14.95 32 0 45.73 0 64c0 8.188 3.125 16.38 9.375 22.62L178.8 256l-169.4 169.4C3.125 431.6 0 439.8 0 448c0 18.28 14.95 32 32 32c8.188 0 16.38-3.125 22.62-9.375l192-192C252.9 272.4 256 264.2 256 256zM544 416H256c-17.67 0-32 14.31-32 32s14.33 32 32 32h288c17.67 0 32-14.31 32-32S561.7 416 544 416z"></path></svg>
			PowerShell Setup Script
		</h2>

		<p>Provided by <a href="https://github.com/grimpirate/" target="_blank">GrimPirate</a></p>
"@) | Set-Content -Path .\$sub\app\Views\welcome_message.php

if((Read-Host "Configure a database? [y/n]") -match "[yY]")
{
	$h = Read-Host "Host name {localhost}"
	if([string]::IsNullOrWhiteSpace($h))
	{
		$h = 'localhost'
	}
	$u = Read-Host "Root username {root}"
	if([string]::IsNullOrWhiteSpace($u))
	{
		$u = 'root'
	}
	$p = Read-Host "Root password"
	$d = Read-Host "Database {ci4}"
	if([string]::IsNullOrWhiteSpace($d))
	{
		$d = 'ci4'
	}
	$t = Read-Host "Session table name {ci_sessions}"
	if([string]::IsNullOrWhiteSpace($t))
	{
		$t = 'ci_sessions'
	}
	$c = Read-Host "Session cookie name {ci_session}"
	if([string]::IsNullOrWhiteSpace($c))
	{
		$c = 'ci_session'
	}

	((Get-Content -Path .\$sub\.env -Raw) -replace 'FileHandler', 'DatabaseHandler') | Set-Content -Path .\$sub\.env
	((Get-Content -Path .\$sub\.env -Raw) -replace '# app.sessionDriver', 'app.sessionDriver') | Set-Content -Path .\$sub\.env
	((Get-Content -Path .\$sub\.env -Raw) -replace "# app.sessionCookieName = 'ci_session'", "app.sessionCookieName = $c") | Set-Content -Path .\$sub\.env
	((Get-Content -Path .\$sub\.env -Raw) -replace '# app.sessionExpiration', 'app.sessionExpiration') | Set-Content -Path .\$sub\.env
	((Get-Content -Path .\$sub\.env -Raw) -replace '# app.sessionSavePath = null', "app.sessionSavePath = $t") | Set-Content -Path .\$sub\.env
	((Get-Content -Path .\$sub\.env -Raw) -replace '# app.sessionMatchIP = false', 'app.sessionMatchIP = true') | Set-Content -Path .\$sub\.env
	((Get-Content -Path .\$sub\.env -Raw) -replace '# app.sessionTimeToUpdate', 'app.sessionTimeToUpdate') | Set-Content -Path .\$sub\.env
	((Get-Content -Path .\$sub\.env -Raw) -replace '# app.sessionRegenerateDestroy = false', 'app.sessionRegenerateDestroy = true') | Set-Content -Path .\$sub\.env

	((Get-Content -Path .\$sub\.env -Raw) -replace '# database.default.hostname = localhost', @"
database.default.hostname = $h
database.default.database = $d
database.default.username = $u
database.default.password = '$p'
database.default.DBDriver = MySQLi
database.default.pConnect = false
database.default.DBDebug = true
database.default.charset = utf8
database.default.DBCollat = utf8mb4_unicode_ci

# database.default.hostname = localhost
"@) | Set-Content -Path .\$sub\.env
	
 	php -r @"
	`$pdo = new PDO('mysql:host=$h', '$u', '$p');
	`$pdo->exec('CREATE DATABASE $d CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;');
	`$pdo = new PDO('mysql:host=$h;dbname=$d;charset=utf8mb4', '$u', '$p');
	`$pdo->exec('CREATE TABLE IF NOT EXISTS ``$t`` (``id`` varchar(128) NOT null, ``ip_address`` varchar(45) NOT null, ``timestamp`` timestamp DEFAULT CURRENT_TIMESTAMP NOT null, ``data`` blob NOT null, KEY ``ci_sessions_timestamp`` (``timestamp``));');
	`$pdo->exec('ALTER TABLE $t ADD PRIMARY KEY (id, ip_address);');
"@
}

Pop-Location -PassThru

function Format-Block
{
	param(
		$message,
		$length
	)

	Write-Host "*" -NoNewLine -ForegroundColor yellow
	if($message.Length -gt 0)
	{
		Write-Host "   " -NoNewLine -ForegroundColor yellow
		Write-Host "$message" -NoNewLine -ForegroundColor yellow
		for($i = 5; $i -lt $length - $message.Length; $i++)
		{
			Write-Host " " -NoNewLine -ForegroundColor yellow
		}
	}
	else
	{
		for($i = 0; $i -lt $length - 2; $i++)
		{
			Write-Host "*" -NoNewLine -ForegroundColor yellow
		}
	}
	Write-Host "*" -NoNewLine -ForegroundColor yellow
	Write-Host ""
}

$length = if($url.Length -gt $log.Length) {$url.Length} else {$log.Length}
$length += 11

Format-Block "" $length
Format-Block " " $length
Format-Block "CodeIgniter URL(s):" $length
if(-not ([string]::IsNullOrWhiteSpace($vu)))
{
	Format-Block "   http://$vu/" $length	
}
Format-Block "   $url/" $length
Format-Block " " $length
Format-Block "CodeIgniter Log(s):" $length
Format-Block "   $log" $length
if(-not ([string]::IsNullOrWhiteSpace($vu)))
{
	Format-Block " " $length
	Format-Block "Windows Host(s) File:" $length
	Format-Block "   C:\Windows\System32\drivers\etc\hosts" $length
	Format-Block "   $vi $vu" $length
}
Format-Block " " $length
Format-Block "" $length
