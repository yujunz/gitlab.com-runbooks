# Google mtail for prometheus metrics

https://github.com/google/mtail

This is a way of getting metrics out of logs.

To do so we will be using regexes and a program called mtail that will be
watching these log files to parse and execute counts as the files are being
written.

## Getting started

1. Pick the log file you want to be parsing
1. Code the `prog` you need for parsing this file referring to https://github.com/google/mtail/blob/master/docs/Programming-Guide.md
1. Configure the mtail prog files in [gitlab-prometheus](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus), such that
  1. There is a file that defines the parsing job stored in `files/default/mtail/<job_name>.mtail`
  1. There is a recipe that configures mtail to copy this file into the progs folder, for ex: `recipes/mtail-nginx.rb` (check this file)
  1. There is a spec file that checks that the file is correctly configured.
  1. You bump the cookbook version and install
1. Deploy to production

## Testing the parsing locally

Using a local folder such as `~/tmp`

1. Capture a log file so you can use it, store it with a name like log-source in the tmp folder.
1. In this same folder store the `prog.mtail` file that describes how to parse and count things.
1. Using docker start a container such that `docker run --name mtail -v ${HOME}/tmp:/tmp -p 3903:3903 --rm dylanmei/mtail -progs /tmp --logs /tmp/<logfile-you-expect>`
1. `curl -s localhost:3903/metrics`, you should only see a comment with the names of the metrics, nothing should have been accounted for.
1. cat the source file into the expected log file to make mtail detect that something was written down, for example: `# cat log-source > logfile-you-expect`
1. `curl -s localhost:3903/metrics`, you should now see that mtail is counting things
1. rinse and repeat
