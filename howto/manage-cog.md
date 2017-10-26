# COG

[Cog](https://github.com/operable/cog/) is a chatops bot that lurks in our slack, it replies to the name of [@marvin](https://en.wikipedia.org/wiki/Marvin_\(character\))

## How to

### Troubleshoot marvin being down

* ssh into cog.gitlap.com
* Turn into root with `sudo su -`
* Check that cog is not running with `docker ps`
* If it's not runnig you should not get any ouptut, if it is running yous should see something like this: ```
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                                                                             NAMES
ce0cdef19d3e        operable/relay:latest   "/usr/local/bin/relay"   3 minutes ago       Up 2 minutes                                                                                          root_relay_1
67509f728e6e        operable/cog:latest     "/home/operable/co..."   3 minutes ago       Up 2 minutes        0.0.0.0:4001-4002->4001-4002/tcp, 0.0.0.0:32769->1883/tcp, 0.0.0.0:80->4000/tcp   root_cog_1
cefd144ca3be        postgres:9.5.4          "/docker-entrypoin..."   4 weeks ago         Up 2 minutes        5432/tcp                                                                          root_postgres_1
```
* If it's not running, start it again with `docker-compose start`
* Wait in slack to see him pop up again.

### Run cogctl

* ssh into cog.gitlap.com
* Turn into root `sudo su -`
* Start a bash interpreter inside the container `docker exec -it $(docker-compose ps -q cog) bash`
* Here you can run `cogctl`

### Add a user

Adding a user can be done from slack by having the user talk to `@marvin`. They can then be added to a group by an admin with `!group-member-add <group-name> <user-handle>`.
Alternatively a user can be added from the console with the following:

* Follow the _Run cogctl_ instructions to get yourself into a bash inside cog
* Run the following command `cogctl user create <username> --first-name <first name> --last-name <last name> --email <email> --password <generated password>`
* Add a handle to the user `cogctl chat-handle create $username slack $username < /dev/null``

### Install a bundle

### Know how secure our cog instance is

Please refer to <https://gitlab.com/gitlab-com/infrastructure/issues/2451>.

...
