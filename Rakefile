if ENV['RACK_ENV'] == "production"
  task default: %w[build]
else
  require 'rspec/core/rake_task'
  task default: %w[spec build]
end

task :spec do
  RSpec::Core::RakeTask.new
end

task :build do
  ruby "hyph-utf8/source/generic/hyph-utf8/generate-converters.rb"
  ruby "hyph-utf8/source/generic/hyph-utf8/generate-pattern-loaders.rb"
  ruby "hyph-utf8/source/generic/hyph-utf8/generate-ptex-patterns.rb"
  ruby "hyph-utf8/source/generic/hyph-utf8/generate-tl-files.rb"
  ruby "hyph-utf8/source/generic/hyph-utf8/generate-plain-patterns.rb"
  ruby "hyph-utf8/source/generic/hyph-utf8/generate-webpage.rb"
  system "tools/make_CTAN_zip.sh"
end
