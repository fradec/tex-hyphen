#!/usr/bin/env ruby
# encoding: utf-8

# this file auto-generates tlpsrc files for hyphenation patterns - to be improved

require_relative 'languages.rb'
include Language::TeXLive
include Languages::TeXLive

# TODO - make this a bit less hard-coded
$path_TL=File.expand_path("../../../../../TL", __FILE__)
$path_language_dat="#{$path_TL}/texmf-dist/tex/generic/config"
# hyphen-foo.tlpsrc for TeX Live
$path_tlpsrc="#{$path_TL}/tlpkg/tlpsrc"


$dirlist = Hash.new
def dirlist(type)
	$dirlist[type] ||= Dir.glob(File.expand_path(sprintf('../../../../%s/generic/hyph-utf8/languages/*', type), __FILE__)).select do |file|
		File.directory?(file)
	end.map do |dir|
		dir.gsub /^.*\//, ''
	end
end

def write_dependencies(collection)
	$file_tlpsrc.puts "category TLCore"
	$file_tlpsrc.puts "depend hyphen-base"
	$file_tlpsrc.puts "depend hyph-utf8"

	# external dependencies
	if collection == "german" then
		$file_tlpsrc.puts "depend dehyph"
	# for Russian and Ukrainian (until we implement the new functionality at least)
	elsif collection == "russian" then
		$file_tlpsrc.puts "depend ruhyphen"
	elsif collection == "ukrainian" then
		$file_tlpsrc.puts "depend ukrhyph"
	end
end

def make_synonyms(language)
	# synonyms
	if language.synonyms != nil and language.synonyms.length > 0 then
		synonyms=" synonyms=#{language.synonyms.join(',')}"
	else
		synonyms=""
	end
end

def make_hyphenmins(language)
	# lefthyphenmin/righthyphenmin
	if language.hyphenmin == nil or language.hyphenmin.length == 0 then
		lmin = ''
		rmin = ''
	elsif language.filename_old_patterns == "zerohyph.tex" then
		lmin = ''
		rmin = ''
	else
		lmin = language.hyphenmin[0]
		rmin = language.hyphenmin[1]
	end
	"lefthyphenmin=#{lmin} \\\n\trighthyphenmin=#{rmin}"
end

def make_file_line(language)
	# which file to use
	if language.use_old_loader
		file = "file=#{language.filename_old_patterns}"
		if ['ar', 'fa'].include? language.code
			file = file + " \\\n\tfile_patterns="
		elsif language.code == 'grc-x-ibycus' then
			# TODO: fix this
			file = file + " \\\n\tluaspecial=\"disabled:8-bit only\""
		end
	else
		file = sprintf "file=%s", language.loadhyph
	end
end

def make_run_file_list(collection)
	full = []
	full = ["tex/generic/hyph-utf8/patterns/tex/hyph-no.tex"] if collection == "norwegian"

  languages = Languages.packages[collection]

  full = languages.inject(full) do |full, language|
	  full + make_individual_run_file_list(language)
	end

	if !["german", "russian", "ukrainian"].include? collection
		languages.each do |language|
			if language.use_old_patterns and language.filename_old_patterns != "zerohyph.tex" and language.code != 'cop'
				full.push("tex/generic/hyphen/#{language.filename_old_patterns}")
			end
		end
	end

	full
end

