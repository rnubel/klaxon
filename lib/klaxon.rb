require "klaxon/version"
require "klaxon/notifiers"
require "klaxon/config"
require "klaxon/railtie"

require "active_record/errors" 

# Library for escalating and logging errors.
module Klaxon
  # Raise an alarm and escalate as configured in etc/klaxon.yml.
  # @param [Exception] exception exception object if one was raised
  # @option options :severity severity of this notication. Should be low,
  # medium, high, critical, or notification (arbitrary, though)
  # @option options :message any info attached to this notification
  # @option options :category totally arbitrary, but escalation can be configured based on
  # this field.
  # @return [Alert] the created alert
  def self.raise_alert(exception, options={})
    alert = Alert.create(
      :exception => exception && exception.to_s,
      :backtrace => exception && exception.backtrace.join("\n"),
      :severity => options[:severity].to_s || "",
      :message => options[:message].to_s || "",
      :category => options[:category].to_s || "uncategorized"
    )

    Resque.enqueue(NotificationJob, alert.id)

    alert
  end

  # Synonyms for raise_alert when no exception is involved.
  def self.notify(options)
    self.raise_alert(nil, {:severity => "notification"}.merge(options))
  end

  def self.warn!(options)
    self.raise_alert(nil, options)
  end

  # Watch the yielded block for exceptions, and log one if it's raised.
  def self.watch(options={})
    begin
      yield
    rescue => e
      raise_alert(e, options)
    end
  end

  # Same as watch, but re-raises the exception after catching it.
  def self.watch!(options={})
    begin
      yield
    rescue => e
      raise_alert(e, options)
      raise e
    end
  end

  # Determine the recipients per notification method for a particular alert.
  def self.recipients(alert)
    # Each recipient group should look like (where the filter values are regexps):
    # - category: .*
    # severity: (critical|high)
    # recipients:
    # - rnubel@test.com
    # notifier: email
    recipients_per_notifier = config.recipient_groups.inject({}) do |rec_lists, group|
      if alert_matches_group(alert, group)
        notifier = group[:notifier] || Klaxon::Notifiers.default_notifier
        rec_lists[notifier] ||= []
        rec_lists[notifier] += group[:recipients]
      end

      rec_lists
    end

    recipients_per_notifier.each do |k, v| v.uniq!; v.sort! end # Filter duplicates and sort for sanity
  end

  def self.configure
    @config = nil
    yield config
  end

  def self.config
    @config ||= Klaxon::Config.new
  end

  def self.queue
    @queue ||= config.queue
  end

  # Job to notify admins via email of a problem.
  class NotificationJob
    class NotifierNotFound < StandardError; end
    @queue = Klaxon.queue

    # Look up the given alert and notify recipients of it.
    def self.perform(alert_id)
      alert = Alert.find(alert_id) 
      recipients = Klaxon.recipients(alert)

      recipients.each do |notifier_key, recipient_list|
        raise NotifierNotFound unless notifier = Klaxon::Notifiers[notifier_key]
        notifier.notify(recipient_list, alert)
        Alert.logger.info { "Notification sent to #{recipient_list.inspect} via #{notifier_key} for alert #{alert.id}." }
      end
      #KlaxonMailer.alert().deliver
    rescue ActiveRecord::RecordNotFound
      Alert.logger.error { "Raised alert with ID=#{alert_id} but couldn't find that alert." }
    rescue NotifierNotFound
      Alert.logger.error { "Raised alert with ID=#{alert_id} for notifier #{notifier_key} but couldn't find that notifier." }
    end
  end

  private
  def self.alert_matches_group(alert, group)
    alert.category =~ Regexp.new(group[:category] || '.*') && 
    alert.severity =~ Regexp.new(group[:severity] || '.*')
  end
end
