# Clearing sessions for anonymous users

The following script will clear all sessions from redis that have no
current user attached.

The script can be run from a rails console, and back off while a
BGSAVE is running.

```ruby
#!/usr/bin/env ruby
scanned_keys = 0
deleted_keys = 0
session_key_pattern = "session:gitlab:*"
log_batch_size = 10_000.0
previous_printed_batch = 1
wait_time = 10.seconds
last_save_check = Time.at(0)

Gitlab::Redis::SharedState.with do |redis|
  cursor, keys = redis.scan(0, match: session_key_pattern)

  begin
    if last_save_check < Time.now - 1.second
      while redis.info('persistence')['rdb_bgsave_in_progress'] == '1'
        puts "BGSAVE in progress, waiting #{wait_time}"
        sleep(wait_time)
      end
      last_save_check = Time.now
    end

    keys = keys.to_a
    values = keys.any? ? Array(redis.mget(keys)) : []

    keys_to_delete = []
    values.each_with_index do |session_data, index|
      session_data = Marshal.load(session_data)

      unless session_data['warden.user.user.key']
        keys_to_delete << keys[index]
      end
    end

    redis.del(*keys_to_delete) if keys_to_delete.any?

    scanned_keys += keys.count
    deleted_keys += keys_to_delete.count

    if (scanned_keys / log_batch_size).ceil > previous_printed_batch
      previous_printed_batch = (scanned_keys / log_batch_size).ceil
      puts "scanned: #{scanned_keys} - deleted: #{deleted_keys}"
    end

    cursor, keys = redis.scan(cursor, match: session_key_pattern)
  end while cursor.to_i != 0

  puts "--- All done!"
  puts "scanned: #{scanned_keys} - deleted: #{deleted_keys}"
end
```
