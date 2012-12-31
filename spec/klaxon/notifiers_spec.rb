require 'spec_helper'

# Fixture for testing notifiers.
class DummyNotifier

end

describe Klaxon::Notifiers do
  context "after a notifier has been registered with a key" do
    before {
      Klaxon::Notifiers.register! :dummy, DummyNotifier
    }

    it "can retrieve the notifier based on that key" do
      Klaxon::Notifiers[:dummy].should == DummyNotifier
    end
  end
end
