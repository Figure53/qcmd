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
  gem.homepage      = "https://github.com/Figure53/qcmd"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'dnssd', '= 2.0'
  gem.add_runtime_dependency 'json', '= 1.7.7'
  gem.add_runtime_dependency 'osc-ruby', '= 1.1.0'
  gem.add_runtime_dependency 'trollop', '= 2.0'

  gem.add_development_dependency "rspec", '~> 2.10.0'
  gem.add_development_dependency "cucumber", '= 1.2.1'
  gem.add_development_dependency "aruba"

  gem.required_ruby_version = '>= 1.9'
end
