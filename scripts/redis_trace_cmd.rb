require 'time'

raise 'no input file provided' if ARGV.empty?

def self.filter_key(key)
  key
    .gsub(%r{^(application_rate_limiter:|branch_names:|highlighted-diff-files:merge_request_diffs/|merged_branch_names:|peek:requests:|tag_names:)(.+)}, '\1$PATTERN')
    .gsub(/^cache:gitlab:(diverging_commit_counts_|github-import)(.+)/, 'cache:gitlab:\1$PATTERN')
    .gsub(%r{^cache:gitlab:(show_raw_controller:project|ancestor|branch_count|can_be_resolved_in_ui\?|changelog|commit_count|commit_count_refs/heads/master|commit_count_master|contribution_guide|exists\?|gitignore|gitlab_ci_yml|has_visible_content\?|last_commit_id_for_path|license_blob|license_key|merge_request_template_names|readme_path|root_ref|size|tag_count|xcode_project\?|issue_template_names|rendered_readme|views/shared/projects/_project):(.+)}, 'cache:gitlab:\1:$PATTERN')
    .gsub(/^cache:gitlab:(avatar):([^:]+)/, 'cache:gitlab:\1:$PATTERN')
    .gsub(/([0-9a-f]{40})/, '$LONGHASH')
    .gsub(/([0-9a-f]{32})/, '$HASH')
    .gsub(/([0-9]+)/, '$NUMBER')
end

ARGV.each do |idx_filename|
  filename = idx_filename.gsub(/\.findx$/, "")

  warn filename

  index_keys = []
  index_vals = []

  File.readlines(idx_filename).each do |line|
    offset, timestamp, _length = line.strip.split("|")

    index_keys << offset.to_i
    index_vals << timestamp.to_f
  end

  File.open(filename, 'r:ASCII-8BIT') do |f|
    until f.eof?
      begin
        offset = f.tell
        line = f.readline.strip

        next unless line.match(/^\*([0-9]+)$/)

        args = []

        argc = Regexp.last_match(1).to_i
        argc.times do
          line = f.readline.strip
          raise unless line.match(/^\$([0-9]+)$/)

          len = Regexp.last_match(1).to_i
          args << f.read(len)
          f.read(2) # \r\n
        end

        i = index_keys.bsearch_index { |v| v >= offset }
        if i.nil?
          i = index_keys.size - 1
        elsif i.positive? && index_keys[i] != offset
          # bsearch rounds up, we want to round down
          i -= 1
        end

        cmd = args[0].downcase
        ts = Time.at(index_vals[i]).to_datetime.new_offset(0)
        # kbytes = args.reject(&:nil?).map(&:size).reduce(&:+) / 1024

        raise unless File.basename(filename).match(/^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)$/)

        src_host = Regexp.last_match(1).split('.').map(&:to_i).join('.')
        # src_port = Regexp.last_match(2).to_i
        # dst_host = Regexp.last_match(3).split('.').map(&:to_i).join('.')
        # dst_port = Regexp.last_match(4).to_i

        case cmd
        when "get"
          keys = [args[1]]
        when "exists"
          keys = args[1..]
        when "expire"
          keys = [args[1]]
        when "del"
          keys = args[1..]
        when "mget"
          keys = args[1..]
        when "set"
          keys = [args[1]]
        when "smembers"
          keys = [args[1]]
        when "multi"
          keys = []
        when "exec"
          keys = []
        when "auth"
          keys = []
        when "role"
          keys = []
        when "info"
          keys = []
        when "memory"
          keys = []
        when "replconf"
          keys = []
        when "ping"
          keys = []
        when "sismember"
          keys = [args[1]]
        when "incr"
          keys = [args[1]]
        when "incrby"
          keys = [args[1]]
        when "setex"
          keys = [args[1]]
        when "hmget"
          keys = [args[1]]
        when "hmset"
          keys = [args[1]]
        when "unlink"
          keys = args[1..]
        when "ttl"
          keys = [args[1]]
        when "sadd"
          keys = [args[1]]
        when "hset"
          keys = [args[1]]
        when "publish"
          keys = [args[1]]
        when "eval"
          keys = []
        else
          raise "unknown command #{cmd}"
        end

        keys.each do |key|
          key_pattern = filter_key(key).gsub(' ', '_').gsub('/', ';').gsub(':', ';')
          puts "#{ts.iso8601(9)} #{ts.to_time.to_i % 60} #{cmd} #{src_host} #{key_pattern.inspect} #{key.gsub(' ', '_').inspect}"
        end
      rescue EOFError
      end
    end
  end
end
