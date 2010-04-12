# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts_as_permission}
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cyril Wack"]
  s.cert_chain = ["/Users/cyril/gem-public_cert.pem"]
  s.date = %q{2010-04-12}
  s.description = %q{Simple Rails plugin to assign a list of permissions on a resource.}
  s.email = %q{cyril.wack@gmail.com}
  s.extra_rdoc_files = ["README.rdoc", "lib/acts_as_permission.rb", "lib/permissions_helper.rb"]
  s.files = ["MIT-LICENSE", "README.rdoc", "Rakefile", "VERSION.yml", "generators/acts_as_permission/USAGE", "generators/acts_as_permission/acts_as_permission_generator.rb", "init.rb", "lib/acts_as_permission.rb", "lib/permissions_helper.rb", "Manifest", "acts_as_permission.gemspec"]
  s.homepage = %q{http://github.com/cyril/acts_as_permission}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Acts_as_permission", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{acts_as_permission}
  s.rubygems_version = %q{1.3.6}
  s.signing_key = %q{/Users/cyril/gem-private_key.pem}
  s.summary = %q{Simple Rails plugin to assign a list of permissions on a resource.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