def make_individual_run_file_list(language)
	return [] if language.use_old_loader

	files_run = []

	files_path_hyph8 = "tex/generic/hyph-utf8"
	files_run.push(sprintf "%s/loadhyph/%s", files_path_hyph8, language.loadhyph)
	if language.has_quotes then
		files_run.push("#{files_path_hyph8}/patterns/quote/hyph-quote-#{language.code}.tex")
	end

	if language.code == "mn-cyrl-x-lmc" then
		files_run.push("#{files_path_hyph8}/patterns/tex/hyph-#{language.code}.tex")
		files_run.push("#{files_path_hyph8}/patterns/ptex/hyph-#{language.code}.#{language.encoding}.tex")
	# we skip the mongolian language for luatex files
	else
		if (code = language.code) =~ /^sh-/
			files_run.push("#{files_path_hyph8}/patterns/tex/hyph-#{code}.tex")
			files_run.push("#{files_path_hyph8}/patterns/ptex/hyph-#{code}.#{language.encoding}.tex")
			# duplicate entries (will be removed later)
			files_run.push("#{files_path_hyph8}/patterns/tex/hyph-sr-cyrl.tex")
			['chr', 'pat', 'hyp', 'lic'].each do |t|
				files_run.push("#{files_path_hyph8}/patterns/txt/hyph-#{code}.#{t}.txt")
				# duplicate entries (will be removed later)
				files_run.push("#{files_path_hyph8}/patterns/txt/hyph-sr-cyrl.#{t}.txt")
			end
		else
			files_run.push("#{files_path_hyph8}/patterns/tex/hyph-#{language.code}.tex")
			if language.encoding && language.encoding != "ascii" then
				files_run.push("#{files_path_hyph8}/patterns/ptex/hyph-#{language.code}.#{language.encoding}.tex")
			elsif language.code == "cop" then
				files_run.push("#{files_path_hyph8}/patterns/tex-8bit/#{language.filename_old_patterns}")
				# files_run.push("#{files_path_hyph8}/patterns/tex-8bit/copthyph.tex")
			end
			['chr', 'pat', 'hyp', 'lic'].each do |t|
				files_run.push("#{files_path_hyph8}/patterns/txt/hyph-#{language.code}.#{t}.txt")
			end
		end
	end

	files_run
end

# languages.each do |language|
# 	if language.hyphenmin == nil then
# 		lmin = ''
# 		rmin = ''
# 	else
# 		lmin = language.hyphenmin[0]
# 		rmin = language.hyphenmin[1]
# 	end
# 	puts "#{language.name}: #{lmin} #{rmin}"
# end

#--------#
# TLPSRC #
#--------#

Languages.packages.sort.each do |collection, languages|
	files_doc = []
	files_src = []
	$file_tlpsrc = File.open("#{$path_tlpsrc}/hyphen-#{collection}.tlpsrc", 'w')
	puts "generating #{$path_tlpsrc}/hyphen-#{collection}.tlpsrc"

	write_dependencies(collection)

	files_run = make_run_file_list(collection)

	languages.each do |language|
		if language.description_s && language.description_l then
			$file_tlpsrc.puts "shortdesc #{language.description_s}."
			$file_tlpsrc.puts "longdesc #{language.description_l.join("\nlongdesc ")}"
		end

		name = "name=#{language.name}"
		synonyms = make_synonyms(language)
		hyphenmins = make_hyphenmins(language)

		$file_tlpsrc.puts  "execute AddHyphen \\\n\t#{name}#{synonyms} \\"
		$file_tlpsrc.print "\t#{hyphenmins} \\\n\t#{make_file_line(language)}"
		if language.patterns_line + language.exceptions_line != ""
			$file_tlpsrc.print " \\\n\t#{language.patterns_line} \\\n\t#{language.exceptions_line}"
		end
		if language.code == "mn-cyrl-x-lmc" then
			$file_tlpsrc.print " \\\n\tluaspecial=\"disabled:only for 8bit montex with lmc encoding\""
		end
		# end-of-line
		$file_tlpsrc.puts

		# add sources
		if dirlist('source').include?(language.code) then
			files_src.push("source/generic/hyph-utf8/languages/#{language.code}")
		end
		# add documentation
		if dirlist('doc').include?(language.code) then
			files_doc.push("doc/generic/hyph-utf8/languages/#{language.code}")
		end
	end

	# documentation
	if collection == "greek" then
		files_doc.push("doc/generic/elhyphen")
	elsif collection == "hungarian" then
		files_doc.push("doc/generic/huhyphen")
	end

	files_doc.sort.each do |f|
		$file_tlpsrc.puts "docpattern d texmf-dist/#{f}"
	end
	files_src.sort.each do |f|
		$file_tlpsrc.puts "srcpattern d texmf-dist/#{f}"
	end
	files_run.sort.uniq.each do |f|
		$file_tlpsrc.puts "runpattern f texmf-dist/#{f}"
	end
	$file_tlpsrc.close
end

#--------------#
# language.dat #
#--------------#
File.open("#{$path_language_dat}/language.dat", "w") do |file_language_dat|
	Languages.packages.sort.each do |collection, languages|
		languages.each do |language|
			if language.use_old_loader then
				file_language_dat.puts "#{language.name}\t#{language.filename_old_patterns}"
			else
				file_language_dat.puts sprintf("%s\t%s", language.name, language.loadhyph)
			end

			# synonyms
			language.synonyms.each do |synonym|
				file_language_dat.puts "=#{synonym}"
			end
		end
	end
end
