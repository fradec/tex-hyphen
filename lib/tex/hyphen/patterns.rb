require 'yaml'
require 'hydra'
require 'byebug' rescue LoadError

module TeX
  module Hyphen
    class InvalidMetadata < StandardError; end

    class Language
      @@topdir = File.expand_path('../../../../hyph-utf8/tex/generic/hyph-utf8/patterns', __FILE__)
      @@eohmarker = '=' * 42

      def initialize(bcp47 = nil)
        @bcp47 = bcp47
      end

      def self.all
        @@languages ||= Dir.glob(File.join(@@topdir, 'txt', 'hyph-*.pat.txt')).inject [] do |languages, txtfile|
          bcp47 = txtfile.gsub /^.*\/hyph-(.*)\.pat\.txt$/, '\1' # TODO Move that to #hyphenate
          languages << [bcp47, Language.new(bcp47)]
        end.to_h
      end

      def self.find_by_bcp47(bcp47)
        all[bcp47]
      end

      def bcp47
        self.class.all
        @bcp47
      end

      def patterns
        @patterns ||= File.read(File.join(@@topdir, 'txt', sprintf('hyph-%s.pat.txt', @bcp47))) if self.class.all[@bcp47]
      end

      def exceptions
        @exceptions ||= File.read(File.join(@@topdir, 'txt', sprintf('hyph-%s.hyp.txt', @bcp47))) rescue Errno::ENOENT if self.class.all[@bcp47]
      end

      def hyphenate(word)
        unless @hydra
          begin
            metadata = extract_metadata
            @hydra = Hydra.new patterns.split, :lax, '', metadata
          rescue InvalidMetadata
            @hydra = Hydra.new patterns.split
          end
        end
        @hydra.showhyphens(word) # FIXME Take exceptions in account!
      end

      def extract_metadata
        header = ""
        File.read(File.join(@@topdir, 'tex', sprintf('hyph-%s.tex', @bcp47))).each_line do |line|
          break if line =~ /\\patterns|#{@@eohmarker}/
          header += line.gsub(/^% /, '').gsub(/%.*/, '')
        end
        begin
          metadata = YAML::load header
          raise InvalidMetadata unless metadata.is_a? Hash
        rescue Psych::SyntaxError
          raise InvalidMetadata
        end

        @name = metadata.dig('language', 'name')
        @lefthyphenmin = metadata.dig('hyphenmins', 'typesetting', 'left')
        @righthyphenmin = metadata.dig('hyphenmins', 'typesetting', 'right')
        licences = metadata.dig('licence')
        raise InvalidMetadata unless licences
        licences = [licences] unless licences.is_a? Array
        @licences = licences.map do |licence|
          next if licence.count == 1 && licence.values == [nil]
          licence.dig('name') || 'custom'
        end.compact
        authors = metadata.dig('authors')
        # puts "Authors: #{authors}"
        @authors = if authors
          authors.map do |author|
            author['name']
          end
        else
          nil
        end

        metadata
      end
    end
  end
end
