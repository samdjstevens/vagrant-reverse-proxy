require_relative 'action/write_nginx_config'

module VagrantPlugins
  module ReverseProxy
    module Action
      include Vagrant::Action::Builtin

      def self.add_machine
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use(ConfigValidate)
          builder.use(WriteNginxConfig, :add)
        end
      end

      def self.remove_machine
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use(ConfigValidate)
          builder.use(WriteNginxConfig, :remove)
        end
      end
    end
  end
end
