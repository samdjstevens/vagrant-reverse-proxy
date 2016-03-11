# Vagrant Reverse Proxy

This Vagrant plugin automatically installs a reverse proxy
configuration for each of your Vagrant machines.

This means you can access the HTTP interface of your virtual machines
by accessing HTTP on your machine's IP address or DNS hostname, with
a suffix that indicates the VM.

In other words, `http://localhost/my-vm` refers to `http://my-vm/` on
the local machine.  This also works if you access it from an external
machine, even though `my-vm` is a local machine name unknown on the
network.

This plugin currently only supports NGINX, but patches are accepted to
integrate it with other web servers.

## Installation

Install the plugin as usual:

    $ vagrant plugin install vagrant-reverse-proxy

## Usage

First, install nginx and create a configuration as usual.  Then, in
the `server` configuration block for the host you want to use for
proxying, simply put `include "vagrant-proxy-config";` in the file.

If you don't need anything specific, just put the following in
`/etc/nginx/sites-enabled/default`:

    server {
        listen [::]:80 default ipv6only=off;
        # This is the fallback server
        server_name default;
        # Redirect http://localhost/hostname/lalala
        # to http://hostname/lalala
        include "vagrant-proxy-config";
    }

This will load the `/etc/nginx/vagrant-proxy-config` file which is
managed by this plugin.  This file contains `location` statements for
each of your virtual machines, such that `http://localhost/foo` will
proxy to port 80 on the virtual machine with a `config.vm.hostname`
value of `foo`.  This is only done for virtual machines that have
`config.reverse_proxy.enabled` set to `true` in their config.

Whenever you bring up or halt a machine, the plugin updates the proxy
config file and invokes `sudo systemctl reload nginx` to make the
change immediately visible.
