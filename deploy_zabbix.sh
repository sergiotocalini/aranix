#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -F            Force configuration overwrite."
    echo "  -H            Displays this help message."
    echo "  -P            Installation prefix (SCRIPT_DIR)."
    echo "  -Z            Zabbix agent include files directory (ZABBIX_INC)."
    echo "  -u            Configuration key ARANGODB_URL."
    echo ""
    echo "Please send any bug reports to https://github.com/sergiotocalini/aranix/issues"
    exit 1
}

while getopts ":o:p:u:P:Z:FH" OPTION; do
    case ${OPTION} in
	F)
	    FORCE=true
	    ;;
	H)
	    usage
	    ;;
	P)
	    SCRIPT_DIR="${OPTARG}"
	    if [[ ! "${SCRIPT_DIR}" =~ .*aranix ]]; then
		SCRIPT_DIR="${SCRIPT_DIR}/aranix"
	    fi
	    ;;
	Z)
	    ZABBIX_INC="${OPTARG}"
	    ;;
	u)
	    ARANGODB_URL="${OPTARG}"
	    ;;
	\?)
	    exit 1
	    ;;
    esac
done

[ -n "${SCRIPT_DIR}"  ]  || SCRIPT_DIR="${ZABBIX_DIR}/scripts/agentd/lostix"
[ -n "${ZABBIX_INC}"  ]  || ZABBIX_INC="${ZABBIX_DIR}/zabbix_agentd.d"
[ -n "${ARANGODB_URL}" ] || ARANGODB_URL="http://localhost:8529"

# Creating necessary directories
mkdir -p "${SCRIPT_DIR}" "${ZABBIX_INC}" 2>/dev/null

# Copying the main script and dependencies
cp -rpv  "${SOURCE_DIR}/aranix/aranix.sh"          "${SCRIPT_DIR}/aranix.sh"

# Provisioning script configuration
SCRIPT_CFG="${SCRIPT_DIR}/aranix.conf"
cp -rpv "${SOURCE_DIR}/aranix/aranix.conf.example" "${SCRIPT_CFG}.new"

# Adding script configuration values
regex_cfg[0]="s|ARANGODB_URL=.*|ARANGODB_URL=\"${ARANGODB_URL}\"|g"
for index in ${!regex_cfg[*]}; do
    sed -i'' -e "${regex_cfg[${index}]}" "${SCRIPT_CFG}.new"
done

# Checking if the new configuration exist
if [[ -f "${SCRIPT_CFG}" && ${FORCE:-false} == false ]]; then
    state=$(cmp --silent "${SCRIPT_CFG}" "${SCRIPT_CFG}.new")
    if [[ ${?} == 0 ]]; then
	rm "${SCRIPT_CFG}.new" 2>/dev/null
    fi
else
    mv "${SCRIPT_CFG}.new" "${SCRIPT_CFG}" 2>/dev/null
fi

# Provisioning zabbix_agent configuration
SCRIPT_ZBX="${ZABBIX_INC}/aranix.conf"
cp -rpv "${SOURCE_DIR}/aranix/zabbix_agentd.conf"  "${SCRIPT_ZBX}.new"
regex_inc[0]="s|{PREFIX}|${SCRIPT_DIR}|g"
for index in ${!regex_inc[*]}; do
    sed -i'' -e "${regex_inc[${index}]}" "${SCRIPT_ZBX}.new"
done
if [[ -f "${SCRIPT_ZBX}" ]]; then
    state=$(cmp --silent "${SCRIPT_ZBX}" "${SCRIPT_ZBX}.new")
    if [[ ${?} == 0 ]]; then
	rm "${SCRIPT_ZBX}.new" 2>/dev/null
    fi
else
    mv "${SCRIPT_ZBX}.new" "${SCRIPT_ZBX}" 2>/dev/null
fi
