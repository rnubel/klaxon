module Klaxon
  class Config
    attr_accessor :recipient_groups 

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
  end
end
