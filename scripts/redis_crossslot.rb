require 'digest/crc16'
require 'json'

raise 'no input file provided' if ARGV.empty?

def self.filter_key(key)
  key
    .gsub(%r{^(highlighted-diff-files:merge_request_diffs/)(.+)}, '\1$PATTERN')
    .gsub(%r{^(show_raw_controller:project|ancestor|can_be_resolved_in_ui\?|commit_count_refs/heads/master|commit_count_master|exists\?|last_commit_id_for_path|merge_request_template_names|root_ref|xcode_project\?|issue_template_names|views/shared/projects/_project|application_rate_limiter|branch_names|merged_branch_names|peek:requests|tag_names|branch_count|tag_count|commit_count|size|gitignore|rendered_readme|readme_path|license_key|contribution_guide|gitlab_ci_yml|changelog|license_blob|avatar|metrics_dashboard_paths|has_visible_content\?):(.+)}, '\1:$PATTERN')
    .gsub(%r{^cache:gitlab:(diverging_commit_counts_|github-import/)(.+)}, 'cache:gitlab:\1$PATTERN')
    .gsub(/([0-9a-f]{40})/, '$LONGHASH')
    .gsub(/([0-9a-f]{32})/, '$HASH')
    .gsub(/([0-9]+)/, '$NUMBER')
end

# https://github.com/zachhale/ruby-crc16

def self.hash_slot(key)
  s = key.index "{"
  if s
    e = key.index "}", s + 1
    key = key[s + 1..e - 1] if e && e != s + 1
  end
  Digest::CRC16.checksum(key) % 16384
end

ARGV.each do |idx_filename|
  filename = idx_filename.gsub(/\.findx$/, "")

  warn filename

  in_tx = false
  tx_keys = []
  tx_cmds = []

  File.open(filename, 'r:ASCII-8BIT') do |f|
    until f.eof?
      begin
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

        extra = nil

        cmd = args[0].downcase

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

        in_tx = true if cmd == "multi"

        if cmd == "exec"
          keys += tx_keys
          extra = tx_cmds

          in_tx = false
          tx_keys = []
          tx_cmds = []
        end

        if in_tx && !%w[multi exec].include?(cmd)
          tx_keys += keys
          tx_cmds << args
        end

        if keys.size > 1 && keys.map { |k| hash_slot(k) }.uniq.size != 1
          # data = { args: args, extra: extra }
          data = { cmd: cmd, keys: keys, patterns: keys.map { |k| filter_key(k) }.uniq, tx_ops: extra&.map { |a| a[0] } }
          puts data.to_json
        end
      rescue EOFError
      end
    end
  end
end
