module VagrantPlugins
  module ReverseProxy
    module Action
      class WriteNginxConfig
        def initialize(app, env, action)
          @app = app
          @global_env = env[:machine].env
          @provider = env[:machine].provider_name
          @config = @global_env.vagrantfile.config
          @action = action
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

          machines = get_machines()
          # This code is so stupid
          File.open(nginx_site, 'r') do |old|
            File.open(tmp_file, 'w') do |new|
              sm = machines.map {|m| start_marker(m) }
              em = machines.map {|m| end_marker(m) }

              while ln = old.gets() do
                if sm.member?(ln.chomp)
                  until !ln || em.member?(ln.chomp) do
                    ln = old.gets()
                  end
                else
                  new.puts(ln)
                end
              end

              if @action == :add
                machines.each do |m|
                  new.write(start_marker(m)+"\n"+server_block(m)+end_marker(m)+"\n")
                end
              end
            end
          end

          Kernel.system('sudo', 'cp', tmp_file.to_s, nginx_site)
          Kernel.system('sudo', 'service', 'nginx', 'reload')
        end

        def server_block(machine)
          if @config.reverse_proxy.vhosts
            vhosts = @config.reverse_proxy.vhosts
          else
            host = machine.config.vm.hostname || machine.name
            vhosts = {host => host}
          end
          ip = get_ip_address(machine)
          vhosts.collect do |path, vhost|
            # Rewrites are matches literally by nginx, which means
            # http://host:80/... will NOT match http://host/...!
            port_suffix = vhost[:port] == 80 ? '' : ":#{vhost[:port]}"
            <<EOF
location /#{path}/ {
    proxy_set_header Host #{vhost[:host]};
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Base-Url http://$host:$server_port/#{path}/;

    proxy_pass http://#{ip}#{port_suffix}/;
    proxy_redirect http://#{vhost[:host]}#{port_suffix}/ /#{path}/;
}
EOF
          end.join("\n")
        end

        def start_marker(m)
          "# BEGIN #{m.id} #"
        end

        def end_marker(m)
          "# END #{m.id} #"
        end

        # Machine-finding code stolen from vagrant-hostmanager :)
        def get_machines()
          # Collect only machines that exist for the current provider
          @global_env.active_machines.collect do |name, provider|
            if provider == @provider
              begin
                @global_env.machine(name, @provider)
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
