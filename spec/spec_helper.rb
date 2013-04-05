require File.expand_path("../../lib/klaxon", __FILE__)

RSpec.configure do |c|
  c.mock_with :mocha
end

Mail.defaults do
  delivery_method :test
end

class Alert
  def id
    1
  end

  def self.create(*args)
    self.new
  end

  def self.find(*args)
    self.new
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end
end

class Resque
  def self.enqueue(*args)
  end
end
