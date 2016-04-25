# frozen_string_literal: true

# RubyGems
require 'bundler'
Bundler.require

class Request < Rack::Request
end

class Response < Rack::Response
end

module Routable
  def define_routes(&block)
    instance_exec(&block)
  end

  def route!
    send "#{request.request_method} #{request.path}".to_sym
  end

  def map_method(verb, path, &block)
    define_singleton_method("#{verb} #{path}", &block)
  end

  def get(path, &block)
    map_method('GET', path, &block)
  end

  def post(path, &block)
    map_method('POST', path, &block)
  end

  def request
    @request
  end

  def response
    @response
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
    handler = detect_rack_handler(@options[:rack_handler_name] || 'WEBrick')
    app = lambda do |env|
      @request = Request.new(env)
      @response = Response.new

      route!

      @response
    end

    handler.run app
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

app.define_routes do
  get '/hello' do
    response.header['Content-Type'] = 'text/html'
    response.body = ['hello']
  end
end

app.run
