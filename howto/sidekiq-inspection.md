# Poking around at sidekiq's running state

Here in are some pre-packaged bits of Ruby for poking around (non-destructively) in what's running on Sidekiq.  

## Prep/connection

On any sidekiq node, run:

`sudo gitlab-rails console`

After it starts, run:

`workers = Sidekiq::Workers.new`

which we'll assume for all the other snippets

The snippets look into (I assume) redis to can see what's running, so this is a global view and can be run from any sidekiq node.  You could also, with some effort, connect from a redis node (or anywhere else that has some common gems installed, and network connectivity to redis). 

Initial details borrowed from https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/administration/troubleshooting/sidekiq.md; that has some other useful context if you need to go further.

All snippets are single-line, for ease of up-arrow + editing in the console.  I apologise in advance for the difficulty in reading them.

Note also that workers.each is an instantaneous view, so on staging it sometimes reports nothing (because no jobs are running that instant).  On gprd, probably should always report *something*, but may vary.


## Quick view

Warning: on prod, there is a lot of data.  This is an exploratory diagnostic only to see that your connection is working:

`workers.each { |process_id, thread_id, work| puts "#{process_id} #{work}"}; nil`

Note interesting data (IMO):
* work["payload"]["class"]
* work["payload"]["created_at"]
* work["payload"]["enqueued_at"]
* work["run_at"]
* work["payload"]["jid"] #Job id, useful for killing

## Report run_at (when they started) in human terms
`workers.each { |process_id, thread_id, work| puts "#{Time.at(work["run_at"])}: #{process_id} #{work["payload"]["class"]}"}; nil`

## Runtime:
`workers.each { |process_id, thread_id, work| puts "#{process_id} #{work["payload"]["class"]}:#{Time.now.to_i-work["run_at"]}s"}; nil`

### Selective runtime; modify 10 at end for min number of seconds
`workers.each { |process_id, thread_id, work| runtime = Time.now.to_i-work["run_at"]; puts "#{process_id} #{work["payload"]["class"]}:#{runtime}s" if runtime > 10}; nil`

### Find just the longest running job:
`workers.map { |process_id, thread_id, work| runtime = Time.now.to_i-work["run_at"]; { pid: process_id, class: work["payload"]["class"], runtime: runtime } }.sort { |a,b| b[:runtime] <=> a[:runtime] }.first`

### Find the x-longest running jobs (10 is the number)
`workers.map { |process_id, thread_id, work| runtime = Time.now.to_i-work["run_at"]; { pid: process_id, class: work["payload"]["class"], runtime: runtime } }.sort { |a,b| b[:runtime] <=> a[:runtime] }[0..10].each { |j| puts "#{j[:pid]}: #{j[:class]} #{j[:runtime]}s" }; nil`

