module VagrantPlugins
  module ReverseProxy
    class Plugin
      class Config < Vagrant.plugin(2, :config)
        attr_accessor :enabled
        alias_method :enabled?, :enabled

        def initialize
          @enabled = UNSET_VALUE
        end

        def finalize!
          @enabled = false if @enabled == UNSET_VALUE
        end

        def validate(machine)
          errors = _detected_errors

          unless [true, false, UNSET_VALUE].include?(@enabled)
            errors << 'enabled must be a boolean'
          end

          { 'Reverse proxy configuration' => errors.compact }
        end
      end
    end
  end
end
