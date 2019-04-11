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

  def default_locale
    DBConnection.execute("SELECT * FROM locales WHERE default is true LIMIT 1")
    Locale.new(id: "locale_default_id")
  end

  def insert_user(user)
    DBConnection.execute("INSERT INTO users #{user.insert_fields} VALUES #{user.insert_values}")
  end

  class Bulk
    extend BreakpointDSL
    extend Memoist

    memoize :default_locale

    breakpoint def role_by_slug(slugs)
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

    breakpoint def insert_user(users)
      insert_values = users.map(&:insert_values).join(', ')
      DBConnection.execute("INSERT INTO users #{users.first.insert_fields} VALUES #{insert_values}")
    end
  end
end
