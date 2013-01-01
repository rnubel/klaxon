# Klaxon

## Installation
Add Klaxon to your Gemfile:
<pre>
gem 'klaxon'
</pre>

Update your bundle:
<pre>
bundle install
</pre>

Use the provided Rake task to generate the migration and model needed by Klaxon. (Angry at the lack of normalization? Install [lookup_by](https://github.com/companygardener/lookup_by/) and rewrite the migration and model to use it; Klaxon won't even notice.)
<pre>
rake klaxon:install
</pre>

Lastly, configure Klaxon to be useful. Create an initializer in `config/initializers/klaxon.rb` that looks something like this:
<pre>
Klaxon.configure do |c|
  c.from_address = 'me@mysite.com'

  c.notify 'you@gmail.com', :of => { :category => /user_registrations/ }, :by => :email
  c.notify ['you@gmail.com', 'sales@mysite.com'], :of => { :category => /new_sales/ } # N.B. 'email' is the default nofifier.
  c.notify 'ops@mysite.com', :of => { :severity => /critical/ } # Values in the :of hash should be regexes.
end
</pre>

## Usage
In anywhere you want to send yourself a notification:
<pre>
Klaxon.notify :category => :user_registrations,
              :message => "User #{user.name} registered at #{Time.now}!"
</pre>

If anywhere you want to sound the alarm:
<pre>
Klaxon.raise_alert  :category => :user_registrations,
                    :severity => :critical,
                    :message => "An error occurred when a user tried to sign up!"
</pre>

In any code you want to watch for explosions:
<pre>
Klaxon.watch! :category => :important_stuff, :severity => :critical, :message => "Error doing important stuff!" do
  Important::Stuff.do!
end
</pre>
