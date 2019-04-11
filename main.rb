# 20:10
# 20:30 - models

require 'bundler'
Bundler.require

AwesomePrint.defaults = {
  indent: 2,
  index: false
}

require_relative 'models'

role_slugs = Role::SLUGS + %w[UNKNOWN_ROLE_SLUG]
users_count = 1
users_data = users_count.times.map { |i|
  {
    name: "John Conner #{i}",
    role_slug: role_slugs.sample
  }
}

inserted_users_count = 0

users_data.each do |user_data|
  inserted_users_count += 1 if User.new(user_data).save
end

puts "Inserted users: #{inserted_users_count}"
puts "SQL queries: #{DBConnection.queries_count}"
