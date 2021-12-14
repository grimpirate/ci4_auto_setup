<#
	CodeIgniter 4 Setup Script
#>

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

$url = "http://localhost/$main/$sub/public"
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
php composer-setup.php
Remove-Item .\composer-setup.php
php composer.phar require codeigniter4/framework

New-Item -Path . -Name $sub -ItemType 'directory'

Copy-Item -Path .\vendor\codeigniter4\framework\app -Destination .\$sub -Recurse
Copy-Item -Path .\vendor\codeigniter4\framework\public -Destination .\$sub -Recurse
Copy-Item -Path .\vendor\codeigniter4\framework\env -Destination .\$sub\.env

Copy-Item -Path .\vendor\codeigniter4\framework\writable\ -Destination . -Recurse
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

php -r "unlink('composer.phar');"

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
			<!--<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 382.60492 424.8894"><path d="M 265.35921,196.5803 H 267.71471 C 286.41371,196.5803 302.12871,182.1233 303.22671,163.1113 304.48451,143.4703 289.55471,126.3413 269.91471,125.0843 269.12955,125.0843 268.34441,124.92805 267.55921,124.92805 248.86021,124.92805 233.14521,139.38505 232.04721,158.39705 230.78941,178.35405 245.71921,195.32305 265.35921,196.58105 Z M 128.80921,209.7803 H 131.16471 C 149.86371,209.7803 165.57871,195.3233 166.67671,176.3113 167.93451,156.6703 153.00471,139.5413 133.36471,138.2843 132.57955,138.2843 131.79441,138.12805 131.00921,138.12805 112.31021,138.12805 96.595213,152.58505 95.497213,171.59705 94.243313,191.39805 109.16921,208.52305 128.80921,209.78105 Z M 192.13921,249.2203 H 192.61187 L 223.25287,247.8062 C 230.47947,247.4937 235.19387,240.107 232.68257,233.3492 L 217.28457,192.4942 C 215.55797,187.7794 211.47207,185.5801 207.22957,185.5801 202.98737,185.5801 198.90147,187.9356 197.17457,192.6504 L 181.93257,235.0764 C 179.56537,241.9944 184.75287,249.2214 192.13957,249.2214 Z M 377.55921,318.6703 C 382.74281,309.557 384.00061,299.0293 381.01621,288.9713 376.45761,272.4713 361.84421,261.0023 344.55921,260.5303 H 343.45761 C 339.84431,260.5303 336.38731,261.00296 332.93061,261.9444 L 271.33661,278.9174 C 272.90691,275.933 274.32101,273.2612 275.42251,270.7455 280.13731,261.0033 281.07871,260.0615 282.96551,259.5895 321.30551,248.7455 344.56351,204.5935 346.91851,168.4525 352.73101,81.3975 286.57851,5.9725 199.67851,0.3125 196.22151,0.15625 192.76441,0 189.15151,0 148.76851,0 107.44051,15.086 75.861513,41.484 41.447513,70.238 22.279513,108.422 21.806513,149.124 21.333853,196.894 40.033513,225.804 55.747513,241.519 73.661513,259.589 97.544513,270.746 121.58751,272.316 H 121.74376 C 123.15786,273.4176 125.82966,277.4996 127.87266,280.6441 L 50.720663,257.3901 C 47.419863,256.44869 43.962863,255.8198 40.505663,255.6635 H 39.247863 C 22.118863,255.6635 6.7208628,267.1365 1.6928628,283.4755 -1.2915372,293.5305 -0.35013715,304.0615 4.6772628,313.3305 9.7045628,322.6 17.876263,329.3575 27.931263,332.3425 L 53.388263,340.0417 33.275263,345.6979 C 12.533263,351.5104 0.43526285,373.1979 6.2482628,393.9359 10.963063,410.5919 25.576263,422.0649 42.705263,422.5339 H 43.806863 C 47.263863,422.5339 50.877163,422.06124 54.177863,421.1198 L 193.39786,382.3078 328.84786,423.1628 C 332.14866,424.10421 335.60566,424.7331 339.06286,424.8894 H 340.47696 C 357.76196,424.73315 372.68796,413.5774 377.71896,397.0774 380.70336,387.0224 379.76196,376.4914 374.73456,367.2224 369.86346,357.9529 361.53556,351.1954 351.48056,348.2104 L 333.56656,342.8666 353.52356,337.3666 C 364.04356,334.3861 372.37156,327.7846 377.55856,318.6716 Z M 123.15921,247.1743 C 93.147213,245.1313 46.479213,219.5183 47.104213,149.4363 47.733123,79.0413 118.91321,25.2963 189.31421,25.2963 192.29861,25.2963 195.28691,25.45255 198.11501,25.6088 271.18101,30.3236 326.65501,93.6478 321.77501,166.8688 320.20471,192.9588 303.07601,227.6848 276.20901,235.3848 246.03701,243.8692 259.39301,284.0958 213.19701,292.8968 206.12671,294.3109 199.84201,294.7835 194.34201,294.7835 146.41601,294.7835 153.95901,249.0565 123.15801,247.1705 Z M 47.737213,396.7643 C 46.479413,397.0768 45.221613,397.23696 43.967713,397.23696 H 43.655213 C 37.526313,397.08071 32.343213,392.99476 30.768213,387.18196 28.725213,379.79526 32.967413,372.09596 40.354113,370.05296 L 98.651113,353.70896 148.30711,368.63896 Z M 344.55721,372.2523 C 348.17051,373.3539 351.15881,375.7093 352.88531,379.0101 354.61191,382.3109 354.92831,386.0804 353.98691,389.6941 352.26031,395.5066 346.91661,399.5925 340.78791,399.5925 H 340.31525 C 339.05745,399.5925 337.79965,399.28 336.70195,398.96359 L 35.321953,308.14359 C 31.708653,307.04199 28.720353,304.68659 26.993853,301.38579 23.536853,294.94439 25.736053,286.77279 32.021153,283.00279 35.478153,280.95979 39.720353,280.33089 43.494153,281.43249 Z M 288.61921,329.0413 238.96321,314.1113 339.68321,286.1423 C 339.99571,285.98605 340.31212,285.98605 340.62462,285.98605 340.93712,285.98605 341.25353,285.8298 341.56603,285.8298 342.19494,285.8298 342.82383,285.67355 343.45273,285.67355 H 343.92539 C 350.05429,285.8298 355.23739,289.91575 356.81239,295.88855 357.7538,299.50185 357.4413,303.11515 355.55459,306.41555 353.66788,309.71595 350.83979,311.91555 347.22649,313.01715 Z"></svg>-->
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
Format-Block "CodeIgniter URL:" $length
Format-Block "   $url" $length
Format-Block " " $length
Format-Block "CodeIgniter Log(s):" $length
Format-Block "   $log" $length
Format-Block " " $length
Format-Block "" $length