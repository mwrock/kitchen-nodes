module Kitchen
  module Transport
    class Ssh < Kitchen::Transport::Base
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

        def node_execute_with_exit_code(command, &block)
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

              channel.on_request("exit-status") do |_ch, data|
                exit_code = data.read_long
              end
            end
          end
          session.loop
          [out.join("\n"), exit_code]
        end
      end
    end
  end

  module Provisioner
    module IpFinder
      class Ssh
        def initialize(connection)
          @connection = connection
        end

        def find_ips
          ips = []
          retry_count = 0

          while retry_count < 5
            begin
              ips = run_ifconfig
            rescue Kitchen::Transport::TransportFailed
              ips = run_ip_addr
            end
            return ips unless ips.empty?
            retry_count += 1
            sleep 0.5
          end
        end

        def run_ifconfig
          response = @connection.node_execute("ifconfig -a")
          ips = []
          start_token = "inet addr:"
          response.split(/^\S+/).each do |device|
            if device.include?("RUNNING") && !device.include?("LOOPBACK")
              start_idx = device.index(start_token)
              start_idx += start_token.length unless start_idx.nil?
              end_idx = device.index(" ", start_idx) unless start_idx.nil?
              ips << device[start_idx,end_idx - start_idx] unless end_idx.nil?
            end
          end
          ips
        end

        def run_ip_addr
          response = @connection.node_execute("ip -4 addr show")
          ips = []
          start_token = "inet "
          response.split(/[0-9]+: /).each do |device|
            unless device.include?("LOOPBACK") || device.include?("NO-CARRIER")
              start_idx = device.index(start_token)
              start_idx += start_token.length unless start_idx.nil?
              end_idx = device.index("/", start_idx) unless start_idx.nil?
              ips << device[start_idx,end_idx - start_idx] unless end_idx.nil?
            end
          end
          ips
        end
      end
    end
  end
end
