# GitLab Pages returning 404

## Symptoms

Users may report seeing 404 errors whenever they access a GitLab pages domain
(e.g. https://pages.gitlab.io). If they try from a different IP address,
things may work fine.

This may be an issue with one or more gitlab-pages instances. Since the load
balancer may map a specific instance by IP address, the problem may be
only apparent to some users but not others.

## Possible checks

1. Ask the user to run:

    ```
    curl -v https://pages.gitlab.io > /dev/null
    ```

1. Go to https://log.gitlap.com and look for that request. You can search in Kibana for the terms:


    ```
    curl AND "gitlab-pages"
    ```

    Note that the AND must be all caps and the quotes are necessary around the word `gitlab-pages`.

1. This will help isolate which worker is having an issue. You can also use Kibana to look for patterns :

    ```
    "gitlab-pages" AND 404 AND "https://pages.gitlab.io"
    ```

1. Bypass the load balancer by setting up a SOCKS proxy by logging in to a specific worker. For example,
   to login to worker1, run:

    ```sh
    ssh worker1-cluster-gitlab-com.cloudapp.net -D localhost:5000
    ```

1. Find out on which port gitlab-pages is running:

    ```
    $ ps -ef | grep gitlab-pages | grep listen
    root     31269  3496  0 03:32 ?        00:00:00 /opt/gitlab/embedded/bin/gitlab-pages -listen-http 0.0.0.0:1080 -listen-https 0.0.0.0:1443 -root-cert /etc/gitlab/ssl/pages.crt -root-key /etc/gitlab/ssl/pages.key -daemon-uid 1100 -daemon-gid 1100 -pages-domain gitlab.io -pages-root /var/opt/gitlab/gitlab-rails/shared/pages -redirect-http false -use-http2 true
    ```

    In this example, gitlab-pages is listening for:

    * HTTPS on port 1443
    * HTTP on port 1080

1. Now attempt to run `curl` by proxying through this SOCKS host with a custom
  `Host` header and SSL verification disabled:


    ```sh
    curl -I -k -v --header "Host: pages.gitlab.io" --socks5 localhost:5000 https://127.0.0.1:1443
    ```

    If there is a problem, you will see a 404:

    ```sh
    * Rebuilt URL to: https://127.0.0.1:1443/
    *   Trying ::1...
    * 127
    * 0
    * 0
    * 1
    * Connected to localhost (::1) port 5000 (#0)
    * TLS 1.2 connection using TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
    * Server certificate: *.gitlab.io
    * Server certificate: COMODO RSA Domain Validation Secure Server CA
    * Server certificate: COMODO RSA Certification Authority
    * Server certificate: AddTrust External CA Root
    > HEAD / HTTP/1.1
    > Host: pages.gitlab.io
    > User-Agent: curl/7.43.0
    > Accept: */*
    >
    < HTTP/1.1 404 Not Found
    HTTP/1.1 404 Not Found
    < Content-Type: text/html; charset=utf-8
    Content-Type: text/html; charset=utf-8
    < X-Content-Type-Options: nosniff
    X-Content-Type-Options: nosniff
    < Date: Sun, 07 Aug 2016 13:38:34 GMT
    Date: Sun, 07 Aug 2016 13:38:34 GMT
    ```

    If everything is normal, you should see "200 OK" instead of "404 Not Found".

1. If you are seeing a 404, scan the logs to see when gitlab-pages last updated its domain list:

    ```sh
    sudo grep Updated /var/log/gitlab/gitlab-pages/current
    ```

1. If you see no entries, you may have to scan the older logs in gzip format. For example:

    ```sh
    # sudo ls -lt /var/log/gitlab-pages/current
    total 34800
    -rw-r--r-- 1 root root 1915178 Aug  7 13:42 current
    -rwxr--r-- 1 root root  928317 Aug  7 04:34 @4000000057a6ba563a8da1b4.s
    <snip>

    # sudo zgrep Updated /var/log/gitlab-pages/current/@4000000057a6ba563a8da1b4.s
    ```

1. If you see a message such as the following:

    ```
    2016-08-05_13:14:39.47477 worker1 gitlab-pages: 2016/08/05 13:14:39 Updated 0 domains in 182.5¬µs Hash: []
    ```

    This means gitlab-pages had trouble reading `/var/opt/gitlab/gitlab-rails/shared/pages/.update`.


1. Gather some strace information for a few minutes before restarting gitlab-pages:

    ```sh
    $ sudo strace -f -p `pidof gitlab-pages >& /tmp/gitlab-pages-debug.txt`
    ```

1. Restart gitlab-pages:

    ```sh
    $ sudo gitlab-ctl restart gitlab-pages
    ```
