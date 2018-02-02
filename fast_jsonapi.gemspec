Gem::Specification.new do |gem|
  gem.name = "fast_jsonapi"
  gem.version = "1.0.17"

  gem.required_rubygems_version = Gem::Requirement.new(">= 0") if gem.respond_to? :required_rubygems_version=
  gem.metadata = { "allowed_push_host" => "https://rubygemgem.org" } if gem.respond_to? :metadata=
  gem.require_paths = ["lib"]
  gem.authors = ["Shishir Kakaraddi", "Srinivas Raghunathan", "Adam Gross"]
  gem.date = "2018-02-01"
  gem.description = "JSON API(jsonapi.org) serializer that works with rails and can be used to serialize any kind of ruby objects"
  gem.email = ""
  gem.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md",
    "README.rdoc"
  ]
  gem.files = Dir["lib/**/*"]
  gem.homepage = "http://github.com/Netflix/fast_jsonapi"
  gem.licenses = ["Apache-2.0"]
  gem.rubygems_version = "2.5.1"
  gem.summary = "fast JSON API(jsonapi.org) serializer"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, ["~> 5.0"])
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.12"])
      s.add_runtime_dependency(%q<oj>, ["~> 3.3"])
      s.add_runtime_dependency(%q<activerecord>, ["~> 5.0"])
      s.add_development_dependency(%q<skylight>, ["~> 1.3"])
      s.add_development_dependency(%q<rspec>, ["~> 3.5.0"])
      s.add_development_dependency(%q<rspec-benchmark>, ["~> 0.3.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<juwelier>, ["~> 2.1.0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<byebug>, [">= 0"])
      s.add_development_dependency(%q<active_model_serializers>, ["~> 0.10.4"])
      s.add_development_dependency(%q<sqlite3>, ["~> 1.3"])
      s.add_development_dependency(%q<jsonapi-rb>, ["~> 0.5.0"])
    else
      s.add_dependency(%q<activesupport>, ["~> 5.0"])
      s.add_dependency(%q<multi_json>, ["~> 1.12"])
      s.add_dependency(%q<oj>, ["~> 3.3"])
      s.add_dependency(%q<skylight>, ["~> 1.3"])
      s.add_dependency(%q<activerecord>, ["~> 5.0"])
      s.add_dependency(%q<rspec>, ["~> 3.5.0"])
      s.add_dependency(%q<rspec-benchmark>, ["~> 0.3.0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<juwelier>, ["~> 2.1.0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<byebug>, [">= 0"])
      s.add_dependency(%q<active_model_serializers>, ["~> 0.10.4"])
      s.add_dependency(%q<sqlite3>, ["~> 1.3"])
      s.add_dependency(%q<jsonapi-rb>, ["~> 0.5.0"])
    end
  else
    s.add_dependency(%q<activesupport>, ["~> 5.0"])
    s.add_dependency(%q<multi_json>, ["~> 1.12"])
    s.add_dependency(%q<oj>, ["~> 3.3"])
    s.add_dependency(%q<skylight>, ["~> 1.3"])
    s.add_dependency(%q<activerecord>, ["~> 5.0"])
    s.add_dependency(%q<rspec>, ["~> 3.5.0"])
    s.add_dependency(%q<rspec-benchmark>, ["~> 0.3.0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<juwelier>, ["~> 2.1.0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<byebug>, [">= 0"])
    s.add_dependency(%q<active_model_serializers>, ["~> 0.10.4"])
    s.add_dependency(%q<sqlite3>, ["~> 1.3"])
    s.add_dependency(%q<jsonapi-rb>, ["~> 0.5.0"])
  end
end
