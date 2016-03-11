require_relative 'action/write_nginx_config'

module VagrantPlugins
  module ReverseProxy
    module Action
      include Vagrant::Action::Builtin

      # We (currently) don't distinguish between upping and downing a
      # machine; we always write a complete config with all machines.
      def self.add_machine
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use WriteNginxConfig
        end
      end

      def self.remove_machine
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use WriteNginxConfig
        end
      end
    end
  end
end
