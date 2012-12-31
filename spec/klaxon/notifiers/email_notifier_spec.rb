require 'spec_helper'

describe Klaxon::Notifiers::EmailNotifier do
  let(:alert) {
    stub("Alert", :id => 1, :category => 'category', :severity => 'severity',
                            :message => 'message', :exception => 'exception',
                            :backtrace => 'backtrace')
  }

  describe "notifying" do
    it "uses the Mail gem to send an alert" do
      described_class.notify(["a@b.com"], alert)
    end
    
    describe "the sent email" do
      let(:message) { Mail::TestMailer.deliveries.first }
      let(:body) { message.body.decoded }

      it "was sent" do
        message.should_not be_nil
      end

      it "has a subject including the alert's message, severity and category" do
        message.subject.should == "[Klaxon] [severity] message (category)"
      end

      it "has a body including all fields" do
        puts body
        body.should =~ /severity/
        body.should =~ /message/
        body.should =~ /category/
        body.should =~ /exception/
        body.should =~ /backtrace/
      end
    end
  end

  it "registers itself under the key :email" do
    Klaxon::Notifiers[:email].should == described_class
  end
end
