# frozen_string_literal: true

# RubyGems
require 'bundler'
Bundler.require

class Request < Rack::Request
end

class Response < Rack::Response
end

class Application
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

      # Router execution code here

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

app = Application.new
app.run