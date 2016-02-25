module VagrantPlugins
  module ReverseProxy
    class Plugin < Vagrant.plugin(2)
        name 'Reverse Proxy'

      description <<-DESC
        This plugin automatically manages a reverse proxy
        configuration in your host machine's web server, which makes
        it easy to access the web servers of your guest machines.

        This is safer and easier than making the guest machine
        completely available on the outside network.
      DESC

      config :reverse_proxy do
        require_relative 'config'
        Config
      end

      action_hook(:reverse_proxy, :machine_action_up) do |hook|
        hook.append(lambda{|*x| puts "Machine is up"})
      end

      action_hook(:reverse_proxy, :machine_action_suspend) do |hook|
        hook.append(lambda{|*x| puts "Machine is suspended"})
      end

      action_hook(:reverse_proxy, :machine_action_resume) do |hook|
        hook.append(lambda{|*x| puts "Machine is resumed"})
      end

      action_hook(:reverse_proxy, :machine_action_halt) do |hook|
        hook.append(lambda{|*x| puts "Machine is halted"})
      end
    end
  end
end
