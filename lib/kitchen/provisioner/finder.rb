module Kitchen
  module Provisioner
    # Locates active IPs that are not localhost
    # there are separate implementations for
    # different kitchen transports
    module Finder
      @finder_registry = {}

      def self.for_transport(transport, state)
        @finder_registry.each do |registered_transport, finder|
          if transport.class <= registered_transport
            return finder.new(transport.connection(state))
          end
        end
      end

      def self.register_finder(transport, finder)
        @finder_registry[transport] = finder
      end
    end
  end
end

require 'kitchen/provisioner/finder/ssh'
require 'kitchen/provisioner/finder/winrm'
