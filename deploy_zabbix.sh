#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

ARANGODB_SERVER=${1:-localhost}
ARANGODB_PORT=${2:-8529}
ARANGODB_METHOD=${3:-http}
ARANGODB_URL="${ARANGODB_METHOD}://${ARANGODB_SERVER}:${ARANGODB_PORT}"

mkdir -p ${ZABBIX_DIR}/scripts/agentd/aranix
cp ${SOURCE_DIR}/aranix/aranix.conf.example ${ZABBIX_DIR}/scripts/agentd/aranix/aranix.conf
cp ${SOURCE_DIR}/aranix/aranix.sh ${ZABBIX_DIR}/scripts/agentd/aranix/
cp ${SOURCE_DIR}/aranix/zabbix_agentd.conf ${ZABBIX_DIR}/zabbix_agentd.d/aranix.conf
sed -i "s|ARANGODB_URL=.*|ARANGODB_URL=\"${ARANGODB_URL}\"|g" ${ZABBIX_DIR}/scripts/agentd/aranix/aranix.conf
