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
          session.open_channel do |channel|

            channel.request_pty
            out = []
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
      end
    end
  end
end
