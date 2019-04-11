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

    def role_by_slug(*params)
      Fiber.yield(
        method: :role_by_slug,
        singular_params: params
      )
    end

    def breakpoint_role_by_slug(slugs)
      normalized_slugs = slugs.uniq
      query_slugs = normalized_slugs.map { |s| "'#{s}'" }.join(', ')

      DBConnection.execute("SELECT * FROM roles WHERE slug IN '#{query_slugs}'")

      roles = normalized_slugs.map { |slug|
        Role.new(id: "role_#{slug}_id", slug: slug) if Role::SLUGS.include?(slug)
      }.compact.index_by(&:slug)

      Enumerator.new do |enum|
        slugs.each do |slug|
          enum << roles[slug]
        end
      end
    end
  end
end
