namespace :klaxon do
  task :install do
    puts `rails g model Klaxon::Alert exception:string message:string category:string severity:string backtrace:string --no-test-framework --skip`
    puts "Run rake db:migrate to finish installation."
  end
end
