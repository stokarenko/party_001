require 'fiber'

module Bulk
  # FIXME: Why that is bad?
  mattr_accessor :bulk_handler

  class << self
    def engage(bulk_handler:, collection:)
      raise 'Double engage error' if running?

      self.bulk_handler = bulk_handler

      initial_breakpoint = Breakpoint.new
      initial_breakpoint.fibers = collection.map { |item|
        Fiber.new { yield(item) }
      }

      breakpoints = { nil => initial_breakpoint }

      2.times do
        method, breakpoint = breakpoints.shift

        if method
          resume_params = bulk_handler.send(:"breakpoint_#{method}", *breakpoint.bulk_params.transpose)
        end

        breakpoint.fibers.each do |fiber|
          breakpoint_params = fiber.resume(resume_params&.next)
          next unless fiber.alive?

          new_method = breakpoint_params[:method]
          new_breakpoint = breakpoints[new_method] ||= Breakpoint.new

          new_breakpoint.fibers << fiber
          new_breakpoint.bulk_params << breakpoint_params[:singular_params]
        end
      end
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

class Breakpoint
  attr_accessor :fibers, :bulk_params

  def initialize
    self.fibers = []
    self.bulk_params = []
  end
end
