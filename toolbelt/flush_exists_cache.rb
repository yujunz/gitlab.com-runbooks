removed = 0

Gitlab::Redis.with do |redis|
  cursor = '0'

  loop do
    cursor, keys = redis.scan(
      cursor,
      match: 'cache:gitlab:exists?:*',
      count: 1000
    )

    redis.del(*keys) if keys.any?

    removed += keys.length

    break if cursor == '0'
  end
end

puts "Removed #{removed} keys"
