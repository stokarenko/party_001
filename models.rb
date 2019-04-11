module DBConnection
  mattr_accessor :queries_count
  self.queries_count = 0

  class << self
    def execute(query)
      puts "SQL QQUERY: #{query}"
      self.queries_count += 1
    end

    def reset_queries_count
      self.queries_count = 0
    end
  end
end

class Locale
  attr_accessor :id

  def self.default
    DBConnection.execute("SELECT * FROM locales WHERE default is true")
    new(id: "locale_default_id")
  end

  def initialize(id:)
    self.id = id
  end
end

class Role
  SLUGS = %w[admin manager guest].freeze

  attr_accessor :id, :slug

  def self.find_by_slug(slug)
    DBConnection.execute("SELECT * FROM roles WHERE slug = '#{slug}'")
    return unless SLUGS.include?(slug)

    new(id: "role_#{slug}_id", slug: slug)
  end

  def initialize(id:, slug:)
    self.id, self.slug = id, slug
  end
end

class User
  attr_accessor :name, :role_slug, :role_id, :locale_id

  def initialize(name:, role_slug:)
    self.name, self.role_slug = name, role_slug
  end

  def save
    self.role_id = Role.find_by_slug(role_slug)&.id
    return false unless role_id

    self.locale_id = Locale.default.id

    insert
    true
  end

  private

  def insert
    DBConnection.execute("IMSERT INTO users #{insert_fields} VALUES #{insert_values}")
  end

  def insert_fields
    fields = %w[name role_id locale_id].join(', ')
    "(#{fields})"
  end

  def insert_values
    values = [name, role_id, locale_id].map { |v| "'#{v}'" }.join(', ')
    "(#{values})"
  end
end
