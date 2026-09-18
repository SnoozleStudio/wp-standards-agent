#!/usr/bin/env bash
set -euo pipefail

# Install wp-standards-agent into a WordPress plugin or theme project.
# Usage: ./install.sh [target-dir] [slug] [text-domain]
# Non-interactive when slug is given (or WSA_SLUG set); text-domain falls back
# to slug.

TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" && pwd)"
SLUG="${2:-${WSA_SLUG:-}}"
TEXT_DOMAIN="${3:-${WSA_TEXT_DOMAIN:-}}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS="$REPO_ROOT/skills/wp-standards-agent/configs"

if [ ! -d "$TARGET" ]; then
    echo "Target directory does not exist: $TARGET" >&2
    exit 1
fi

DEFAULT_SLUG="$(basename "$TARGET")"
if [ -z "$SLUG" ]; then
    read -r -p "Project slug [$DEFAULT_SLUG]: " SLUG
fi
SLUG="${SLUG:-$DEFAULT_SLUG}"

if [ -z "$TEXT_DOMAIN" ]; then
    read -r -p "Text domain [$SLUG]: " TEXT_DOMAIN
fi
TEXT_DOMAIN="${TEXT_DOMAIN:-$SLUG}"

install_file() {
    local name="$1"
    local src="$CONFIGS/$name"
    local dst="$TARGET/$name"
    local content
    content="$(sed -e "s/{{SLUG}}/$SLUG/g" -e "s/{{TEXT_DOMAIN}}/$TEXT_DOMAIN/g" "$src")"
    if [ -f "$dst" ]; then
        cp "$dst" "$dst.bak"
        echo "  backed up existing $name -> $name.bak"
    fi
    mkdir -p "$(dirname "$dst")"
    printf '%s\n' "$content" > "$dst"
    echo "  installed $name"
}

echo ""
echo "Installing wp-standards-agent into $TARGET"
echo ""

install_file "phpcs.xml"
install_file "pint.json"
install_file "phpstan.neon"
install_file ".prettierrc"
install_file ".prettierignore"
install_file ".husky/pre-commit"

if [ ! -f "$TARGET/.gitignore" ]; then
    install_file ".gitignore"
else
    echo "  kept existing .gitignore"
fi

if [ ! -f "$TARGET/.gitattributes" ]; then
    install_file ".gitattributes"
else
    echo "  kept existing .gitattributes (ensure '*.php text eol=lf' is present)"
fi

MADE_COMPOSER=0
if [ -f "$TARGET/composer.json" ]; then
    echo "  kept existing composer.json (merge dev deps manually)"
else
    install_file "composer.json"
    MADE_COMPOSER=1
fi

MADE_PACKAGE=0
if [ -f "$TARGET/package.json" ]; then
    echo "  kept existing package.json (add scripts + devDeps manually)"
else
    install_file "package.json"
    MADE_PACKAGE=1
fi

SNIPPET="$(cat "$CONFIGS/AGENTS.md.snippet")"
AGENTS="$TARGET/AGENTS.md"
if [ -f "$AGENTS" ]; then
    if grep -q 'wp-standards-agent:start' "$AGENTS"; then
        echo "  AGENTS.md already gated (skipped)"
    else
        printf '\n\n%s\n' "$SNIPPET" >> "$AGENTS"
        echo "  appended guardrails to AGENTS.md"
    fi
else
    printf '%s\n' "$SNIPPET" > "$AGENTS"
    echo "  created AGENTS.md with guardrails"
fi

echo ""
echo "Next steps:"
echo ""
if [ "$MADE_COMPOSER" -eq 1 ]; then
    echo "  composer install"
else
    echo "  composer require --dev laravel/pint phpcompatibility/php-compatibility phpstan/phpstan szepeviktor/phpstan-wordpress wp-coding-standards/wpcs"
    echo "  composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true"
fi
if [ "$MADE_PACKAGE" -eq 1 ]; then
    echo "  npm install   (installs husky + prettier and wires the pre-commit gate)"
else
    echo "  npm i -D husky prettier && npm pkg set scripts.prepare=husky && npm run prepare"
fi
echo ""
echo "Then run the chain: npm run build; npm run format:all:check; vendor/bin/phpcs --standard=phpcs.xml; vendor/bin/phpstan analyse"
echo ""