# -*- coding: utf-8 -*-

module PATH
	ROOT = File.expand_path('../../../../..', __FILE__)

	TeXROOT = File.join(ROOT, 'hyph-utf8')
	TeX_GENERIC = File.join(TeXROOT, 'tex', 'generic')
	TXT = File.join(TeX_GENERIC, 'hyph-utf8', 'patterns', 'txt')
	TEX = File.join(TeX_GENERIC, 'hyph-utf8', 'patterns', 'tex')
	PTEX = File.join(TeX_GENERIC, 'hyph-utf8', 'patterns', 'ptex')
	QUOTE = File.join(TeX_GENERIC, 'hyph-utf8', 'patterns', 'quote')

  HYPHU8 = File.join('tex', 'generic', 'hyph-utf8')

	TL = File.join(ROOT, 'TL')
	LANGUAGE_DAT = File.join(PATH::TL, 'texmf-dist', 'tex', 'generic', 'config')
	# hyphen-foo.tlpsrc for TeX Live
	TLPSRC = File.join(PATH::TL, 'tlpkg', 'tlpsrc')
end

class String
	def superstrip
		strip.gsub /%.*$/, ''
	end

	def supersplit
		strip.gsub(/\s+/m,"\n").split("\n")
	end
end

class Author
	def initialize(name,surname,email,contacted1,contacted2)
		@name       = name
		@surname    = surname
		@email      = email
		# this mostly means if email has been recently checked
		@contacted1 = contacted1
		# this means if we made more cooperation with author,
		# exchanging patches etc.
		@contacted2 = contacted2
	end

	attr_reader :name, :surname, :email
end

