#!/usr/bin/env bash
set -e
######################################################################
# License Andrei Shahun, Alexander Dobrodey
# Get terraform providers file as name:version separated with new line.
# Installs providers to the TF_PLUGIN_CACHE_DIR location
######################################################################

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
  echo -e "${GREEN}INFO: ${1}${NC}"
}

warning() {
  echo -e "${YELLOW}WARNING: ${1}${NC}"
}

PROVIDERS_URL='https://releases.hashicorp.com'
if [[ "$(uname -p)" == "arm" ]]; then
  PLATFORM="darwin_arm64"
else
  PLATFORM="linux_amd64"
fi

DOWNLOAD_FILES=${2:-true}
if $DOWNLOAD_FILES; then
  mkdir -p "${TF_PLUGIN_CACHE_DIR}"
fi

while IFS= read -r line; do
  if ! [[ "${line}" =~ ^#.*$ || "${line}" =~ ^\s?$ ]]; then
 #   info "Processing \"${line}\""
    IFS=':' read -r -a config <<< "${line}"
    OWNER="${config[0]}"
    NAME="${config[1]}"
    VERSION="${config[2]}"
    ARCHIVE="/tmp/provider-${NAME}.zip"
    if [[ "$OWNER" == "hashicorp" ]]; then
      LATEST_VERSION=$(
        curl -s "https://releases.hashicorp.com/terraform-provider-${NAME}/" \
          | sed -rn "s|.*<a href=\"/terraform-provider-${NAME}/.*_(.*)<.*$|\1|p" \
          | head -n 1
      )
    else
      LATEST_VERSION=$(
        curl -s "https://api.github.com/repos/${OWNER}/terraform-provider-${NAME}/releases/latest" \
          | sed -rn "s|.*\"name\": \"v(.*)\".*$|\1|p" \
          | head -n 1
      )
    fi
    if [[ "${LATEST_VERSION}" == "" ]]; then
      warning "Provider ${OWNER}/${NAME} skipped, cannot find latest version"
    elif [[ "${LATEST_VERSION}" != "${VERSION}" ]]; then
      info "Found new version: ${LATEST_VERSION} for provider ${OWNER}/${NAME}"
    fi
    if $DOWNLOAD_FILES; then
      info "Downloading terraform-provider-${NAME}_${VERSION}_${PLATFORM}.zip"

      DOWNLOAD_URL="${PROVIDERS_URL}/terraform-provider-${NAME}/${VERSION}/terraform-provider-${NAME}_${VERSION}_${PLATFORM}.zip"
      if [[ "${OWNER}" != "hashicorp" ]]; then
        DOWNLOAD_URL="https://github.com/${OWNER}/terraform-provider-${NAME}/releases/download/v${VERSION}/terraform-provider-${NAME}_${VERSION}_${PLATFORM}.zip"
      fi

      if ! wget --quiet "${DOWNLOAD_URL}" -O "${ARCHIVE}"; then
        warning "Failed to install ${NAME}_${VERSION}"
        wget "${DOWNLOAD_URL}" -O "${ARCHIVE}"
        continue
      fi

      TARGET_DIR="${TF_PLUGIN_CACHE_DIR}/registry.terraform.io/${OWNER}/${NAME}/${VERSION}/${PLATFORM}/"
      mkdir -p "${TARGET_DIR}"

      unzip -o "${ARCHIVE}" -d "${TARGET_DIR}" > /dev/null
      rm -f "${ARCHIVE}"
    fi
  fi
done < "$1"
