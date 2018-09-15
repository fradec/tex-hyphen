#!/usr/bin/env ruby
# encoding: utf-8

# this file generates plain patterns (one-per-line) out of TeX source

# use 'gem install unicode' if unicode is missing on your computer
require 'unicode'

require_relative 'languages.rb'
include Language::TeXLive

Language.all.sort.each do |language|
	code = language.code

	if language.use_old_loader || code == 'mn-cyrl-x-lmc'
		puts "(skipping #{language.code})"
		next
	end

	puts "generating #{code}"

	files = Hash.new
	[:pat, :hyp, :chr, :lic].each do |ext|
		files[ext] = File.open File.join(PATH::TXT, sprintf('hyph-%s.%s.txt', code, ext)), 'w'
	end

	# patterns
	patterns_with_quote = language.write_patterns(files[:pat])

	# exceptions
	# language.write_exceptions(files[:hyp])
	files[:hyp].puts language.get_exceptions if language.get_exceptions != ""

	# characters
	characters_indexes = language.get_patterns.join.gsub(/[.0-9]/,'').unpack('U*').sort.uniq
	characters_indexes.each do |c|
		ch = [c].pack('U')
		files[:chr].puts ch + Unicode.upcase(ch)
		files[:chr].puts "’’" if ch == "'" && !language.isgreek?
	end

	# comments and licence
	files[:lic].puts language.get_comments_and_licence

	files.values.each do |file|
	  file.close
	end

	if patterns_with_quote
		f = File.open File.join(PATH::QUOTE, sprintf('hyph-quote-%s.tex', code)), 'w'
		f.printf "\\bgroup\n\\lccode`\\’=`\\’\n\\patterns{\n"
		patterns_with_quote.each do |pattern|
			f.printf "%s\n", pattern
		end
		f.puts "}\n\\egroup\n"
		f.close
	end
end
