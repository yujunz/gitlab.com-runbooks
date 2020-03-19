# Node memory alerts

## HighMemoryPressure

This indicates there may not be enough memory on the node in order to operate.

The alert combines two signals:
* The available memory is under 5%.
* There is a high rate of major page faults.  This indicates that there is not enough memory to keep application pages in memory.

Possible issues:
* A run-away cron job uses too much memory.
* The application load is too high.
* There are memory leaks.

Possible actions:
* Kill runaway job(s).
* Provision more memory on the node.
