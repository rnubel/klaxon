module Klaxon
  module Notifiers
    class EmailNotifier
      def self.notify(recipients, alert)

      end
    end

    register! :email, EmailNotifier
  end
end
