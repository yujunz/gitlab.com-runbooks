# Errors are reported in LOG files

## First and foremost

*Don't Panic*

## Symptoms

* Message in alerts channel _Check_MK: service LOG /path/to/some.log is CRITICAL_

## Possible checks

* Go to https://checkmk.gitlap.com/gitlab/check_mk/logwatch.py to see the log message
that triggered the alert (the specific line will be highlighted in yellow/red).

After you've resolved the cause of the alert you can mark it as acknowledged by
clicking on "Clear Logs" on that file in https://checkmk.gitlap.com/gitlab/check_mk/logwatch.py
