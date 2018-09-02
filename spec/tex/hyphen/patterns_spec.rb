require 'spec_helper'

describe TeX::Hyphen::Patterns do
  describe '.new' do
    it "sets the path to the pattern files" do
      expect(TeX::Hyphen::Patterns.class_variable_get :@@topdir).to eq File.expand_path('../../../../hyph-utf8/tex/generic/hyph-utf8/patterns', __FILE__)
    end

    it "loads all names of the TeX files" do
      patterns = TeX::Hyphen::Patterns.new
      expect(patterns.instance_variable_get(:@texfiles).count).to eq 79
    end

    it "loads all names of the text pattern files" do
      patterns = TeX::Hyphen::Patterns.new
      expect(patterns.instance_variable_get(:@txtfiles).count).to eq 77
    end
  end
end

describe TeX::Hyphen::Language do
  describe '.new' do
    it "creates a new Language instance" do
      expect(TeX::Hyphen::Language.new).to be_a TeX::Hyphen::Language
    end

    it "takes an optional BCP47 tag as argument" do
      language = TeX::Hyphen::Language.new('ro')
      expect(language.instance_variable_get :@bcp47).to eq 'ro'
    end

    it "sets the patterns" do
      language = TeX::Hyphen::Language.new('nl')
      expect(language.instance_variable_get :@patterns).to match /^\.a4\n\.aan5\n\.aarts5/
    end

    it "sets the hyphenation exceptions" do
      language = TeX::Hyphen::Language.new('af')
      expect(language.instance_variable_get :@exceptions).to match /^sandaal\naand-e-tes\naan-gons/
    end
  end

  describe '.all' do
    it "sets the @@languages class variable" do
      TeX::Hyphen::Language.all
      expect(TeX::Hyphen::Language.class_variable_get :@@languages).to be_an Hash
    end

    it "lists all languages" do
      expect(TeX::Hyphen::Language.all.count).to eq 77
    end
  end

  describe '.find_by_bcp47' do
    it "finds the language for that BCP47 tag" do
      language = TeX::Hyphen::Language.find_by_bcp47 'bn'
      expect(language).to be_a TeX::Hyphen::Language
    end

    it "calls .all first" do
      expect(TeX::Hyphen::Language).to receive(:all).and_return({ 'cy' => TeX::Hyphen::Language.new('cy') })
      TeX::Hyphen::Language.find_by_bcp47('cy')
    end
  end

  describe '#bcp47' do
    it "returns the BCP47 tag of the language" do
      language = TeX::Hyphen::Language.new('zu')
      expect(language.bcp47).to eq 'zu'
    end

    # it "calls Language.all first" # FIXME Do we need that?
  end

  describe '#patterns' do
    it "returns the patterns" do
      language = TeX::Hyphen::Language.new('da')
      expect(language.patterns).to match /^\.ae3\n\.an3k\n\.an1s/
    end

    it "calls .all first" do
      language = TeX::Hyphen::Language.new('eu')
      expect(TeX::Hyphen::Language).to receive(:all).and_return({ 'eu' => TeX::Hyphen::Language.new('eu') })
      language.patterns
    end

    # it "loads the patterns first" # TODO Actually that’s prabably stupid
  end

  describe '#exceptions' do
    it "returns the hyphenation exceptions" do
      language = TeX::Hyphen::Language.new('ga')
      expect(language.patterns).to match /^\.ab4ai\n\.ab6ar\n\.ab5r/
    end

    it "calls .all first" do
      language = TeX::Hyphen::Language.new('hu')
      expect(TeX::Hyphen::Language).to receive(:all).and_return({ 'hu' => TeX::Hyphen::Language.new('hu') })
      language.patterns
    end

    it "loads the exceptions first" do
      language = TeX::Hyphen::Language.new('is')
      expect(File).to receive(:read).and_return(".a∂3 .a∂a4 .a∂k2")
      language.patterns
    end
  end
end

# Language
#   #hyphenate
#     hyphenates
#     initialises the hydra if needed
#
# Finished in 1.87 seconds (files took 0.52834 seconds to load)
# 11 examples, 0 failures
#
