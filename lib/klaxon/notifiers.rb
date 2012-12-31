module Klaxon
  module Notifiers
    def self.default_notifier
      :email
    end
    
    def self.notifiers
      @notifiers ||= {}
    end

    def self.register!(key, notifier)
      notifiers.store(key, notifier)
    end

    def self.[](key)
      notifiers[key]
    end
  end
end

Dir[File.expand_path("../notifiers/*.rb", __FILE__)].each do |f|
  require f
end
