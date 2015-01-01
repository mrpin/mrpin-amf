# -*- encoding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name        = 'mrpin-amf'
  spec.version     = '2.0.2'
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ['Jacob Henry', 'Stephen Augenstein', "Joc O'Connor", 'Gregory Tkach']
  spec.email       = %w(gregory.tkach@gmail.com)
  spec.homepage    = 'https://github.com/mrpin/mrpin-amf'
  spec.license     = 'MIT'
  spec.summary     = 'Fast AMF3 serializer/deserializer'
  spec.description = 'Fast AMF3 serializer/deserializer with remoting request/response wrappers to simplify integration'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = Dir[*['spec/**/*_spec.rb']]
  spec.extensions    = Dir[*['ext/**/extconf.rb']]
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake-compiler', '~> 0'

  spec.has_rdoc         = true
  spec.extra_rdoc_files = %w( README.rdoc )
  spec.rdoc_options     = %w(--line-numbers --main README.rdoc)
end