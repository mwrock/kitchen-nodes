module Kitchen
  module Transport
    class Ssh < Kitchen::Transport::Base
      # Monkey patch of test-kitchen ssh transport
      # that returns stdout
      class Connection < Kitchen::Transport::Base::Connection
        def node_execute(command, &block)
          return if command.nil?
          out, exit_code = node_execute_with_exit_code(command, &block)

          if exit_code != 0
            raise Transport::SshFailed,
                  "SSH exited (#{exit_code}) for command: [#{command}]"
          end
          out
        rescue Net::SSH::Exception => ex
          raise SshFailed, "SSH command failed (#{ex.message})"
        end

        # rubocop:disable Metrics/AbcSize
        def node_execute_with_exit_code(command)
          exit_code = nil
          out = []
          session.open_channel do |channel|
            channel.request_pty
            channel.exec(command) do |_ch, _success|
              channel.on_data do |_ch, data|
                out << data
                yield data if block_given?
              end

              channel.on_extended_data do |_ch, _type, data|
                out << data
                yield data if block_given?
              end

              channel.on_request('exit-status') do |_ch, data|
                exit_code = data.read_long
              end
            end
          end
          session.loop
          [out.join("\n"), exit_code]
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end

  module Provisioner
    module Finder
      # SSH implementation for returning active non-localhost IPs
      class Ssh
        IP4REGEX = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/

        Finder.register_finder(Kitchen::Transport::Ssh, self)

        def initialize(connection)
          @connection = connection
        end

        def find_ips
          ips = []
          (0..5).each do
            begin
              ips = run_ifconfig
            rescue Kitchen::Transport::TransportFailed
              ips = run_ip_addr
            end
            return ips unless ips.empty?
            sleep 0.5
          end
          ips
        end

        def find_fqdn
          @connection.node_execute('hostname -f').chomp.chomp
        end

        private

        def run_ifconfig
          response = @connection.node_execute('/sbin/ifconfig -a')
          ips = []
          response.split(/^\S+/).each do |device|
            next if !device.include?('RUNNING') || device.include?('LOOPBACK')
            next if IP4REGEX.match(device).nil?
            ips << IP4REGEX.match(device)[1]
          end
          ips.compact
        end

        def run_ip_addr
          response = @connection.node_execute('/sbin/ip -4 addr show')
          ips = []
          response.split(/^[0-9]+: /).each do |device|
            next if device.include?('LOOPBACK') || device.include?('NO-CARRIER')
            next if device == ''
            found_ips = IP4REGEX.match(device)
            ips << IP4REGEX.match(device)[1] unless found_ips.nil?
          end
          ips.compact
        end
      end
    end
  end
end
