module Kitchen
  module Transport
    class Winrm < Kitchen::Transport::Base
      class Connection < Kitchen::Transport::Base::Connection
        def node_execute(command, &block)
          session.run_powershell_script(command, &block)
        end
      end
    end
  end

  module Provisioner
    module IpFinder
      class Winrm
        def initialize(connection)
          @connection = connection
        end

        def find_ips
          @connection.node_execute("Get-NetIPConfiguration | % { $_.ipv4address.IPAddress}")
        end
      end
    end
  end
end
