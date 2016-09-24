module Kitchen
  module Transport
    class Winrm < Kitchen::Transport::Base
      # Monkey patch of test-kitchen winrm transport
      # that returns stdout
      class Connection < Kitchen::Transport::Base::Connection
        def node_execute(command, &block)
          unelevated_session.run(command, &block)
        end
      end
    end
  end

  module Provisioner
    module Finder
      # WinRM implementation for returning active non-localhost IPs
      class Winrm
        Finder.register_finder(Kitchen::Transport::Winrm, self)

        def initialize(connection)
          @connection = connection
        end

        def find_ips
          out = @connection.node_execute(
            '(ipconfig) -match \'IPv[46] Address\''
          )
          data = []
          out[:data].each do |out_data|
            stdout = out_data[:stdout]
            data << Regexp.last_match[1] if stdout.chomp =~ /:\s*(\S+)/
          end
          data
        end

        def find_fqdn
          out = @connection.node_execute <<-EOS
            [System.Net.Dns]::GetHostByName($env:computername) |
              FL HostName |
              Out-String |
              % { \"{0}\" -f $_.Split(':')[1].Trim() }
          EOS
          data = ''
          data = out.stdout.chomp unless out.stdout.nil?
          data
        end
      end
    end
  end
end
