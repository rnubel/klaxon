require File.expand_path("../../lib/klaxon", __FILE__)

RSpec.configure do |c|
  c.mock_with :mocha
end

Mail.defaults do
  delivery_method :test
end

class Alert
  def self.create(*args)
  end

  def self.find(*args)
  end
end

class Resque
  def self.enqueue(*args)
  end
end
