# -*- coding: utf-8 -*-

require 'rubygems/command'
require 'rubygems/dependency'
require 'bundler'
require 'colored'
require 'json'
require 'open-uri'
require 'slop'

require 'appraiser/version'

class Gem::Commands::AppraiserCommand < Gem::Command
  RUBY_GEMS_URL = 'http://rubygems.org/api/v1/gems/%s.json'
  LINE = '-' * 60

  def initialize
    super 'appraiser', 'appraiser'

    add_option('-g', '--group=GROUP', 'Group') do |group, options|
      options[:group] = group
    end
  end

  def usage # :nodoc:
    "#{program_name} [-g group]"
  end

  def execute
    group = (options[:group] || :default).to_sym

    dependencies_for(group).each do |dependency|
      json = load_json(dependency.name)

      if json.empty?
        puts dependency.name.green
        puts "Source   : #{dependency.source.to_s.cyan.underline}"
      else
        name = json['name']
        authors = json['authors']
        downloads = number_with_delimiter(json['downloads'])
        project_uri = json['project_uri']
        doc_uri = json['documentation_uri']
        src_uri = json['source_code_uri']
        info = json['info'].split("\n").first.strip

        puts "#{name.green} (by #{authors})"
        puts "Downloads: #{downloads.blue}"
        puts "Project  : #{project_uri.cyan.underline}" if project_uri
        puts "Document : #{doc_uri.cyan.underline}" if doc_uri
        puts "Source   : #{src_uri.cyan.underline}" if src_uri
        puts info
      end

      puts LINE
    end
  end

  private

  # @param [String] gem_name
  # @return [Hash]
  def load_json(gem_name)
    JSON.parse(open(RUBY_GEMS_URL % gem_name).read)
  rescue OpenURI::HTTPError => e
    {}
  end

  # @param [Symbol] group
  # @return [Array<Bundler::Dependency>]
  def dependencies_for(group)
    Bundler.definition.dependencies.select{ |i| i.groups.include? group }
  end

  # @param [Integer] number
  # @param [String] delimiter
  # @param [String] separator
  # @return [String]
  def number_with_delimiter(number, delimiter = ',', separator = '.')
    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join separator
  rescue
    number.to_s
  end
end
