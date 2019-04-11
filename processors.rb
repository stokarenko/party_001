module UserProcessor
  extend self

  def self.handler
    ::Bulk.handler(singular_handler: self)
  end

  def role_by_slug(slug)
    DBConnection.execute("SELECT * FROM roles WHERE slug = '#{slug}' LIMIT 1")
    return unless Role::SLUGS.include?(slug)

    Role.new(id: "role_#{slug}_id", slug: slug)
  end

  class Bulk
    include UserProcessor
  end
end
