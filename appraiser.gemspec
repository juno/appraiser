# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "appraiser/version"

Gem::Specification.new do |s|
  s.name        = "appraiser"
  s.version     = Appraiser::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Junya Ogura"]
  s.email       = ["junyaogura@gmail.com"]
  s.homepage    = "https://github.com/juno/appraiser"
  s.licenses    = ["MIT"]
  s.summary     = %q{`appraiser` is a simple rubygems subcommand for Gemfile.}
  s.description = %q{`appraiser` is a rubygems subcommand which displays gem information in `./Gemfile`.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.post_install_message = %q{
appraiser installed as a rubygems subcommand.

  (basic)
  $ gem appraiser

  (shorthand)
  $ gem a

  ("group" option)
  $ gem a -g test

}

  s.add_dependency('bundler', ['~> 1.3'])
  s.add_dependency('colored', ['~> 1.2'])
  s.add_dependency('json')

  s.add_development_dependency('rake', ['~> 10.0'])
  s.add_development_dependency('rspec', ['~> 2.13'])
  s.add_development_dependency('webmock', ['~> 1.11'])
  s.add_development_dependency('coveralls')
  s.add_development_dependency('simplecov')
end
