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

mkdir $main
cd $main

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
php composer.phar require codeigniter4/framework

mkdir $sub

cp -R .\vendor\codeigniter4\framework\app .\$sub\
cp -R .\vendor\codeigniter4\framework\public\ .\$sub\
cp .\vendor\codeigniter4\framework\env .\$sub\.env

cp -R .\vendor\codeigniter4\framework\writable\ .
#cp .\vendor\codeigniter4\framework\phpunit.xml.dist .
#cp .\vendor\codeigniter4\framework\spark .

((Get-Content -Path .\$sub\app\Config\Paths.php -Raw) -replace '/../../system', '/../../../vendor/codeigniter4/framework/system') | Set-Content -Path .\$sub\app\Config\Paths.php
((Get-Content -Path .\$sub\app\Config\Paths.php -Raw) -replace '/../../writable', '/../../../writable') | Set-Content -Path .\$sub\app\Config\Paths.php
((Get-Content -Path .\$sub\app\Config\Paths.php -Raw) -replace '/../../tests', '/../../../tests') | Set-Content -Path .\$sub\app\Config\Paths.php

# Composer setup and additional packages install
((Get-Content -Path .\$sub\app\Config\Constants.php -Raw) -replace 'vendor/autoload.php', '../vendor/autoload.php') | Set-Content -Path .\$sub\app\Config\Constants.php

$package = Read-Host "Composer package to install [library/package]"
while(-not ([string]::IsNullOrWhiteSpace($package)))
{
	php composer.phar require $package
	$package = Read-Host "Composer package to install {library/package}"
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

###############################
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
###############################

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

cd ..