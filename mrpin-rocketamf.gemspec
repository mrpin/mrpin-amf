# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name    = 'mrpin-rocketamf'
  s.version = '1.0.4'
  s.platform = Gem::Platform::RUBY
  s.authors  = ['Jacob Henry', 'Stephen Augenstein', "Joc O'Connor"]
  s.email    = ['perl.programmer@gmail.com']
  s.homepage = 'https://github.com/mrpin/mrpin-rocketamf'
  s.summary = 'Fast AMF serializer/deserializer with remoting request/response wrappers to simplify integration'

  s.files         = Dir[*['README.rdoc', 'benchmark.rb', 'mrpin-rocketamf.gemspec', 'Rakefile', 'lib/**/*.rb', 'spec/**/*.{rb,bin,opts}', 'ext/**/*.{c,h,rb}']]
  s.test_files    = Dir[*['spec/**/*_spec.rb']]
  s.extensions    = Dir[*["ext/**/extconf.rb"]]
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake-compiler'

  s.has_rdoc         = true
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options     = ['--line-numbers', '--main', 'README.rdoc']
end