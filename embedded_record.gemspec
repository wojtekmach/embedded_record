# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "embedded_record"

Gem::Specification.new do |s|
  s.name        = "embedded_record"
  s.version     = EmbeddedRecord::VERSION
  s.authors     = ["Wojciech Mach"]
  s.email       = ["wojtek@wojtekmach.pl"]
  s.homepage    = ""
  s.summary     = %q{Embed objects in a bitmask field. Similar to bitmask-attribute and friends}

  s.rubyforge_project = "embedded_record"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "virtus", "~> 0.0.10"

  s.add_development_dependency "rake"
  s.add_development_dependency "minitest", ">= 2.6"
end
