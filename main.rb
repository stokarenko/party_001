require 'bundler'
Bundler.require

require 'pp'

require_relative 'bulk'
require_relative 'processors'
require_relative 'models'

role_slugs = Role::SLUGS + %w[UNKNOWN_ROLE_SLUG]
users_count = 10
users_data = users_count.times.map { |i|
  {
    name: "John Connor #{i}",
    role_slug: role_slugs.sample
  }
}

puts '! SINGULAR MODE !'
inserted_users_count = 0
users_data.each do |user_data|
  inserted_users_count += 1 if User.new(user_data).save
end
puts "Inserted users: #{inserted_users_count}"
puts "SQL queries: #{DBConnection.queries_count}"

puts
puts '! BULK MODE !'
DBConnection.reset_queries_count
inserted_users_count = 0

bulk_handler = UserProcessor::Bulk.new
Bulk.engage(bulk_handler: bulk_handler, collection: users_data) do |user_data|
  inserted_users_count += 1 if User.new(user_data).save
end
puts "Inserted users: #{inserted_users_count}"
puts "SQL queries: #{DBConnection.queries_count}"
