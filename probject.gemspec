$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'probject/version'

Gem::Specification.new 'probject', Probject::VERSION do |s|
  s.summary = "Actor-based concurrent framework with objects running in separate processes"
  s.description = "A lightweight actor-based concurrent object framework with each object running in it's own process"
  s.authors = ['Johan Lundahl']
  s.email = 'yohan.lundahl@gmail.com'
  s.homepage = 'https://github.com/quezacoatl/probject'
  s.files = `git ls-files`.split($\)
  s.executables = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.add_runtime_dependency 'ichannel', '~> 5.0.1'
end
