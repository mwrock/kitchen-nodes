module Kitchen
  module Provisioner
    # Locates active IPs that are not localhost
    # there are separate implementations for
    # different kitchen transports
    module Finder
      def self.for_transport(transport, state)
        transport_string = transport.class.name.split('::').last
        require("kitchen/provisioner/finder/#{transport_string.downcase}")

        connection = transport.connection(state)
        klass = const_get(transport_string)
        object = klass.new(connection)
        object
      end
    end
  end
end
