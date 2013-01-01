namespace :klaxon do
  task :install do
    puts `rails g model Alert exception:string message:string category:string severity:string backtrace:string`
    puts "Run rake db:migrate to finish installation."
  end
end
