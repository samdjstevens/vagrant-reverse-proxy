module VagrantPlugins
  module ReverseProxy
    module Action
      class WriteNginxConfig
        def initialize(app, env, action)
          @app = app
          @action = action
        end

        def call(env)
          @app.call(env)

          # Does this make much sense?  What if we disable it later
          # for one specific machine?  Then, the config should still
          # be removed.
          return unless env[:machine].config.reverse_proxy.enabled?

          # Determine temp file and target file
          nginx_config_file = env[:machine].config.reverse_proxy.nginx_config_file || '/etc/nginx/vagrant-proxy-config'

          # Get the directory of the config file
          nginx_config_dir = File.dirname(nginx_config_file)

          unless File.directory?(nginx_config_dir)
            env[:ui].error("Could not update nginx configuration: directory '#{nginx_config_dir}' does not exist.  Continuing without proxy...")
            return
          end

          tmp_file = env[:machine].env.tmp_path.join('nginx.vagrant-proxies')

          env[:ui].info('Updating nginx configuration. Administrator privileges will be required...')

          sm = start_marker(env[:machine])
          em = end_marker(env[:machine])

          # This code is so stupid: We write a tmp file with the
          # current config, filtered to exclude this machine.  Later,
          # we put this machine's config back in.  It might have
          # changed, and might not have been present originally.
          File.open(tmp_file, 'w') do |new|
            begin
              File.open(nginx_config_file, 'r') do |old|
                # First, remove old entries for this machine.
                while ln = old.gets() do
                  if sm == ln.chomp
                    # Skip lines until we find EOF or end marker
                    until !ln || em == ln.chomp do
                      ln = old.gets()
                    end
                  else
                    # Keep lines for other machines.
                    new.puts(ln)
                  end
                end
              end
            rescue Errno::ENOENT
              # Ignore errors about the source file not existing;
              # we'll create it soon enough.
            end

            if @action == :add # Removal is already (always) done above
              # Write the config for this machine
              if env[:machine].config.reverse_proxy.enabled?
                new.write(sm+"\n"+server_block(env[:machine])+em+"\n")
              end
            end
          end

          # Finally, copy tmp config to actual config
          Kernel.system('sudo', 'cp', tmp_file.to_s, nginx_config_file)

          # And reload nginx
          nginx_reload_command = env[:machine].config.reverse_proxy.nginx_reload_command || 'sudo nginx -s reload'
          Kernel.system(nginx_reload_command)
        end

        def server_block(machine)
          if machine.config.reverse_proxy.vhosts
            vhosts = machine.config.reverse_proxy.vhosts
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
server {
    server_name #{vhost[:host]};
    location / {
        proxy_set_header Host #{vhost[:host]};
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://#{ip}#{port_suffix}/;
    }
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
