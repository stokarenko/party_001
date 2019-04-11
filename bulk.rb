module Bulk
  # FIXME: Why that is bad?
  mattr_accessor :bulk_handler

  class << self
    def engage(bulk_handler:)
      raise 'Double engage error' if running?

      self.bulk_handler = bulk_handler
      yield
    ensure
      self.bulk_handler = nil
    end

    def handler(singular_handler:)
      running? ? bulk_handler : singular_handler
    end

    def running?
      !!bulk_handler
    end
  end
end
