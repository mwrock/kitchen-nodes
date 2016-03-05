require 'serverspec'
require 'json'

if RUBY_PLATFORM =~ /mingw/
  set :backend, :cmd
  set :os, family: 'windows'
else
  set :backend, :exec
end

describe 'other node' do
  let(:node) do
    JSON.parse(
      IO.read(File.join(ENV['TEMP'] || '/tmp', 'kitchen/other_node.json'))
    )
  end
  let(:ip) { node['automatic']['ipaddress'] }
  let(:fqdn) { node['automatic']['fqdn'] }
  let(:connection) do
    if RUBY_PLATFORM =~ /mingw/
      require 'winrm'
      ::WinRM::WinRMWebService.new(
        "http://#{ip}:5985/wsman",
        :plaintext,
        user: 'vagrant',
        pass: 'vagrant',
        basic_auth_only: true
      )
    else
      Net::SSH.start(
        ip,
        'vagrant',
        password: 'vagrant',
        paranoid: false
      )
    end
  end

  it 'has an non localhost ip' do
    expect(ip).not_to eq('127.0.0.1')
  end

  it 'has a valid ip' do
    expect(ip).to match(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
  end

  # Skip this test on the 2008 box bc its not sysprepped....
  unless ENV['computername'] =~ /VAGRANT\-2008R2/i
    describe command('hostname') do
      its(:stdout) { should_not match(/#{Regexp.quote(fqdn)}/) }
    end
  end

  if RUBY_PLATFORM =~ /mingw/
    it 'has a computername matching node fqdn' do
      expect(connection.run_cmd('hostname').stdout.chomp).to eq(fqdn)
    end
  else
    it 'has a computername matching node fqdn' do
      connection.open_channel do |channel|
        channel.request_pty
        channel.exec('hostname') do |_ch, _success|
          channel.on_data do |_ch, data|
            expect(data.chomp).to eq(fqdn)
          end
        end
      end
      connection.loop
    end
  end
end
