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
        hook.append(Action.add_machine)
      end

      action_hook(:reverse_proxy, :machine_action_suspend) do |hook|
        hook.append(Action.remove_machine)
      end

      action_hook(:reverse_proxy, :machine_action_resume) do |hook|
        hook.append(Action.add_machine)
      end

      action_hook(:reverse_proxy, :machine_action_halt) do |hook|
        hook.append(Action.remove_machine)
      end

      action_hook(:reverse_proxy, :machine_action_reload) do |hook|
        hook.append(Action.add_machine)
      end
    end
  end
end
