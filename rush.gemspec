# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rush/version"
require 'rake'

Gem::Specification.new do |s|
	s.name        = "rush"
	s.version     = Rush::VERSION
	s.platform    = Gem::Platform::RUBY
	s.authors     = %w(adamwiggins)
	s.email       = %w()
	s.homepage    = "http://rush.heroku.com/"
	s.summary     = "A Ruby replacement for bash+ssh."
	s.description = %q{A Ruby replacement for bash+ssh, providing both an interactive shell and a library.  Manage both local and remote unix systems from a single client.}

	s.files            = `git ls-files`.split("\n")
	s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.executables      = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
	s.require_paths    = ["lib"]
	s.extra_rdoc_files = %w(README.rdoc)

	s.add_development_dependency "rspec", ["~> 2.1.0"]
	s.add_development_dependency "rcov"
	s.add_development_dependency "yard",  ["~> 0.6.0"]

	s.add_runtime_dependency "session"
end
