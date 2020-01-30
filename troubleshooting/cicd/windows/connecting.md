# Connecting to a Windows machine

Ideally, one would never have to log into Windows servers. Alas,
everything does not always work as planned and sometimes one must.

## Required Software

We use Okta ASA to manage users on the Windows machines. As such, you will
need to follow Okta's documentation on installing the `sft` client. There
are docs for both [Mac](https://help.okta.com/en/prod/Content/Topics/Adv_Server_Access/docs/sft-osx.htm)
and [Linux](https://help.okta.com/en/prod/Content/Topics/Adv_Server_Access/docs/sft-ubuntu.htm).

You will also need to install an RDP client. For Mac, you can use homebrew
`brew install freerdp`. For Linux, you'll also probably need something and
that something and associated directions will go here when I figure it out.

I highly recommend setting a screen size for `sft rdp` as the default is nearly
unuseable. To do so, use the command `sft config rdp.screensize 1280x720`
replacing the resolution with whatever you prefer. You can also instead set
`rdp.fullscreen true`, however this hasn't worked well for me but feel
free to experiment.

## Connecting

Currently, we have a firewall rule that prevents access to the Windows manager servers.
In order to connect we first need to turn this off. You can do so by going to the 
[Google Cloud Console Firewall](https://console.cloud.google.com/networking/firewalls)
and enable the rule `winrm-to-managers`, which is disabled by default. Alternatively,
you can enable this by enabling the rule in [terraform](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/environments/windows-ci/firewall.tf#L86).

Once the firewall rule is disabled, you can log in using the `sft` tool on your machine.
The syntax is `sft rdp $servername`. For example,
`sft rdp windows-shared-runners-manager-1` would begin an RDP session to `windows-shared-runners-manager-1`.
The name of the server is in Okta, so a FQDN or IP is not required.
