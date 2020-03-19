# osqueryd troubleshooting

## Symptoms

### /var/osqueryd consumes a lot of space

This seems to happen, when local data caching is enabled (which we should try to avoid) and osqueryd is collecting too many data, which is leading the underlying rocketdb to loose track of `/var/osquery/osquery.db/*.sst` which are not cleaned up anymore.

1. trim down the profile to collect less data (especially not each file access, as is done with the default profile)
2. disable local data caching
3. `systemctl stop osqueryd; rm /var/osquery/osquery.db/*.sst; systemctl start osqueryd`


### osqueryd is consuming more than 10% CPU on one core

osqueryd should not be impacting production services and we are using a
configuration profile that is keeping CPU consumption of the `osqueryd` process
very low. We setup an alert that triggers if CPU consumption on one core is
higher than 10% for 15m. If it triggers it usually means that

  * the configuration of osqueryd is making it check too many things
    * Solution: give the security team insight into the osqueryd logs and let
      them adjust the profile
  * or the underlying rocketsdb is corrupt (check if there are stale old
    `/var/osquery/osquery.db/*.sst` files
    * Solution: `systemctl stop osqueryd; rm /var/osquery/osquery.db/*.sst; systemctl start osqueryd`
