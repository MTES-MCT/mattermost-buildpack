#!/bin/bash

steptxt="----->"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'                              # No Color
CURL="curl -L --retry 15 --retry-delay 2" # retry for up to 30 seconds

info() {
  echo -e "${GREEN}       $*${NC}"
}

warn() {
  echo -e "${YELLOW} !!    $*${NC}"
}

err() {
  echo -e "${RED} !!    $*${NC}" >&2
}

step() {
  echo "$steptxt $*"
}

start() {
  echo -n "$steptxt $*... "
}

finished() {
  echo "done"
}

function indent() {
  c='s/^/       /'
  case $(uname) in
  Darwin) sed -l "$c" ;; # mac/bsd sed: -l buffers on line boundaries
  *) sed -u "$c" ;;      # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

function install_jq() {
  if [[ -f "${ENV_DIR}/JQ_VERSION" ]]; then
    JQ_VERSION=$(cat "${ENV_DIR}/JQ_VERSION")
  else
    JQ_VERSION=1.6
  fi
  step "Fetching jq $JQ_VERSION"
  if [ -f "${CACHE_DIR}/dist/jq-$JQ_VERSION" ]; then
    info "File already downloaded"
  else
    ${CURL} -o "${CACHE_DIR}/dist/jq-$JQ_VERSION" "https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSION/jq-linux64"
  fi
  cp "${CACHE_DIR}/dist/jq-$JQ_VERSION" "${BUILD_DIR}/bin/jq"
  chmod +x "${BUILD_DIR}/bin/jq"
  finished
}

function install_plugin() {
  local location="$1"
  local plugin_url="$2"
  local plugin_package
  # local plugin_package
  plugin_package=$(echo "$plugin_url" | rev | cut -d '/' -f 1 | rev )
  if [ -f "${CACHE_DIR}/dist/plugins/${plugin_package}" ]; then
    info "$plugin_package is already downloaded in cache"
  else
    ${CURL} -o "${CACHE_DIR}/dist/plugins/$plugin_package" "$plugin_url"
  fi
  mv "${CACHE_DIR}/dist/plugins/${plugin_package}" "$location"
  info "Plugin $plugin_package installed in $location"
}

function fetch_github_latest_release() {
  local repo="$1"
  local http_code
  http_code=$($CURL -G -o "$TMP_PATH/latest_release.json" -w '%{http_code}' -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${repo}/releases/latest")
  local plugin_url
  if [[ $http_code == 200 ]]; then
    plugin_url=$(cat "$TMP_PATH/latest_release.json" | jq 'if (.assets | length < 2) then .assets[0].browser_download_url else .assets[] | select(.name|test("linux_amd64";"ix")) | .browser_download_url end' | xargs)
    plugin_url="${plugin_url%\"}"
    plugin_url="${plugin_url#\"}"
  fi
  echo "$plugin_url"
}

function install_github_plugins_list() {
  local location="$1"
  local plugins_list="$2"
  info "Plugins list to install: ${plugins_list}"
  local plugin_url
  for plugin_id in $(echo "$plugins_list" | tr ',' '\n')
  do
    plugin_url=$(fetch_github_latest_release "$plugin_id")
    info "Plugin id to install: ${plugin_id}"
    if [[ -n $plugin_url ]]; then
      install_plugin "$location" "$plugin_url"
    else
      warn "No plugin with id $plugin_id found in Github"
    fi
  done
}

function install_marketplace_plugins_list() {
  local location="$1"
  local server_version="$2"
  local plugins_list="$3"
  info "Plugins list to install: ${plugins_list}"
  local http_code
  http_code=$($CURL -G -o "$TMP_PATH/plugins.json" -w '%{http_code}' -H "Accept: application/json" "https://api.integrations.mattermost.com/api/v1/plugins?platform=linux-amd64&server_version=$server_version")
  local plugin_url
  if [[ $http_code == 200 ]]; then
    for plugin_id in $(echo "$plugins_list" | tr ',' '\n')
    do
      info "Plugin id to install: ${plugin_id}"
      plugin_url=$(cat "$TMP_PATH/plugins.json" | jq --arg id "$plugin_id" '.[] | select(.manifest.id == $id) | .download_url')
      plugin_url="${plugin_url%\"}"
      plugin_url="${plugin_url#\"}"
      if [[ -n $plugin_url ]]; then
        install_plugin "$location" "$plugin_url"
      else
        warn "No plugin with id $plugin_id found in marketplace"
      fi
    done
  else
    warn "No plugins list found in marketplace"
  fi
}

function fetch_mattermost_dist() {
  local version="$1"
  local location="$2"
  local edition="$3"
  local dist="mattermost"
  if [[ $edition == "team" ]]; then
    dist="${dist}-${edition}"  
  fi
  dist="${dist}-${version}-linux-amd64.tar.gz"
  local dist_url="https://releases.mattermost.com/${version}/${dist}"
  if [ -f "${CACHE_DIR}/dist/${dist}" ]; then
    info "File is already downloaded"
  else
    ${CURL} -o "${CACHE_DIR}/dist/${dist}" "${dist_url}"
  fi
  tar xzf "$CACHE_DIR/dist/${dist}" -C "$location"
}
