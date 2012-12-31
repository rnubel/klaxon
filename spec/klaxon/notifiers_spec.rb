require 'spec_helper'

# Fixture for testing notifiers.
class DummyNotifier

end

describe Klaxon::Notifiers do
  it "can register a notifier with a key" do
    Klaxon::Notifiers.register! :dummy, DummyNotifier
    
    Klaxon::Notifiers.should have(1).notifiers
  end

  context "after a notifier has been registered with a key" do
    before {
      Klaxon::Notifiers.register! :dummy, DummyNotifier
    }

    it "can retrieve the notifier based on that key" do
      Klaxon::Notifiers[:dummy].should == DummyNotifier
    end
  end
end
