# Prometheus Dead Man's Snitch

## Symptoms

Prometheus SnitchHeartBeat is an always-firing alert. It's used as an end-to-end test of Prometheus through the Alertmanager.

## Possible checks

* Make sure the SnitchHeartBeat alert is not silenced.
* Check the Prometheus and Alertmanager logs to make sure they are communicating properly with https://deadmanssnitch.com/.
