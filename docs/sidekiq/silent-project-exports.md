From time to time, for legal reasons, we are required to export projects without the owner being aware.  Requests for this will come through Legal, and will have suitable looking authorizations (e.g. subpeonas)

While it is possible for an admin to create an export and it won't *email* the owner, it will be visible in the UI while the export exists, and the owner might notice this and infer something is going on.

To avoid this we can do it by hand with some effort.  

* Open a session to the rails console with ```ssh gprd-rails-console```
* Find the user (we should have been given the name as part of the request): ```u = User.find_by(username: 'USERNAME')```
* List their projects, assuming we want all of them: 
```
u.projects.each do |p|
  puts "#{p.path}: #{p.repository_storage} #{p.repository.path_to_repo}"
end
```
* Keep note of the and storage node, you'll need that soon.
* Export the projects:
```
u.projects.each do |p|
  pts = Gitlab::ImportExport::ProjectTreeSaver.new(project: p, current_user: u, shared: p.import_export_shared)
  pts.save
  dir = "#{u.username}/#{p.path}"
  puts "mkdir -p #{dir}; cp #{pts.full_path} #{dir}/project.json"
end
```
* This will output a bunch of commands (mkdir + cp) to copy the generated project.json files to your homedir.  In a root shell on the console server (console-01-sv-gprd), run them.
* Copy the directory from your homedir (it will be the username) to the appropriate target location.
* You don't need the console anymore, but you will need the output of the first loop.
* For each identifed file-server, ssh to it and copy the identified repository, and the wiki.git variant (same hashed path, but .wiki.git replaces .git)
* Copy these to the target location as well, preferably into the same directory structure as was created for the project.json

Adjust as necessary if there is only one (or a subset) of projects necessary.  Take care around *large* repositories, or large project exports as well.
