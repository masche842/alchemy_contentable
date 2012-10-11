$:.push File.expand_path("../lib", __FILE__)

require "alchemy_contentable/version"

Gem::Specification.new do |s|
  s.name        = "alchemy_contentable"
  s.version     = AlchemyContentable::VERSION
  s.authors       = ["Marc Schettke"]
  s.email         = ["marc@magiclabs.de"]
  s.description   = %q{Use Alchemy's Elements in any model you like.}
  s.summary       = %q{Adds cms-features to models}
  s.homepage      = "http://github.com/masche842/alchemy_contentable.git"

#  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
#  s.files         = `git ls-files`.split("\n")
#  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_dependency 'alchemy_cms', ["~> 2"]
  s.add_dependency "rails", "~> 3.2"

  s.add_runtime_dependency(%q<magiclabs-userstamp>, ["~> 2.0.2"])

  s.add_development_dependency 'rspec-rails', ["~> 2.7"]
  s.add_development_dependency "sqlite3"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.require_paths = ["lib"]

end
