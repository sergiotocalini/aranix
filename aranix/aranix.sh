#!/usr/bin/env ksh
rcode=0
PATH=/usr/local/bin:${PATH}

#################################################################################

#################################################################################
#
#  Variable Definition
# ---------------------
#
APP_NAME=$(basename $0)
APP_DIR=$(dirname $0)
APP_VER="1.0.0"
APP_WEB="https://sergiotocalini.github.io/"
APP_FIX="https://github.com/sergiotocalini/aranix/issues"
TIMESTAMP=`date '+%s'`
CACHE_DIR=${APP_DIR}/tmp
CACHE_TTL=5                                      # IN MINUTES
ARANGODB_URL="http://localhost:8529"
#
#################################################################################

#################################################################################
#
#  Load Environment
# ------------------
#
[[ -f ${APP_DIR}/${APP_NAME%.*}.conf ]] && . ${APP_DIR}/${APP_NAME%.*}.conf

#
#################################################################################

#################################################################################
#
#  Function Definition
# ---------------------
#
usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -a            Query arguments."
    echo "  -h            Displays this help message."
    echo "  -j            Jsonify output."
    echo "  -s ARG(str)   Section (default=stat)."
    echo "  -v            Show the script version."
    echo ""
    echo "Please send any bug reports to ${APP_FIX}"
    exit 1
}

version() {
    echo "${APP_NAME%.*} ${APP_VER}"
    exit 1
}

refresh_cache() {
    [[ -d ${CACHE_DIR} ]] || mkdir -p ${CACHE_DIR}
    type=${1:-'stats'}
    file=${CACHE_DIR}/${type}.json
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
	if [[ ${type} == 'stats' ]]; then
	    RESOURCE="/_admin/statistics"
	elif [[ ${type} =~ server_.* ]]; then
	    if [[ ${type} =~ .*_role ]]; then
		RESOURCE="/_admin/server/role"
	    else
		RESOURCE="/_admin/server/id"
	    fi
	elif [[ ${type} == 'cluster-stats' ]]; then
	    RESOURCE="/_admin/clusterStatistics"
	elif [[ ${type} == 'api-version' ]]; then
	    RESOURCE="/_api/version"
	else
	    return 1
	fi
	curl -s "${ARANGODB_URL}${RESOURCE}" 2>/dev/null | jq '.' > ${file}
    fi
    echo "${file}"
    return 0
}

discovery() {
    resource=${1}
    json=$( refresh_cache ${resource} )
}

get_stat() {
    type=${1}
    name=${2}
    resource=${3}
    json=$( refresh_cache ${type} )
    if [[ ${type} =~ (server_.*|api-version) ]]; then
	res=`jq -r ".\"${name}\"" ${json}`
    else
	res=`jq -r ".\"${name}\".${resource}" ${json}`
    fi
    echo ${res}
}
#
#################################################################################

#################################################################################
while getopts "s::a:s:uphvj:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	s)
	    SECTION="${OPTARG}"
	    ;;
        j)
            JSON=1
            IFS=":" JSON_ATTR=(${OPTARG//p=})
            ;;
	a)
	    ARGS[${#ARGS[*]}]=${OPTARG//p=}
	    ;;
	v)
	    version
	    ;;
         \?)
            exit 1
            ;;
    esac
done


if [[ ${JSON} -eq 1 ]]; then
    rval=$(discovery ${SECTION} ${ARGS[*]})
    echo '{'
    echo '   "data":['
    count=1
    while read line; do
        if [[ ${line} != '' ]]; then
           IFS="|" values=(${line})
           output='{ '
           for val_index in ${!values[*]}; do
              output+='"'{#${JSON_ATTR[${val_index}]:-${val_index}}}'":"'${values[${val_index}]}'"'
              if (( ${val_index}+1 < ${#values[*]} )); then
                 output="${output}, "
              fi
           done
           output+=' }'
           if (( ${count} < `echo ${rval}|wc -l` )); then
              output="${output},"
           fi
           echo "      ${output}"
	fi
	let "count=count+1"
    done <<< ${rval}
    echo '   ]'
    echo '}'
else
    rval=$( get_stat ${SECTION} ${ARGS[*]} )
    rcode="${?}"
    echo "${rval:-0}"
fi

exit ${rcode}
