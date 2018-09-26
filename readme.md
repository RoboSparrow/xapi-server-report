# xAPI server report (bash)

Example shell script for sending Linux server info to an xAPI LRS. This is just an experiment with [Experience API](https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-About.md#partone) and Bash.

 * Copy `config.template` to `config` and edit values (see comments)
 * Add `report.sh` to (root) cron

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

1. Copy `config.template` to `config` and fill in the values. See comments in file for help.
2. make `report.sh` executable and add it to your root cron (see example)

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

# disable/set cron mail target
MAILTO=""
# will run the report every 10 minutes
*/10 * * * * /<path-to-script>/report.sh

...
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
