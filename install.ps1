#requires -Version 5.1
<#
.SYNOPSIS
    Install wp-standards-agent into a WordPress plugin or theme project.
.DESCRIPTION
    Copies the enforcement configs (phpcs.xml, pint.json, phpstan.neon,
    .prettierrc, .husky/pre-commit), creates composer.json / package.json when
    absent, and appends the portable AGENTS.md guardrail block.
.PARAMETER Target
    Project directory. Defaults to the current directory.
.PARAMETER Slug
    Project slug (composer/package name). Prompts when omitted.
.PARAMETER TextDomain
    Text domain for the phpcs I18n sniff. Defaults to Slug.
.EXAMPLE
    .\install.ps1 -Target .\my-plugin
.EXAMPLE
    .\install.ps1 -Target .\my-plugin -Slug my-plugin -TextDomain my-plugin
#>
param(
    [string]$Target = ".",
    [string]$Slug = "",
    [string]$TextDomain = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configs = Join-Path $repoRoot "configs"

$target = [IO.Path]::GetFullPath($Target)
if ( -not ( Test-Path -LiteralPath $target ) ) {
    throw "Target directory does not exist: $target"
}

$defaultSlug = Split-Path -Leaf $target
if ( [string]::IsNullOrWhiteSpace( $Slug ) ) {
    $Slug = Read-Host "Project slug [$defaultSlug]"
}
if ( [string]::IsNullOrWhiteSpace( $Slug ) ) {
    $Slug = $defaultSlug
}

if ( [string]::IsNullOrWhiteSpace( $TextDomain ) ) {
    $TextDomain = Read-Host "Text domain [$Slug]"
}
if ( [string]::IsNullOrWhiteSpace( $TextDomain ) ) {
    $TextDomain = $Slug
}

function Write-FileUtf8( [string]$path, [string]$content ) {
    [IO.File]::WriteAllText( $path, $content, ( New-Object Text.UTF8Encoding( $false ) ) )
}

function Install-File( [string]$name, [switch]$subdir ) {
    $src = Join-Path $configs $name
    $dst = Join-Path $target $name
    $content = [IO.File]::ReadAllText( $src )
    $content = $content.Replace( '{{SLUG}}', $slug ).Replace( '{{TEXT_DOMAIN}}', $textDomain )

    if ( Test-Path -LiteralPath $dst ) {
        Copy-Item -LiteralPath $dst -Destination ( "$dst.bak" ) -Force
        Write-Host "  backed up existing $name -> $name.bak"
    }
    if ( $subdir ) {
        New-Item -ItemType Directory -Path ( Split-Path $dst ) -Force | Out-Null
    }
    Write-FileUtf8 $dst $content
    Write-Host "  installed $name"
}

Write-Host ""
Write-Host "Installing wp-standards-agent into $target"
Write-Host ""

Install-File "phpcs.xml"
Install-File "pint.json"
Install-File "phpstan.neon"
Install-File ".prettierrc"
Install-File ".prettierignore"
Install-File ".husky/pre-commit" -subdir

if ( -not ( Test-Path -LiteralPath ( Join-Path $target ".gitignore" ) ) ) {
    Install-File ".gitignore"
} else {
    Write-Host "  kept existing .gitignore"
}

$madeComposer = $false
if ( Test-Path -LiteralPath ( Join-Path $target "composer.json" ) ) {
    Write-Host "  kept existing composer.json (merge dev deps manually)"
} else {
    Install-File "composer.json"
    $madeComposer = $true
}

$madePackage = $false
if ( Test-Path -LiteralPath ( Join-Path $target "package.json" ) ) {
    Write-Host "  kept existing package.json (add scripts + devDeps manually)"
} else {
    Install-File "package.json"
    $madePackage = $true
}

$snippetPath = Join-Path $configs "AGENTS.md.snippet"
$snippet = [IO.File]::ReadAllText( $snippetPath )
$agentsPath = Join-Path $target "AGENTS.md"
if ( Test-Path -LiteralPath $agentsPath ) {
    $agents = [IO.File]::ReadAllText( $agentsPath )
    if ( $agents -notmatch 'wp-standards-agent:start' ) {
        Write-FileUtf8 $agentsPath ( $agents.TrimEnd() + "`n`n" + $snippet )
        Write-Host "  appended guardrails to AGENTS.md"
    } else {
        Write-Host "  AGENTS.md already gated (skipped)"
    }
} else {
    Write-FileUtf8 $agentsPath $snippet
    Write-Host "  created AGENTS.md with guardrails"
}

Write-Host ""
Write-Host "Next steps:"
Write-Host ""
if ( $madeComposer ) {
    Write-Host "  composer install"
} else {
    Write-Host "  composer require --dev laravel/pint phpcompatibility/php-compatibility phpstan/phpstan szepeviktor/phpstan-wordpress wp-coding-standards/wpcs"
    Write-Host "  composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true"
}
if ( $madePackage ) {
    Write-Host "  npm install   (installs husky + prettier and wires the pre-commit gate)"
} else {
    Write-Host "  npm i -D husky prettier && npm pkg set scripts.prepare=husky && npm run prepare"
}
Write-Host ""
Write-Host "Then run the chain: npm run build; npm run format:all:check; vendor/bin/phpcs --standard=phpcs.xml; vendor/bin/phpstan analyse"
Write-Host ""