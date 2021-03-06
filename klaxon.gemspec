# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "klaxon/version"

Gem::Specification.new do |s|
  s.name        = "klaxon"
  s.version     = Klaxon::VERSION
  s.authors     = ["Robert Nubel"]
  s.email       = ["rnubel@enovafinancial.com"]
  s.homepage    = ""
  s.summary     = %q{Notification and alert library for Rails-like projects.}
  s.description = %q{Supports wrapping code that you want to be alerted of failures in, as well as sending notifications through the same mechanism.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"

  s.add_runtime_dependency "rails", ">= 3.0.0"
  s.add_runtime_dependency "resque"
  s.add_runtime_dependency "mail"
end
