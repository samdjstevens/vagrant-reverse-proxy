module VagrantPlugins
  module ReverseProxy
    module Action
      class WriteNginxConfig
        def initialize(app, env)
          @app = app
          @global_env = env[:machine].env
          @provider = env[:machine].provider_name
          @config = @global_env.vagrantfile.config
        end

        def call(env)
          @app.call(env)

          return unless @config.reverse_proxy.enabled?

          # Determine temp file and target file
          nginx_dir = '/etc/nginx'
          unless File.directory?(nginx_dir)
            env[:ui].error("Could not update nginx configuration: directory '#{nginx_dir}' does not exist.  Continuing without proxy...")
            return
          end
          nginx_site = "#{nginx_dir}/vagrant-proxy-config"
          tmp_file = @global_env.tmp_path.join('nginx.vagrant-proxies')

          env[:ui].info('Updating nginx configuration. Administrator privileges will be required...')

          File.open(tmp_file, 'w') do |f|
            get_machines().each do |m|
              f.write(server_block(m))
            end
          end

          Kernel.system('sudo', 'cp', tmp_file.to_s, nginx_site)
          Kernel.system('sudo', 'service', 'nginx', 'reload')
        end

        def server_block(machine)
          if @config.reverse_proxy.vhosts
            vhosts = @config.reverse_proxy.vhosts
          else
            vhosts = [machine.config.vm.hostname || machine.name]
          end
          ip = get_ip_address(machine)
          vhosts.collect do |vhost| <<EOF
location /#{vhost}/ {
    proxy_set_header Host #{vhost};
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Base-Url http://$host:$server_port/#{vhost}/;

    proxy_pass http://#{ip}/;
    proxy_redirect http://#{vhost}/ /#{vhost}/;
}
EOF
          end.join("\n")
        end

        # Machine-finding code stolen from vagrant-hostmanager :)
        def get_machines()
          # Collect only machines that exist for the current provider
          @global_env.active_machines.collect do |name, provider|
            if provider == @provider
              begin
                m = @global_env.machine(name, @provider)
                m.state.id == :running ? m : nil
              rescue Vagrant::Errors::MachineNotFound
                nil #ignore
              end
            end
          end.compact
        end

        # Also from vagrant-hostmanager
        def get_ip_address(machine)
          ip = nil
          machine.config.vm.networks.each do |network|
            key, options = network[0], network[1]
            ip = options[:ip] if key == :private_network
            break if ip
          end
          ip || (machine.ssh_info ? machine.ssh_info[:host] : nil)
        end
      end
    end
  end
end
