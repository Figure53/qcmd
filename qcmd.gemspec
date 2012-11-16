# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qcmd/version'

Gem::Specification.new do |gem|
  gem.name          = "qcmd"
  gem.version       = Qcmd::VERSION
  gem.authors       = ["Adam Bachman"]
  gem.email         = ["adam.bachman@gmail.com"]
  gem.description   = %q{A simple interactive QLab 3 command line controller}
  gem.summary       = %q{QLab 3 console}
  gem.homepage      = "https://github.com/abachman/qcmd"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'dnssd'
  gem.add_runtime_dependency 'eventmachine'
  gem.add_runtime_dependency 'json'
  gem.add_runtime_dependency 'osc-ruby'
  gem.add_runtime_dependency 'trollop'

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "cucumber"
  gem.add_development_dependency "aruba"
  gem.add_development_dependency 'ruby-debug'
end
