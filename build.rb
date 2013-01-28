require 'rubygems'
require 'redcarpet'
require 'set'

$ROOT_DIR="./"
$TEMPLATE="template.html"

# smarty pants extension
class HTMLWithPants < Redcarpet::Render::HTML
  include Redcarpet::Render::SmartyPants
end
@@markdown = Redcarpet::Markdown.new(HTMLWithPants,
	:autolink => true, 
	:space_after_headers => true, 
	:fenced_code_blocks => true, 
	:lax_spacing => true,
	:tables => true)

class MenuItem
	attr_accessor :title, :path, :childs, :nestedTitle

	def is_leaf?
		not @childs 
	end

	def to_s
		# debug printing
		if is_leaf?
			return @path + "\t" + @title
		else
			return @path + "\t" + @title +"\n\t" + @childs.map{|c| c.to_s.gsub("\n","\n\t") }.join("\n\t") 
		end
	end
	

	def initialize(filename, titleprefix)
		content = @@markdown.render(File.read(filename))
		if content.match(/<h1>([^<]+)<\/h1>/)
			@title = $1
		else
			puts "Error: file #{filename} does not have a title"
			fail "Title Missing"
		end
		@path = filename
		if titleprefix.empty?
			@nestedTitle = @title
		else 
			@nestedTitle = titleprefix + " - " + @title 
		end
	end
end

puts "Rebuilding pages"
template = File.read($TEMPLATE)

@titlemap = {}
def fill_title_map(items) 
	items.each do |i| 
		@titlemap[i.path] = i.nestedTitle 
		fill_title_map(i.childs) if not i.childs.nil?
	end
end

found_list = ["index.md"]
	
found_list.each do |f|
	puts "Building #{f}"
	content_html = @@markdown.render(File.read(f))
	title_html = @titlemap[f]
	if not title_html and content_html.match(/<h1>([^<]+)<\/h1>/)
		title_html = $1
	elsif not title_html
		puts "Error: file #{f} does not have a title"
		fail "Title Missing"
	end
	content_html.sub!(/<h1>[^<]+<\/h1>/, "") # remove h1 which is used for title
	result = template.gsub("<!-- Title -->", title_html).gsub("<!-- Content -->", content_html).gsub("<!-- RootDir -->", $ROOT_DIR)
	File.open(f.sub(".md", ".html"), "w") { |h| h.write(result) }
end
puts "Succesfully rebuild all pages"
