require 'mail'

module Klaxon
  module Notifiers
    class EmailNotifier
      def self.notify(recipients, alert)
        _body = "
Alert raised by Klaxon on your site:
\n
Message: #{alert.message}
Category: #{alert.category}
Severity: #{alert.severity}
Exception: #{alert.exception}
Backtrace: #{alert.backtrace}
        ";
        
        Mail.deliver do
          from    'you@you.com'
          to      recipients.join(", ")
          subject "[Klaxon] [#{alert.severity}] #{alert.message} (#{alert.category})"
          body    _body
        end
      end
    end

    register! :email, EmailNotifier
  end
end
