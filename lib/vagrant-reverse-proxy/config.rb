module VagrantPlugins
  module ReverseProxy
    class Plugin
      class Config < Vagrant.plugin(2, :config)
        attr_accessor :enabled, :vhosts, :nginx_config_file
        alias_method :enabled?, :enabled

        def initialize
          @enabled = UNSET_VALUE
          @vhosts = UNSET_VALUE
          @nginx_config_file = UNSET_VALUE
        end

        def finalize!
          @enabled = false if @enabled == UNSET_VALUE
          if @vhosts == UNSET_VALUE
            @vhosts = nil
          elsif @vhosts.is_a?(Array)
            # Convert to canonical hash form of
            # {path => {:host => name, :port => num}}
            vhosts_hash = {}
            @vhosts.each {|entry| vhosts_hash[entry] = {:host => entry, :port => 80} }
            @vhosts = vhosts_hash
          elsif @vhosts.is_a?(Hash)
            @vhosts.each do |key, value|
              if (value.is_a?(String))
                @vhosts[key] = {:host => value, :port => 80}
              else
                value[:port] ||= 80
              end
            end
          end
          if @nginx_config_file == UNSET_VALUE
            @nginx_config_file = nil
          end
        end

        def validate(machine)
          errors = _detected_errors

          unless [true, false, UNSET_VALUE].include?(@enabled)
            errors << 'enabled must be a boolean'
          end

          if @vhosts.instance_of?(Array)
            @vhosts.each do |vhost|
              unless (vhost.is_a?(String) || vhost.is_a?(Hash))
                errors << "vhost #{vhost} is not a string or hash"
              end
            end
          elsif @vhosts.instance_of?(Hash)
            @vhosts.each do |path, vhost|
              unless path.is_a?(String)
                errors << "vhost path `#{path}' is not a string"
              end
              unless vhost.is_a?(String) || vhost.is_a?(Hash)
                errors << "Vhost `#{vhost}' for path `#{path}' is not a string or hash"
              else
                if vhost.is_a?(Hash) && !vhost[:host]
                  errors << "Vhost `#{vhost}' for path `#{path}' has no :host key"
                end
              end
            end
          elsif @vhosts != nil && @vhosts != UNSET_VALUE
            errors << 'vhosts must be an array of hostnames, a string=>string hash or nil'
          end

          unless @nginx_config_file.instance_of?(String) || @nginx_config_file == nil || @nginx_config_file == UNSET_VALUE
            errors << 'nginx_config_file must be a string'
          end

          { 'Reverse proxy configuration' => errors.compact }
        end
      end
    end
  end
end