class Language
	def initialize(language_hash)
		@use_old_patterns = language_hash["use_old_patterns"]
		@use_old_patterns_comment = language_hash["use_old_patterns_comment"]
		@use_old_loader = language_hash["use_old_loader"]
		@filename_old_patterns = language_hash["filename_old_patterns"]
		@filename_old_patterns_other = language_hash["filename_old_patterns_other"]
		@code = language_hash["code"]
		@name = language_hash["name"]
		@synonyms = language_hash["synonyms"]
		@hyphenmin = language_hash["hyphenmin"]
		@encoding = language_hash["encoding"]
		@exceptions = language_hash["exceptions"]
		@message = language_hash["message"]

		@description_s = language_hash["description_s"]
		@description_l = language_hash["description_l"]
		@version       = language_hash["version"]

		@licence = language_hash["licence"]
		@authors = language_hash["authors"]

		if @synonyms==nil then @synonyms = [] end
	end

	def readtexfile(code = @code)
		IO.readlines(File.join PATH::TEX, sprintf('hyph-%s.tex', code)).join
	end

	def get_exceptions
		exceptions = readtexfile.superstrip
		unless @exceptions1
			if (exceptions.index('\hyphenation') != nil)
				@exceptions1 = exceptions.gsub(/.*\\hyphenation\s*\{(.*?)\}.*/m,'\1').supersplit
			else
				@exceptions1 = ""
			end
		end

		@exceptions1
	end

	def get_patterns
		unless @patterns
			if @code == 'eo' then
				@patterns = readtexfile.superstrip.
					gsub(/.*\\patterns\s*\{(.*)\}.*/m,'\1').
					#
					gsub(/\\adj\{(.*?)\}/m,'\1a. \1aj. \1ajn. \1an. \1e.').
					gsub(/\\nom\{(.*?)\}/m,'\1a. \1aj. \1ajn. \1an. \1e. \1o. \1oj. \1ojn. \1on.').
					gsub(/\\ver\{(.*?)\}/m,'\1as. \1i. \1is. \1os. \1u. \1us.').
					#
					supersplit
			else
				@patterns = readtexfile(if ['nb', 'nn'].include? @code then 'no' else @code end).superstrip.
					gsub(/.*\\patterns\s*\{(.*?)\}.*/m,'\1').
					supersplit
			end
		end

		@patterns
	end

	def get_comments_and_licence
		@comments_and_licence ||= readtexfile.gsub(/(.*)\\patterns.*/m,'\1')
	end

	# def lc_characters
	# 	if @lc_characters == nil
	# 		lc_characters = Hash.new
	# 		p = self.patterns
	# 		p.each do |pattern|
	# 		end
	# 	end
	# 	return @lc_characters
	# end

	attr_reader :use_old_loader, :use_old_patterns, :use_old_patterns_comment, :filename_old_patterns
	attr_reader :code, :name, :synonyms, :hyphenmin, :encoding, :exceptions, :message
	attr_reader :description_l, :version
	attr_reader :licence, :authors

	def description_s
		@description_s || @message
	end

	# Strictly speaking a misnomer, because grc-x-ibycus should also return true.
	# But useful for a number of apostrophe-related routines
	def isgreek?
	  ['grc', 'el-polyton', 'el-monoton'].include? @code
	end

  def has_apostrophes
		begin
			!isgreek? && get_patterns.any? { |p| p =~ /'/ }
		rescue Errno::ENOENT
		  false
		end
	end

	def has_dashes
		begin
			get_patterns.any? { |p| p =~ /-/ }
		rescue Errno::ENOENT
			false
		end
	end

	# Convenience methods related to TeX Live and the .tlpsrc files
	module TeXLive
		def loadhyph
			return filename_old_patterns if use_old_loader

			code = @code
			code = @code.gsub 'sh-', 'sr-' if @code =~ /^sh-/
			sprintf 'loadhyph-%s.tex', code
		end

		# ext: 'pat' or 'hyp'
		# filetype: 'patterns' or 'exceptions'
		def plain_text_line(ext, filetype)
			return "" if ['ar', 'fa', 'grc-x-ibycus', 'mn-cyrl-x-lmc'].include? @code

			if @code =~ /^sh-/
				# TODO Warning AR 2018-09-12
				filename = sprintf 'hyph-sh-latn.%s.txt,hyph-sh-cyrl.%s.txt', ext, ext
			else
				filename = sprintf 'hyph-%s.%s.txt', @code, ext
				filepath = File.join(PATH::TXT, filename)
				# check for existence of file and that it’s not empty
				unless File.file?(filepath) && File.read(filepath).length > 0
					# if the file we were looking for was a pattern file, something’s wrong
					if ext == 'pat'
						raise sprintf("There is some problem with plain patterns for language [%s]!!!", @code)
					else # the file is simply an exception file and we’re happy
						filename = '' # And we return and empty file name after all
					end
				end
			end

			sprintf "file_%s=%s", filetype, filename
		end

		def exceptions_line
			plain_text_line('hyp', 'exceptions')
		end

		def patterns_line
			plain_text_line('pat', 'patterns')
		end

		def extract_apostrophes
			plain, with_apostrophe = Array.new, nil

			get_patterns.each do |pattern|
				plain << pattern
				if pattern =~ /'/ && !isgreek?
					pattern_with_apostrophe = pattern.gsub(/'/,"’")
					plain << pattern_with_apostrophe
					(with_apostrophe ||= []) << pattern_with_apostrophe
				end
			end

			{ plain: plain, with_apostrophe: if with_apostrophe then with_apostrophe end }
		end

		def extract_characters
			characters = Array.new

			characters_indexes = get_patterns.join.gsub(/[.0-9]/,'').unpack('U*').sort.uniq
			characters_indexes.each do |c|
				ch = [c].pack('U')
				characters << ch + Unicode.upcase(ch)
				characters << "’’" if ch == "'" && !isgreek?
			end

			characters
		end
	end

	def list_run_files
		return [] if use_old_loader

		files = []

		files << File.join(PATH::HYPHU8, 'loadhyph', loadhyph)
		if has_apostrophes
			files << File.join(PATH::HYPHU8, 'patterns', 'quote', sprintf("hyph-quote-%s.tex", code))
		end

		files << File.join(PATH::HYPHU8, 'patterns', 'tex', sprintf('hyph-%s.tex', code))
		if encoding && encoding != "ascii" then
			files << File.join(PATH::HYPHU8, 'patterns', 'ptex', sprintf('hyph-%s.%s.tex', code, encoding))
		elsif code == "cop"
			files << File.join(PATH::HYPHU8, 'patterns', 'tex-8bit', filename_old_patterns)
		end

		# we skip the mongolian language for luatex files
		return files if code == "mn-cyrl-x-lmc"

		['chr', 'pat', 'hyp', 'lic'].each do |t|
			files << File.join(PATH::HYPHU8, 'patterns', 'txt', sprintf('hyph-%s.%s.txt', code, t))
		end

		if code =~ /^sh-/
			# duplicate entries (will be removed later)
			files << File.join(PATH::HYPHU8, 'patterns', 'tex', 'hyph-sr-cyrl.tex')
			['chr', 'pat', 'hyp', 'lic'].each do |t|
				# duplicate entries (will be removed later)
				files << File.join(PATH::HYPHU8, 'patterns', 'txt', sprintf('hyph-sr-cyrl.%s.txt', t))
			end
		end

		files
	end
end

class Author
	@@list = []
	@@hash = { }

	def self.all
		return @@list unless @@list == []

		require_relative 'author-data'
		@@authors.each do |id, details|
			author = Author.new(details[0], details[1], details[2], details[3], details[4])
			@@list.push(author)
			@@hash[id] = author
		end

		@@list
	end

	def self.[] a
		all if @@hash == { }
		@@hash[a]
	end
end

class Language
	@@list = nil
	def self.all
		return @@list if @@list

		require_relative 'language-data'
		@@list = @@languages.map do |language_data|
			new language_data
		end
	end

	# TODO self.find
end

module TeXLive
	class Package
		attr_reader :name

		def initialize(name)
		  @name = name
		end

		@@package_mappings = {
			"en-gb"=>"english",
			"en-us"=>"english",
			"nb"=>"norwegian",
			"nn"=>"norwegian",
			"de-1901"=>"german",
			"de-1996"=>"german",
			"de-ch-1901"=>"german",
			"mn-cyrl"=>"mongolian",
			"mn-cyrl-x-lmc"=>"mongolian",
			"el-monoton"=>"greek",
			"el-polyton"=>"greek",
			"grc"=>"ancientgreek",
			"grc-x-ibycus"=>"ancientgreek",
			"zh-latn-pinyin"=>"chinese",
			"as"=>"indic",
			"bn"=>"indic",
			"gu"=>"indic",
			"hi"=>"indic",
			"kn"=>"indic",
			"ml"=>"indic",
			"mr"=>"indic",
			"or"=>"indic",
			"pa"=>"indic",
			"ta"=>"indic",
			"te"=>"indic",
			"sh-latn"=>"serbian",
			"sh-cyrl"=>"serbian",
			"la"=>"latin",
			"la-x-classic"=>"latin",
			"la-x-liturgic"=>"latin"
		}

		def self.make_mappings
			package_names = @@package_mappings.values.uniq.map do |package_name|
				[package_name, Package.new(package_name)]
			end.to_h

			# a hash with the names of TeX Live packages, either individual language names,
			# or an array of languages as the value
			@@packages = Hash.new
			Language.all.each do |language|
				if package_name = @@package_mappings[language.code]
					# language is part of a package
					package = package_names[package_name] || Package.new(package_name)
				else
					# language is individual, but yields to package if there is one with the same name
					if package_names.include? language.name
						next
					else
						package = Package.new language.name
					end
				end

				(@@packages[package] ||= []) << language
			end

			@@packages
		end

		@@packages = make_mappings
		def self.all
			@@packages.keys
		end

		def languages
		  @languages ||= @@packages[self]
		end

		def self.has_dependency?(collection)
			{
				"german" => "dehyph",
				# for Russian and Ukrainian (until we implement the new functionality at least)
				"russian" => "ruhyphen",
				"ukrainian" => "ukrhyph",
			}[collection]
		end

		def list_doc_files
			files_doc = []

			languages.each do |language|
				# add documentation
				if dirlist('doc').include?(language.code) then
					files_doc << sprintf("doc/generic/hyph-utf8/languages/%s", language.code)
				end
			end

			# documentation
			if name == "greek" then
				files_doc << "doc/generic/elhyphen"
			elsif name == "hungarian" then
				files_doc << "doc/generic/huhyphen"
			end

			files_doc
		end

		def list_src_files
			files_src = []
			languages.each do |language|
				# add sources
				if dirlist('source').include?(language.code) then
					files_src << sprintf("source/generic/hyph-utf8/languages/%s", language.code)
				end
			end

			files_src
		end

		def list_run_files
			files = []
			files << "tex/generic/hyph-utf8/patterns/tex/hyph-no.tex" if name == "norwegian"

			files = languages.inject(files) do |files, language|
				files + language.list_run_files
			end

			unless Package.has_dependency?(name)
				languages.each do |language|
					if language.use_old_patterns and language.filename_old_patterns != "zerohyph.tex" and language.code != 'cop'
						files << sprintf("tex/generic/hyphen/%s", language.filename_old_patterns)
					end
				end
			end

			files
		end

		def <=>(other)
			name <=> other.name
		end
	end
end

class Language
	def <=>(other)
	  code <=> other.code
	end
end
