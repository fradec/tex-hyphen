#!/usr/bin/env ruby

# Validation program for the new YAML headers at the top of TeX hyphenation files.
# Run on an individual file or a directory to get a report of all the errors on the terminal.
# Copyright (c) 2016–2017 Arthur Reutenauer.  MIT licence (https://opensource.org/licenses/MIT)

# TODO Add the optional “source” top-level entry

require 'yaml'
require 'pp'
require 'byebug'

class HeaderValidator
  class WellFormednessError < StandardError # probably not an English word ;-)
  end

  class ValidationError < StandardError
  end

  class InternalError < StandardError
  end

  @@exemptions = ['ar', 'fa', 'grc-x-ibycus']

  @@format = {
    title: {
      mandatory: true,
      type: String,
    },
    copyright: {
      mandatory: true,
      type: String,
    },
    authors: {
       mandatory: false,
       type: "...", # TODO Define
    },
    language: {
      mandatory: true,
      type: {
        name: {
          mandatory: true,
          type: String,
        },
        tag: {
          mandatory: true,
          type: String,
        },
      },
    },
    version: {
      mandatory: false,
      type: String,
    },
    notice: {
      mandatory: true,
      type: String,
    },
    licence: {
      mandatory: true,
      one_or_more: true,
      type: "[Knuth only knows]", # TODO Define
    },
    changes: {
      mandatory: false,
      type: String,
    },
    hyphenmins: {
      mandatory: false,
      type: {
        generation: {
          mandatory: false,
          type: {
            left: {
              mandatory: true,
              type: Integer,
            },
            right: {
              mandatory: true,
              type: Integer,
            },
          },
        },
        typesetting: {
          mandatory: false,
          type: {
            left: {
              mandatory: true,
              type: Integer,
            },
            right: {
              mandatory: true,
              type: Integer,
            },
          },
        },
      },
    },
    source: {
      mandatory: false,
      type: String
    }
  }

  def initialize
    @errors = { InternalError => [], WellFormednessError => [], ValidationError => [] }
  end

  def parse(filename)
    header = ''
    eohmarker = '=' * 42
    File.read(filename).each_line do |line|
      if line =~ /\\patterns|#{eohmarker}/
        break
      end

      line.gsub!(/^% /, '')
      line.gsub!(/%/, '')
      header += line
    end

    puts header unless @mode == 'mojca'
    begin
      # byebug if filename =~ /hyph-grc-x-ibycus\.tex$/
      # puts 'foo'
      @metadata = YAML::load(header)
      # byebug unless @metatada
      # puts 'bar'
      bcp47 = filename.gsub(/.*hyph-/, '').gsub(/\.tex$/, '')
      raise ValidationError.new("Empty metadata set for language [#{bcp47}]") unless @metadata
    rescue Psych::SyntaxError => err
      raise WellFormednessError.new(err.message)
    end
  end

  def check_mandatory(hash, validator)
    validator.each do |key, validator|
      # byebug if validator[:mandatory] && !hash[key.to_s]
      # byebug unless validator && hash
      raise ValidationError.new("Key #{key} missing") if validator[:mandatory] && !hash[key.to_s]
      check_mandatory(hash[key.to_s], validator[:type]) if hash[key.to_s] && validator[:type].respond_to?(:keys)
    end
  end

  def validate(hash, validator)
    hash.each do |key, value|
      # byebug if validator[key.to_sym] == nil
      raise ValidationError.new("Invalid key #{key} found") if validator[key.to_sym] == nil
      validate(value, validator[key.to_sym][:type]) if value.respond_to?(:keys) && !validator[key.to_sym][:one_or_more]
    end
  end

  def run!(pattfile)
    unless File.file?(pattfile)
      raise InternalError.new("Argument “#{pattfile}” is not a file; this shouldn’t have happened.")
    end
    parse(pattfile)
    check_mandatory(@metadata, @@format)
    validate(@metadata, @@format)
    puts @metadata.inspect unless @mode == 'mojca'
    { title: @metadata['title'], copyright: @metadata['copyright'], notice: @metadata['notice'] }
  end

  def runfile(filename)
    begin
      run! filename
    rescue InternalError, WellFormednessError, ValidationError => err
      # byebug
      @errors[err.class] << [filename, err.message]
    end
  end

  def main(args)
    # TODO Sort input file list in alphabetical order of names!
    @mode = 'default'
    arg = args.shift
    if arg == '-m' # Mojca mode
      @mode = 'mojca'
    else
      args = [arg] + args
    end
    @headings = []
    while !args.empty?
      arg = args.shift
      unless arg
        puts "Please give me at least one file to validate."
        exit -1
      end

      if File.file? arg
        runfile(arg)
      elsif Dir.exists? arg
        Dir.foreach(arg) do |filename|
          next if filename == '.' || filename == '..'
          @headings << [filename, runfile(File.join(arg, filename))]
        end
      else
        puts "Argument #{arg} is neither an existing file nor an existing directory; proceeding." unless @mode == 'mojca'
      end
    end

    unless @mode == 'mojca'
      puts "\nReport on #{arg}:" # FIXME Incorrect if multiple input files given.
      summary = []
      if @errors.inject(0) { |errs, klass| errs + klass.last.count } > 0
        @errors.each do |klass, files|
          next if files.count == 0
          files.each do |file|
            filename = file.first
            message = file.last
            exemption_regexp = Regexp.new '(' + @@exemptions.join('|') + ')'
            # byebug
            skip = klass == ValidationError && message =~ /^Empty metadata set for language \[#{exemption_regexp}\]$/
            # skip = false
            summary << "#{filename}: #{klass.name} #{message}" unless skip
          end
        end
      end

      if (exitcode = summary.count) > 0
        puts "There were the following errors with some files:"
        puts summary.join "\n"
        exit exitcode
      else
        puts "No errors were found."
      end
    else
      @headings.sort! { |a, b| a.first <=> b.first }
      [:title, :copyright, :notice].each do |heading|
        puts heading.capitalize
        puts @headings.map { |filedata| "#{filedata.first}: #{filedata.last[heading]}" }.join("\n")
        puts ""
      end
    end
  end
end

validator = HeaderValidator.new
validator.main(ARGV)
