module Klaxon
  class Config
    attr_accessor :logger, :queue, :recipient_groups, :from_address

    # notify [r1, r2], :of => filters, :by => notifier 
    def notify(recipients, parameters)
      self.recipient_groups ||= []

      recipients = [recipients] unless recipients.is_a? Array
      filters   = parameters[:of] || {}
      notifier  = parameters[:by] || Klaxon::Notifiers.default_notifier

      group_config = { :recipients  => recipients,
                       :notifier    => notifier}.merge(filters)
      self.recipient_groups.push(group_config)
    end

    def queue
      @queue ||= :high
    end

    def logger
      @logger ||= Rails.logger
    rescue NameError, NoMethodError => e
      ok =  [ /^uninitialized constant Rails$/,
              /^undefined method `logger'/
            ].any?{|regex| e.message =~ regex }
      raise unless ok
      @logger ||= Logger.new($stderr)
    end
  end
end
