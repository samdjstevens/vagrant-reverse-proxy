# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-reverse-proxy/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-reverse-proxy"
  spec.version       = VagrantPlugins::ReverseProxy::VERSION
  spec.authors       = ["Peter Bex"]
  spec.email         = ["peter@codeyellow.nl"]
  spec.summary       = %q{A vagrant plugin that adds reverse proxies for your VMs}
  spec.description   = %q{This plugin manages reverse proxy configuration (currently nginx-only) so you can reach your Vagrant VM's web servers externally without having to set up bridge networking.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
