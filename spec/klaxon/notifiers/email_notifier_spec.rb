require 'spec_helper'

describe Klaxon::Notifiers::EmailNotifier do
  let(:alert) {
    stub("Alert", :id => 1)
  }

  it "can notify a list of recipients of an alert" do
    described_class.notify(["a@b.com"], alert)
  end

  it "registers itself under the key :email" do
    Klaxon::Notifiers[:email].should == described_class
  end
end
