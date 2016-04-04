# frozen_string_literal: true

# RubyGems
require 'bundler'
Bundler.require

class Request < Rack::Request
end

class Response < Rack::Response
end

module Routable
  def route!
    send "#{request.request_method} #{request.path}".to_sym
  end

  def get(path, &block_p)
    define_singleton_method("GET #{path}") { block_p.call }
  end

  def request
    @request
  end

  def response
    @response
  end

  def method_missing
    [404, {'Content-Type' => 'text/html'}, ['Not Found']]
  end
end

class Application
  include ::Routable

  def initialize(options = {})
    @options = options
    if ARGV.any?
      require 'optparse'
      OptionParser.new do |opt|
        opt.on('-s string') { |val| @options[:rack_handler_name] = val }
      end.parse(ARGV.dup)
    end
  end

  def run
    @options ||= {}
    handler = detect_rack_handler(@options[:rack_handler_name] || 'WEBrick')
    app = lambda do |env|
      @request = Request.new(env)
      @response = Response.new

      route!
    end

    handler.run app
  end

  def define_routes
    yield self
  end

  private

  def detect_rack_handler(name)
    name = name.downcase.to_sym
    Rack::Handler.get(name)
  end
end

#
# Example
#

app = Application.new

app.define_routes do |app|
  app.get '/hello' do
    app.response.header['Content-Type'] = 'text/html'
    app.response.body = ['hello']
    app.response
  end
end

app.run
