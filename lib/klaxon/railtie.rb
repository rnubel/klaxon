require 'rails/railtie'

module Klaxon
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../../tasks/klaxon.rake", __FILE__)
    end
  end
end
