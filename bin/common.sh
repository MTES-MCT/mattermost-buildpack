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
  start "Fetching jq $JQ_VERSION"
  if [ -f "${CACHE_DIR}/dist/jq-$JQ_VERSION" ]; then
    info "File already downloaded"
  else
    ${CURL} -o "${CACHE_DIR}/dist/jq-$JQ_VERSION" "https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSION/jq-linux64"
  fi
  cp "${CACHE_DIR}/dist/jq-$JQ_VERSION" "${BUILD_DIR}/bin/jq"
  chmod +x "${BUILD_DIR}/bin/jq"
  finished
}

function fetch_mattermost_dist() {
  local version="$1"
  local location="$2"
  local team="$3"
  local dist="mattermost"
  if [[ $team == "team" ]]; then
    dist="${dist}-${team}"  
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

function configure_database() {
  local mattermost_path="$1"
  local db_type="$2"
  local db_url="$3"
  local encoded_url
  encoded_url=$(printf %s "$db_url" | jq -s -R -r @uri)
  local MM_CONFIG="${mattermost_path}/config/config.json"
  info "Db type: ${db_type} url: ${encoded_url}"
  jq ".SqlSettings.DriverName = \"${db_type}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".SqlSettings.DataSource = \"${encoded_url}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
}

function configure_mattermost() {
  local mattermost_path="$1"
  local site_url="$2"
  local mattermost_port="$3"
  local smtp_host="$4"
  local smtp_port="$5"
  local smtp_user="$6"
  local smtp_password="$7"
  local file_driver_name="$8"
  local s3_key_id="$9"
  local s3_key_secret="${10}"
  local s3_bucket="${11}"
  local s3_region="${12}"
  local s3_endpoint="${13}"
  local MM_CONFIG="${mattermost_path}/config/config.json"
  jq ".ServiceSettings.SiteURL = \"${site_url}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".ServiceSettings.ListenAddress = \":${mattermost_port}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".EmailSettings.SMTPUsername = \"${smtp_user}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".EmailSettings.SMTPPassword = \"${smtp_password}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".EmailSettings.SMTPServer = \"${smtp_host}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".EmailSettings.SMTPPort = \"${smtp_port}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".FileSettings.DriverName = \"${file_driver_name}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".FileSettings.AmazonS3AccessKeyId = \"${s3_key_id}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".FileSettings.AmazonS3SecretAccessKey = \"${s3_key_secret}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".FileSettings.AmazonS3Bucket = \"${s3_bucket}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".FileSettings.AmazonS3Region = \"${s3_region}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".FileSettings.AmazonS3Endpoint = \"${s3_endpoint}\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
  jq ".PluginSettings.ClientDirectory = \"/app/mattermost/client/plugins\"" "$MM_CONFIG" >"$MM_CONFIG.tmp" && mv "$MM_CONFIG.tmp" "$MM_CONFIG"
}
