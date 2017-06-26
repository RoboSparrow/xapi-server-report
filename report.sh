#!/bin/bash

##
#
# Install:
#    make file executable
# Usage
#   `./xapi-server-report.sh`
#   Do not use bourne shell, i.e `sh ./xapi-server-report.sh`, it will likely throw "bad variable errors" due to function syntax
#
##

source config

##
# Editable configuration
##

### xAPI statement config

# statement.actor name (human readable)
CONFIG_XAPI_ACTOR_NAME="${CONFIG_SYSTEM_MACHINE}"
# statement.actor email
CONFIG_XAPI_ACTOR_EMAIL="${CONFIG_SYSTEM_MACHINE}@server-check.test"

# statement.verb.display name (human readable)
CONFIG_XAPI_VERB_NAME="reported"
# statement.verb.id (valid IRI)
CONFIG_XAPI_VERB_IRI="${CONFIG_LRS_ENDPOINT}/taxonomy/verbs/reported"

# statement.object.definition activity name (human readable)
CONFIG_XAPI_ACTIVITY_NAME="server check"
# statement.object.id (valid IRI)
CONFIG_XAPI_ACTIVITY_IRI="${CONFIG_LRS_ENDPOINT}/taxonomy/activities/server-check"

# statement.result.extensions extension id (valid IRI)
# Our the server check results are stored in statement.result.extensions[id]
CONFIG_XAPI_EXTENSION_IRI="${CONFIG_LRS_ENDPOINT}/profiles/server-check/extensions/result/stats"

##
# disk space
# https://linux.die.net/man/1/du
# arg $1 source
##
dfcmd() {
    local message
    message=$(df -B G --output=source,size,used,avail,pcent "$1" | awk '
        BEGIN {
            print "{"
        }
        NR==1 {
        }
        NR!=1{
            printf "                    \"%s\": {\n", $1
            printf "                        \"size\": \"%s\",\n", $2
            printf "                        \"used\": \"%s\",\n", $3
            printf "                        \"available\": \"%s\",\n", $4
            printf "                        \"percent\": \"%s\"\n", $5
            printf "                    }%s\n", block_separator
            block_separator = ","
        }
        END {
            print "                }"
        }
    ')
    echo "$message"
}

##
# folder size and subfolders
# https://linux.die.net/man/1/du
# arg $1 folder
# arg $2 max-depth
##
ducmd() {
    local message
    message=$(du -h --max-depth="$2" "$1" 2>/dev/null | sort -h | awk '
        BEGIN {
            separator = "                    "
            print "{"
        }
        {
            printf "%s\"%s\": \"%s\"", separator, $2, $1
            separator = ",\n                    "
        }
        END {
            print "\n                }"
        }
    ')
    echo "$message"
}

##
# memory usage
# https://linux.die.net/man/1/free
##
freecmd() {
    local message
    message=$(free -t | awk '
        BEGIN {
            separator = "                    "
            print "{"
        }
        END{
            printf "%s\"used\": \"%sM\"", separator, $3
            separator = ",\n                    "
            printf "%s\"total\": \"%sM\"", separator, $2
            printf "%s\"percent\": \"%.2f%%\"", separator, $3*100/$2
            print "\n                }"
        }
    ')
    echo "$message"
}

##
# cpu usage
# https://linux.die.net/man/1/top
##
topcmd() {
    local message
    message=$(top -bn1 | grep load | awk '
        {
            print "{"
            printf "                    \"cpu-load\": \"%.2f\"", $(NF-2)
            print "\n                }"
        }
    ' )
    echo "$message"
}

JSON_ISODATE_NOW=$(date --utc +%FT%T.%3NZ)
START_TIME=$(($(date +%s%N)/1000000))

# build json

JSON_DRIVE=$(dfcmd $CONFIG_SYSTEM_DRIVE)
JSON_DIR=$(ducmd $CONFIG_SYSTEM_HOME_DIR 1)
JSON_MEMORY=$(freecmd)
JSON_CPU=$(topcmd)

JSON_ISODATE_DONE=$(date --utc +%FT%TZ)
END_TIME=$(($(date +%s%N)/1000000))
ELAPSED_TIME=$((END_TIME - START_TIME))

JSON_EXTENSION="{
            \"${CONFIG_XAPI_EXTENSION_IRI}\": {
                \"machine\": \"${CONFIG_SYSTEM_MACHINE}\",
                \"disk\": ${JSON_DRIVE},
                \"home\": ${JSON_DIR},
                \"memory\": ${JSON_MEMORY},
                \"cpu\": ${JSON_CPU},
                \"initialized\": \"${JSON_ISODATE_NOW}\",
                \"duration\": \"${ELAPSED_TIME}ms\"
            }
        }"


JSON_STATEMENT="{
    \"actor\":{
        \"name\":\"${CONFIG_XAPI_ACTOR_NAME}\",
        \"mbox\":\"mailto:${CONFIG_XAPI_ACTOR_EMAIL}\"
    },
    \"verb\":{
        \"id\":\"${CONFIG_XAPI_VERB_IRI}\",
        \"display\":{
            \"en-US\":\"${CONFIG_XAPI_VERB_NAME}\"
        }
    },
    \"object\":{
        \"id\":\"${CONFIG_XAPI_ACTIVITY_IRI}\",
        \"definition\":{
            \"name\":{
                \"en-US\":\"${CONFIG_XAPI_ACTIVITY_NAME}\"
            }
        }
    },
    \"result\": {
        \"completion\": true,
        \"response\": \"Server check finished in ${ELAPSED_TIME} milliseconds.\",
        \"extensions\": ${JSON_EXTENSION}
    },
    \"timestamp\": \"${JSON_ISODATE_DONE}\"
}"

# debug

# echo "$JSON_STATEMENT"
# exit

STATUS=$(curl -s -w "status: %{http_code}, " \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-H "X-Experience-API-Version:1.0.1" \
--data "${JSON_STATEMENT}" \
-u "${CONFIG_LRS_AUTH_USER}:${CONFIG_LRS_AUTH_PASS}" \
-X POST "${CONFIG_LRS_ENDPOINT}/statements"; echo "exit code: $?")

echo $STATUS
logger "xapi-server-report: ${STATUS}"
