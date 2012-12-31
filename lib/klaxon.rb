require "klaxon/version"
require "klaxon/notifiers"
require "klaxon/config"

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

    Resque.enqueue(EmailAlertJob, alert.id)

    alert
  end

  # Synonym for raise_alert when no exception is involved.
  def self.notify(options)
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

  # Determine the recipients for a particular alert.
  def self.recipients(alert)
    # Each recipient group should look like (where the filter values are regexps):
    # - category: .*
    # severity: (critical|high)
    # recipients:
    # - rnubel@test.com
    rec_lists = config.recipient_groups.collect do |group|
      if alert.category =~ Regexp.new(group[:category]) && alert.severity =~ Regexp.new(group[:severity])
        group[:recipients]
      else
        next
      end
    end

    rec_lists.flatten.compact.uniq # Combine the lists and filter duplicates
  end

  def self.configure
    @config = nil
    yield config
  end

  def self.config
    @config ||= Klaxon::Config.new
  end

  # Job to notify admins via email of a problem.
  class EmailAlertJob
    @queue = :high

    # Look up the given alert and email it out.
    # @param [Integer] alert_id ID of the alert to email about.
    def self.perform(alert_id)
      KlaxonMailer.alert(Alert.find(alert_id)).deliver
    rescue ActiveRecord::RecordNotFound
      Alert.logger.error { "Raised alert with ID=#{alert_id} but couldn't find that alert." }
    end
  end
end
