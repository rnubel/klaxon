require File.expand_path(File.join(File.dirname(__FILE__), '..', 'klaxon'))

namespace :klaxon do
  desc "Generate Klaxon::Alert model & migration"
  task :generate do
    if defined?(Rails)
      puts `rails g model Klaxon::Alert exception:string message:string category:string severity:string backtrace:string --no-test-framework --skip`
      puts "Run rake db:migrate to finish installation."
    else
      puts "Not using rails. Please create Klaxon::Alert manually"
    end
  end
end
