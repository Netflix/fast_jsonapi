# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'fast_jsonapi/version'

Gem::Specification.new do |gem|
  gem.name = 'fast_jsonapi-staging'
  gem.version = FastJsonapi::STAGING_VERSION

  gem.required_ruby_version = '>= 2.0.0' if gem.respond_to? :required_ruby_version=
  gem.required_rubygems_version = Gem::Requirement.new('>= 0') if gem.respond_to? :required_rubygems_version=
  gem.metadata = { 'allowed_push_host' => 'https://rubygems.org' } if gem.respond_to? :metadata=
  gem.require_paths = ['lib']
  gem.authors = ['Shishir Kakaraddi', 'Srinivas Raghunathan', 'Adam Gross']
  gem.description = 'JSON API(jsonapi.org) serializer that works with rails and can be used to serialize any kind of ruby objects'
  gem.email = ''
  gem.extra_rdoc_files = [
    'LICENSE.txt',
    'README.md'
  ]
  gem.files = Dir['lib/**/*']
  gem.homepage = 'http://github.com/Netflix/fast_jsonapi'
  gem.licenses = ['Apache-2.0']
  gem.rubygems_version = '2.5.1'
  gem.summary = 'fast JSON API(jsonapi.org) serializer'

  gem.add_runtime_dependency('activesupport', ['>= 4.2'])
  gem.add_development_dependency('active_model_serializers', ['~> 0.10.7'])
  gem.add_development_dependency('activerecord', ['>= 4.2'])
  gem.add_development_dependency('bundler', ['~> 1.0'])
  gem.add_development_dependency('byebug', ['>= 0'])
  gem.add_development_dependency('jsonapi-rb', ['~> 0.5.0'])
  gem.add_development_dependency('jsonapi-serializers', ['~> 1.0.0'])
  gem.add_development_dependency('oj', ['~> 3.3'])
  gem.add_development_dependency('rspec', ['~> 3.5.0'])
  gem.add_development_dependency('rspec-benchmark', ['~> 0.3.0'])
  gem.add_development_dependency('skylight', ['~> 1.3'])
  gem.add_development_dependency('sqlite3', ['~> 1.3'])
end
