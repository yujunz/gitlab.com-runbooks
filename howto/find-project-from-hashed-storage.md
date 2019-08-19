# Find a project from its hashed storage path

From time to time you might have a hashed repo path like `/var/opt/gitlab/git-data/repositories/@hashed/00/11/00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff.git` (fake hash, used for examples below) and want to find which project it belongs to.  

There are a variety of ways you can do this, and the most effective will depend on what you've currently got to hand.

## Rails console
Most reliable, and quick if you already have a console open

ProjectRepository.find_by(disk_path:"@hashed/00/11/00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff.git").project

## Config on disk
Not 100% reliable; under some circumstances (https://gitlab.com/gitlab-org/gitlab-ce/issues/48527#note_116019702) the config file might not be populated at the time you need it.  But definitely quick, if you're already on the server

`cat /var/opt/gitlab/git-data/repositories/@hashed/00/11/00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff.git/config` 

## In Kibana

If you're already looking at logs (perhaps responding to abusive access patterns), then in the gitaly logs (pubsub-gitaly-inf-gprd\* index pattern), search for `json.grpc.request.repoPath:"@hashed/00/11/00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff.git"`  In the events returned there should be a json.grpc.request.glProjectPath which is the gitlab project path you're looking for.

