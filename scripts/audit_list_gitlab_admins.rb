require 'json'
require 'net/http'

# https://gitlab.example.com/api/v4/users
# Private-Token: <your_access_token>
# "Authorization: Bearer <your_access_token>"

class GitLabAdminsUtil
  USERS_API_TOKEN = '<CHANGE-ME>'.freeze
  TOTAL_USERS = 2000
  PAGE_SIZE = 100
  USERS_URI = 'https://dev.gitlab.org/api/v4/users'.freeze
  REPORT_FIELDS = %w[
    id
    username
    email
    name
    state
    is_admin
    created_at
    last_sign_in_at
  ].freeze

  def initialize
    @users_uri = URI(USERS_URI)
  end

  def run
    users = []
    pages = (TOTAL_USERS / PAGE_SIZE) + 1 # integer divide and catch remainder
    (1..pages).each do |page|
      user_page = send_request(page)
      users.concat(user_page)
    end
    report(users)
  end

  def report(users)
    admins = []
    users.each do |user|
      next unless user["is_admin"]

      admins << user
    end

    admins.each do |admin|
      line = ""
      REPORT_FIELDS.each { |f| line << admin[f.to_s].to_s << "," }
      puts line
    end

    puts "total admin users: #{admins.length}"
  end

  def send_request(page_num)
    params = { order_by: "id", per_page: PAGE_SIZE, page: page_num }
    @users_uri.query = URI.encode_www_form(params)
    req = Net::HTTP::Get.new(@users_uri)
    req['Authorization'] = "Bearer #{USERS_API_TOKEN}"
    res = Net::HTTP.start(@users_uri.hostname, @users_uri.port, use_ssl: true) { |http| http.request(req) }
    JSON.parse(res.body)
  end
end

my_util = GitLabAdminsUtil.new
my_util.run
