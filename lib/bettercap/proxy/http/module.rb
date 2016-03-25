# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Proxy
module HTTP

# Base class for transparent proxy modules.
class Module < BetterCap::Pluggable
  @@path    = File.dirname(__FILE__) + '/modules/'
  @@modules = []

  def on_pre_request( request ); end
  def on_request( request, response ); end

  # Return a list of available builtin proxy module names.
  def self.available
    avail = []
    Dir.foreach( @@path ) do |file|
      if file =~ /.rb/
        avail << file.gsub('.rb','')
      end
    end
    avail
  end

  # Check if the module with +name+ is within the builtin ones.
  def self.is_builtin?(name)
    self.available.include?(name)
  end

  # Load the module with +name+.
  def self.load(ctx, opts, name)
    if self.is_builtin?(name)
      ctx.options.proxies.proxy_module = "#{@@path}/#{name}.rb"
    else
      ctx.options.proxies.proxy_module = File.expand_path(name)
    end

    begin
      require ctx.options.proxies.proxy_module

      self.register_options(opts)
    rescue LoadError => e
      raise BetterCap::Error, "Invalid proxy module name '#{name}': #{e.message}"
    end
  end

  # Return a list of registered modules.
  def self.modules
    @@modules
  end

  # Return true if the module is enabled, otherwise false.
  def enabled?
    true
  end

  # Register custom options for each available module.
  def self.register_options(opts)
    self.each_module do |const|
      if const.respond_to?(:on_options)
        const.on_options(opts)
      end
    end
  end

  # Register available proxy modules into the system.
  def self.register_modules
    self.each_module do |const|
      Logger.debug "Registering module #{const}"
      @@modules << const.new
    end
  end

  private

  # Loop each available BetterCap::Proxy::HTTP::Proxy module and yield each
  # one of them for the given code block.
  def self.each_module
      old_verbose, $VERBOSE = $VERBOSE, nil
      Object.constants.each do |klass|
        const = Kernel.const_get(klass.to_s)
        if const.respond_to?(:superclass) and const.superclass == self
          yield const
        end
      end
    ensure
      $VERBOSE = old_verbose
  end
end

end
end
end
