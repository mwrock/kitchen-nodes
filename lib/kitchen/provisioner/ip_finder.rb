module Kitchen
  module Provisioner
    module IpFinder

      def self.for_transport(transport, state)
        transport_string = transport.class.name.split('::').last
        require("kitchen/provisioner/ip_finder/#{transport_string.downcase}")

        connection = transport.connection(state)
        klass = const_get(transport_string)
        object = klass.new(connection)
        object
      end
    end
  end
end
