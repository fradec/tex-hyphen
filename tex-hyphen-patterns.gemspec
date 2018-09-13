Gem::Specification.new do |s|
  s.name = 'tex-hyphen-patterns'
  s.version = '0.0.2'
  s.date = '2018-09-13'
  s.summary = 'TeX hyphenation patterns as a gem'
  s.description = 'Hyphenation patterns for Ruby, as used by the TeX typesetting system.'
  s.authors = ['Arthur Reutenauer']
  s.email = "info@hyphenation.org"
  s.files = ['lib/tex/hyphen/patterns.rb'] + Dir.glob('hyph-utf8/tex/generic/hyph-utf8/patterns/tex/*')
  s.homepage = 'http://www.hyphenation.org/tex'
  s.add_dependency 'hydra'
end
