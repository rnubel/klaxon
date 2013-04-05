require 'spec_helper'

describe Klaxon do
  let(:alert_options) do
    { :severity => :critical,
      :message => "Raised by someone",
      :category => :real_important_job   }
  end

  let(:recipient_groups) do
    [ {:category => /.*/, :severity => /.*/, :recipients => ["x@y.com", "z@w.com"]},
      {:category => /^test$/, :severity => /(high|low)/, :recipients => ["a@b.com", "z@w.com"], :notifier => :email},
      {:category => /^test$/, :severity => /(high|low)/, :recipients => ["1234567890"], :notifier => :text_message}
    ]
  end

  before do
    Klaxon.configure do |c|
      c.recipient_groups = recipient_groups
    end
  end

  context "when an exception has already been rescued" do
    it "raises an alert" do
      Klaxon::Alert.expects(:create).returns(stub("alert", :id => 1))

      begin
        raise "Testing"
      rescue => e
        Klaxon.raise_alert(e, alert_options)
      end
    end
  end

  context "when considering a block of code which explodes" do
    it "provides a watch method which raises an alert silently" do
      Klaxon.expects(:raise_alert).with(is_a(Exception), has_entries(alert_options))

      lambda {
        Klaxon.watch(alert_options) do
          raise "Testing"
        end
      }.should_not raise_error
    end

    it "provides a watch! method which both send an alert and re-raises the exception" do
      Klaxon.expects(:raise_alert).with(is_a(Exception), has_entries(alert_options))

      lambda {
        Klaxon.watch!(alert_options) do
          raise "Testing"
        end
      }.should raise_error
    end
  end

  describe "being configured" do
    it "wipes old configuration" do
      Klaxon.configure do |c|
        c.recipient_groups = []
      end

      Klaxon.configure { }
      Klaxon.config.recipient_groups.should be_nil
    end

    describe "#recipient_groups=" do
      it "can set the list of recipient groups directly" do
        Klaxon.configure do |c|
          c.recipient_groups = recipient_groups
        end

        Klaxon.config.recipient_groups.should == recipient_groups
      end
    end

    describe "#notify" do
      it "can create a notification group idiomatically" do
        Klaxon.configure do |c|
          c.notify ["rnubel@test.com"], :of => { :severity => /critical/ }, :by => :email
        end

        Klaxon.config.recipient_groups.should == [
          { :severity => /critical/, :recipients => ["rnubel@test.com"], :notifier => :email }
        ]
      end

      it "assumes email as the default notifier if not specified" do
        Klaxon.configure do |c|
          c.notify ["rnubel@test.com"], :of => { :severity => /critical/ }
        end

        Klaxon.config.recipient_groups.should == [
          { :severity => /critical/, :recipients => ["rnubel@test.com"], :notifier => :email }
        ]
      end

      it "converts a single recipient into an array of that single recipient" do
        Klaxon.configure do |c|
          c.notify "rnubel@test.com", :of => { :severity => /critical/ }, :by => :email
        end

        Klaxon.config.recipient_groups.should == [
          { :severity => /critical/, :recipients => ["rnubel@test.com"], :notifier => :email }
        ]
      end

      it 'has a default queue' do
        Klaxon.configure { }
        Klaxon.config.queue.should_not be_nil
      end

      it 'can be confgiured with a default from_address' do
        Klaxon.configure do |c|
          c.from_address = "webdude@example.net"
        end
        Klaxon.config.from_address.should == "webdude@example.net"
      end
    end
  end

  context "deciding what recipients apply to a given alert" do
    context "when given a pattern matching only one group" do
      it "returns the group in a hash with the notifier as the key" do
        Klaxon.recipients(stub('alert', :category => "whee", :severity => "test")).should == { :email => ["x@y.com", "z@w.com"] }
      end
    end

    it "should merge all groups which match the pattern" do
      Klaxon.recipients(stub('alert', :category => "test", :severity => "high")).should == { :email => ["a@b.com", "x@y.com", "z@w.com"],
                                                                                             :text_message => ["1234567890"] }
    end
  end

  describe "synoynms for ::raise_alert" do
    describe "::notify" do
      it "calls raise_alert with notification as the default severity" do
        Klaxon.expects(:raise_alert).with(nil, has_entries(:severity => "notification"))
        Klaxon.notify({})
      end
    end

    describe "::warn!" do
      it "calls raise_alert with the same options as passed" do
        opts = mock("options")
        Klaxon.expects(:raise_alert).with(nil, opts)
        Klaxon.warn!(opts)
      end
    end
  end

  context "when raising an alarm" do
    let(:exception) do
      begin
        raise "Exception"
      rescue => e
        e
      end
    end

    let(:alert) do
      Klaxon.raise_alert(exception, alert_options)
    end

    describe "the created Klaxon::Alert object" do
      it "is created with appropriate fields" do
        Klaxon::Alert.expects(:create).with(has_entries(
          :exception  =>  exception.to_s,
          :backtrace  =>  exception.backtrace.join("\n"),
          :severity   =>  alert_options[:severity].to_s,
          :message    =>  alert_options[:message].to_s,
          :category   =>  alert_options[:category].to_s
        )).returns(stub("alert", :id => 1))
        alert
      end
    end

    it "should enqueue a notification job in Resque" do
      Resque.expects(:enqueue).with(Klaxon::NotificationJob, is_a(Integer))
      alert
    end

    it "does not explode if Resque.enqueue fails" do
      Resque.expects(:enqueue).raises("Blah")
      expect { alert }.to_not raise_error
    end

  end

  describe Klaxon::NotificationJob do
    let(:alert) { stub("alert", :id => 5, :category => "test", :severity => "test", :message => "test", :exception => nil, :backtrace => nil) }
    before { Mail::TestMailer.deliveries.clear }

    it "locates the alert by id" do
      Klaxon::Alert.expects(:find).with(5).returns(alert)
      Klaxon::NotificationJob.perform(5)
    end

    it "uses the associated notifier to alert recipients" do
      Klaxon::Alert.expects(:find).with(5).returns(alert)
      Klaxon.expects(:recipients).with(alert).returns( :email => ["a@b.com"] )
      Klaxon::Notifiers[:email].expects(:notify).with(["a@b.com"], alert)
      Klaxon::NotificationJob.perform(5)
    end

    it 'will use the first email address as the sender when from_address is not present' do
      Klaxon::Alert.expects(:find).with(5).returns(alert)
      Klaxon.expects(:recipients).with(alert).returns( :email => ["a@b.com", "x@y.com"] )
      Klaxon::NotificationJob.perform(5)

      em = Mail::TestMailer.deliveries.first
      em.from.should include("a@b.com")
    end

    it "should raise an error for an unknown Notifier" do
      Klaxon::Alert.expects(:find).with(5).returns(alert)
      Klaxon.expects(:recipients).returns({:raven => "Cersei"})
      Klaxon::Alert.logger.expects(:error)
      Klaxon::NotificationJob.perform(5)
    end

    it "should not raise an exception if the alert isn't found (otherwise, possible recursion)" do
      Klaxon::Alert.expects(:find).with(5).raises(ActiveRecord::RecordNotFound)
      lambda {
        Klaxon::NotificationJob.perform(5)
      }.should_not raise_error
    end
  end
end
