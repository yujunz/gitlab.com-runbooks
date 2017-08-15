STORAGE = 'nfs-file02' # Change this to the right storage

# First expire all projects with no subgroups

projects = Project.select("CONCAT('cache:gitlab:exists?:', namespaces.path, '/', projects.path, ':', projects.id) AS cache_key").joins(:namespace).where(repository_storage: STORAGE)

Gitlab::Redis::Cache.with do |redis|
  removed = 0
  projects.in_batches do |relation|
    keys = relation.map { |row| row[:cache_key] }
    redis.del(*keys) if keys.any?
    removed += keys.length
    print '.'
    sleep 0.005
  end
  puts "\n#{removed} keys removed"
end

# Next expire subgroups individually
projects = Project.select("projects.id, namespaces.path, projects.path").joins(:namespace).where(repository_storage: STORAGE)

Gitlab::Redis::Cache.with do |redis|
  removed = 0
  projects.find_each do |project|
    begin
      next unless project.full_path.count('/') > 1
      cache_key = "cache:gitlab:exists?:#{project.full_path}:#{project.id}"
      puts "Expiring #{cache_key}"
      redis.del(cache_key)
      removed += 1
    rescue => e
      puts "Error handling #{project.id}: #{e}"
    end
  end
  puts "\n#{removed} keys removed"
end
