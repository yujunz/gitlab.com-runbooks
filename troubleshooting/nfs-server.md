# NFS Server down

## First and foremost

*Don't Panic*

## Symptoms

* skyrocket increase of load in both workers due to IOWait. Should be over 200, all of them.
  * [CheckMK Link](https://checkmk.gitlap.com/gitlab/check_mk/index.py?start_url=%2Fgitlab%2Fcheck_mk%2Fview.py%3Ffilled_in%3Dfilter%26_transid%3D1461327179%252F1331678182%26host_address%3D%26host_address_prefix%3Dyes%26opthost_group%3D%26hostgroups%3D%26opthost_contact_group%3D%26optservice_group%3D%26optservice_contact_group%3D%26svc_last_state_change_from%3D%26svc_last_state_change_from_range%3D3600%26svc_last_state_change_until%3D%26svc_last_state_change_until_range%3D3600%26svc_last_check_from%3D%26svc_last_check_from_range%3D3600%26svc_last_check_until%3D%26svc_last_check_until_range%3D3600%26host_tag_0_grp%3D%26host_tag_0_op%3D%26host_tag_0_val%3D%26host_tag_1_grp%3D%26host_tag_1_op%3D%26host_tag_1_val%3D%26host_tag_2_grp%3D%26host_tag_2_op%3D%26host_tag_2_val%3D%26host_regex%3Dworker%26hostalias%3D%26hst0%3Don%26hst1%3Don%26hst2%3Don%26hstp%3Don%26is_summary_host%3D-1%26is_host_in_notification_period%3D-1%26service_regex%3DCPU%2BLOAD%26service_display_name%3D%26service_output%3D%26check_command%3D%26st0%3Don%26st1%3Don%26st2%3Don%26st3%3Don%26stp%3Don%26hdst0%3Don%26hdst1%3Don%26hdst2%3Don%26hdst3%3Don%26hdstp%3Don%26is_service_acknowledged%3D-1%26is_service_scheduled_downtime_depth%3D-1%26is_service_in_notification_period%3D-1%26svc_notif_number_from%3D%26svc_notif_number_until%3D%26is_in_downtime%3D-1%26is_service_staleness%3D-1%26is_service_active_checks_enabled%3D-1%26is_service_notifications_enabled%3D-1%26is_service_is_flapping%3D-1%26is_aggr_service_used%3D-1%26site%3D%26is_host_favorites%3D-1%26is_service_favorites%3D-1%26search%3DSearch%26selection%3D8f61d67e-d664-4264-9661-8297a5b2d651%26view_name%3Dsearchsvc)
  * ![Sample High Load on Worker](img/load-worker1.jpg)
* Skyrocket increase of load in NFS server due to IOWait. Again, over 200.
  * [CheckMK Link for backend4](https://checkmk.gitlap.com/gitlab/pnp4nagios/index.php/graph?host=backend4.cluster.gitlab.com&srv=CPU_load&theme=multisite&baseurl=../check_mk/)
  * ![Sample High Load on NFS Server](img/load-nfs.jpg)
* Drop of context switches in NF server - no actual work being done.
  * [CheckMK Link](https://checkmk.gitlap.com/gitlab/pnp4nagios/index.php/graph?host=backend4.cluster.gitlab.com&srv=Kernel_Context_Switches&theme=multisite&baseurl=../check_mk/)
  * ![Sample Low Context Switches NFS Server](img/context-switches_nfs.jpg)
* Drop of IOPS in NFS Server.
  * [Look for read/write_iops_sec](https://checkmk.gitlap.com/gitlab/pnp4nagios/index.php/graph?host=backend4.cluster.gitlab.com&srv=IOSTAT_gitlab_vg-gitlab_var&theme=multisite&baseurl=../check_mk/)
  * ![Sample Low read IOPS in NFS Server](img/ioread_wait_nfs.jpg)

## Possible checks

* SSHing into the NFS server does not provide a prompt due to the load.
  * `ssh 104.209.211.54`
* Workers will show that the git NFS drive is not mounted (empty result)
  * `bundle exec knife ssh -a ipaddress name:worker1.cluster.gitlab.com 'mount | grep /var/opt/gitlab/git-data'`

## Resolution

* Restart the NFS server in the azure console
  * [Azure Link](https://portal.azure.com/#resource/subscriptions/c802e1f4-573f-4049-8645-4f735e6411b3/resourceGroups/backend4-cluster-gitlab-com/providers/Microsoft.ClassicCompute/virtualMachines/backend4-cluster-gitlab-com)
  * Hit "Restart"
  * NOTE: the azure portal will show the host as down and will recommend stopping it completely, ignore Azure recommendations.
  * This will take roughly
* Once it starts replying (you could ssh to test) mount the NFS in all the workers
  * `bundle exec knife ssh -a ipaddress role:gitlab-cluster-worker 'sudo mount /var/opt/gitlab/git-data'`

## Expectation

* All workers should remount the partition without complaining (some may have it mounted already)
* You should see an increase in NFS retrans
  * ![NFS retransmissions](img/retrans-worker1.jpg)
