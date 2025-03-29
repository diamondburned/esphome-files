#!/usr/bin/env bash
set -eo pipefail

CONFIG_FILES=( *.yaml )
GLOBAL_TLD="lan"

main() {
	if ! command -v esphome > /dev/null; then
		log "esphome is not installed. Please install it first."
		return 1
	fi

	deviceName="$1"
	if [[ $deviceName ]]; then
		flash "${deviceName%.yaml}.yaml"
	else
		flash_all
	fi

	if [[ $? != 0 ]]; then
		log_error "Failed to flash devices"
		return $err
	fi
}

flash_all() {
	FAILED=

	for config in "${CONFIG_FILES[@]}"; do
		if [[ $config == secrets.yaml ]]; then
			continue
		fi
		flash "$config" || FAILED=1
	done

	if [[ $FAILED ]]; then
		return 1
	fi
}

flash() {
	configFile="$1"
	deviceName="$(basename "$configFile" .yaml)"

	if ! deviceAddr="$(dig +short "$deviceName.$GLOBAL_TLD")"; then
		log_title "Flashing $deviceName"
		log_error "Could not resolve $deviceName.$GLOBAL_TLD, skipping device"
		return 1
	else
		log_title "Flashing $deviceName at $deviceAddr"
	fi

	if ! esphome run --no-logs "$configFile" --device "$deviceAddr"; then
		log_error "Failed to flash $deviceName"
		return 1
	fi
}

log_info() {
	echo -e "\e[1;32m$1\e[0m" 1>&2
}

log_error() {
	echo -e "\e[1;31m$1\e[0m" 1>&2
}

log_title() {
	local separator
	printf -v separator '=%.0s' {1..80}

	log_info "$separator"
	log_info "$1"
	log_info "$separator"
	log_info ""
}

main "$@"
