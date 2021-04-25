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
