# xAPI server report

Example shell script for sending Linux server info to an xAPI LRS. This is just an experiment using [xAPI](https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-About.md#partone) and bash.

 * Configure and add it to (root) cron


The scripts sends a small report as an xAPI statement to an LRS

 * disk space
 * home folder size
 * memory usage
 * cpu usage

The report is stored as an xapi result extension within `statement.result` property

```javascript
//...
{
    "machine": "robosparrow",
    "disk": {
        "/dev/sda2": {
            "size": "909G",
            "used": "688G",
            "available": "175G",
            "percent": "80%"
        }
    },
    "home": {
        "/home": "639G",
        "/home/robosparrow": "639G"
    },
    "memory": {
        "used": "2546172M",
        "total": "16383192M",
        "percent": "15.54%"
    },
    "cpu": {
        "cpu-load": "0.15"
    },
    "initialized": "2017-06-26T00:46:29.316Z",
    "duration": "1639ms"
}
//...
```
See a complete statement example below

## Configuration and installation

**1) System and LRS connection**

Copy `config.template` to `config` and fill in the values.

```bash
### System config

# ip, cname, or machine name
CONFIG_SYSTEM_MACHINE="<name,ip-address,c-name>"
# main drive to inspect
CONFIG_SYSTEM_DRIVE="/dev/sda1"
# home folder to inspect
CONFIG_SYSTEM_HOME_DIR="/home"

### Curl config

# xapi lrs main endpoint without trailing slash and "statements" route, example "http://my-lrs.com/xapi"
CONFIG_LRS_ENDPOINT="<lrs main endpoint>"
# http basic auth username and password (lRS minimum permission "statements/write")
CONFIG_LRS_AUTH_USER="<user>"
CONFIG_LRS_AUTH_PASS="<pass>"
```

**2) xAPI statement configuration**

You find xAPI statemment variables on top of the `report.sh`

```bash
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
```

## Usage

It is highly recommended to run this script with root permissions in order to avoid file permission issues

```bash
sudo ./report.sh

```

Note: Bourne shell mode will fail, i.e `sh ./xapi-server-report.sh` due to the function syntax used


**2 Crontab example**

```bash
sudo crontab -e
...
#will run the report every 10 minutes
*/10 * * * * /<path-to-script>/report.sh
```

## Complete example statement


```javascript
{
    "actor":{
        "name":"",
        "mbox":"mailto:@server-check.test"
    },
    "verb":{
        "id":"/taxonomy/verbs/reported",
        "display":{
            "en-US":"reported"
        }
    },
    "object":{
        "id":"/taxonomy/activities/server-check",
        "definition":{
            "name":{
                "en-US":"server check"
            }
        }
    },
    "result": {
        "completion": true,
        "response": "Server check finished in 1615 milliseconds.",
        "extensions": {
            "/profiles/server-check/extensions/result/stats": {
                "machine": "robosparrow",
                "disk": {
                    "/dev/sda2": {
                        "size": "909G",
                        "used": "688G",
                        "available": "175G",
                        "percent": "80%"
                    }
                },
                "home": {
                    "/home": "639G",
                    "/home/robosparrow": "639G"
                },
                "memory": {
                    "used": "2552516M",
                    "total": "16383192M",
                    "percent": "15.58%"
                },
                "cpu": {
                    "cpu-load": "0.10"
                },
                "initialized": "2017-06-26T00:50:48.812Z",
                "duration": "1615ms"
            }
        }
    },
    "timestamp": "2017-06-26T00:50:50Z"
}
```
