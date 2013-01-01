# Klaxon

## Installation

### Rails

In your Gemfile:
<pre>
gem 'klaxon'
</pre>

Either create an Alert model by hand, or use the provided rake task:
<pre>
rake klaxon:install
</pre>

In e.g. `config/initializers/klaxon.rb`:
<pre>
Klaxon.configure do |c|
  c.notify 'you@gmail.com', :of => { :category => /user_registrations/ }, :by => :email
  c.notify '17735555555', :of => { :severity => /critical/ }, :by => :text_message
end
</pre>

## Usage
In anywhere you want to send yourself a notification:
<pre>
Klaxon.notify :category => :user_registrations,
              :message => "User #{user.name} registered at #{Time.now}!"
</pre>

In any code you want to watch for explosions:
<pre>
Klaxon.watch! :category => :important_stuff, :severity => :critical, :message => "Error doing important stuff!" do
  Important::Stuff.do!
end
</pre>
