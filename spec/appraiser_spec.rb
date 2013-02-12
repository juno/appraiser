# -*- coding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Gem::Commands::AppraiserCommand do

  before do
    @rails_json = <<-EOD
{"dependencies":{"runtime":[{"name":"actionmailer","requirements":"= 3.0.9"},{"name":"actionpack","requirements":"= 3.0.9"},{"name":"activerecord","requirements":"= 3.0.9"},{"name":"activeresource","requirements":"= 3.0.9"},{"name":"activesupport","requirements":"= 3.0.9"},{"name":"bundler","requirements":"~> 1.0"},{"name":"railties","requirements":"= 3.0.9"}],"development":[]},"name":"rails","downloads":4977205,"info":"Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity. It encourages beautiful code by favoring convention over configuration.","version_downloads":306973,"version":"3.0.9","homepage_uri":"http://www.rubyonrails.org","bug_tracker_uri":"http://rails.lighthouseapp.com/projects/8994-ruby-on-rails","source_code_uri":"http://github.com/rails/rails","gem_uri":"http://rubygems.org/gems/rails-3.0.9.gem","project_uri":"http://rubygems.org/gems/rails","authors":"David Heinemeier Hansson","mailing_list_uri":"http://groups.google.com/group/rubyonrails-talk","documentation_uri":"http://api.rubyonrails.org","wiki_uri":"http://wiki.rubyonrails.org"}
    EOD

    @empty_json = '{}'
  end

  describe "Constants" do
    describe "RUBY_GEMS_URL" do
      subject { Gem::Commands::AppraiserCommand::RUBY_GEMS_URL }
      it { should eq('http://rubygems.org/api/v1/gems/%s.json') }
    end

    describe "LINE" do
      subject { Gem::Commands::AppraiserCommand::LINE }
      it { should eq('-' * 60) }
    end
  end


  # Instance methods

  describe "#usage" do
    let(:command) { Gem::Commands::AppraiserCommand.new }
    subject { command.usage }
    it { should eq('gem appraiser [-g group]') }
  end

  describe "#execute" do
    let(:command) { Gem::Commands::AppraiserCommand.new }

    it "call #process with STDOUT as output" do
      command.should_receive(:process).with($stdout)
      command.execute
    end
  end


  # private methods

  describe "#process(output)" do
    let(:command) { Gem::Commands::AppraiserCommand.new }
    let(:output) { stub(IO).as_null_object }

    context "response body is not empty json" do
      before do
        dependencies = []
        dependencies << stub(Bundler::Dependency, :groups => [:default], :name => 'rails')
        dependencies << stub(Bundler::Dependency, :groups => [:test], :name => 'rspec')
        Bundler.stub_chain(:definition, :dependencies) { dependencies }
      end

      it "retrieves :default group dependency json from RubyGems API" do
        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_return(:status => 200, :body => @rails_json)
        command.send(:process, output)
        a_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').should have_been_made.once
      end

      it "not retrieves :test group dependency json from RubyGems API" do
        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_return(:status => 200, :body => @rails_json)
        command.send(:process, output)
        a_request(:get, 'http://rubygems.org/api/v1/gems/rspec.json').should_not have_been_made
      end
    end

    context "response body is empty json" do
      before do
        @dependency = stub(Bundler::Dependency,
                           :groups => [:default],
                           :name => 'rails',
                           :source => 'git://github.com/tenderlove/nokogiri.git')
        Bundler.stub_chain(:definition, :dependencies) { [@dependency] }

        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_return(:status => 200, :body => @empty_json)
      end

      it "not raises exception" do
        expect {
          command.send(:process, output)
        }.to_not raise_error
      end

      it "puts dependency source" do
        @dependency.should_receive(:source) { 'git://github.com/tenderlove/nokogiri.git' }
        command.send(:process, output)
      end
    end
  end

  describe "#load_json(gem_name)" do
    let(:command) { Gem::Commands::AppraiserCommand.new }
    let(:gem_name) { 'rails' }

    context "open() raises OpenURI::HTTPError exception" do
      before do
        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_raise(OpenURI::HTTPError.new('error', stub(StringIO)))
      end

      subject { command.send(:load_json, gem_name) }
      it { should be_kind_of(Hash) }
      it { should be_empty }
    end

    context "open() returns JSON response" do
      before do
        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_return(:status => 200, :body => @rails_json)

        @result = command.send(:load_json, gem_name)
      end

      it "have key 'name'" do
        @result.should have_key('name')
        @result['name'].should eq('rails')
      end

      it "have key 'authors'" do
        @result.should have_key('authors')
        @result['authors'].should eq('David Heinemeier Hansson')
      end

      it "have key 'downloads'" do
        @result.should have_key('downloads')
        @result['downloads'].should eq(4977205)
      end

      it "have key 'project_uri'" do
        @result.should have_key('project_uri')
        @result['project_uri'].should eq('http://rubygems.org/gems/rails')
      end

      it "have key 'documentation_uri'" do
        @result.should have_key('documentation_uri')
        @result['documentation_uri'].should eq('http://api.rubyonrails.org')
      end

      it "have key 'source_code_uri'" do
        @result.should have_key('source_code_uri')
        @result['source_code_uri'].should eq('http://github.com/rails/rails')
      end

      it "have key 'info'" do
        @result.should have_key('info')
        @result['info'].should eq("Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity. It encourages beautiful code by favoring convention over configuration.")
      end
    end
  end

  describe "#dependencies_for(group)" do
    let(:command) { Gem::Commands::AppraiserCommand.new }
    let(:group) { :development }

    it "should call Bundler.definition.dependencies.select" do
      dependencies = []
      dependencies << stub(Bundler::Dependency, :groups => [:default])
      dependencies << stub(Bundler::Dependency, :groups => [:development])
      dependencies << stub(Bundler::Dependency, :groups => [:development, :test])
      Bundler.stub_chain(:definition, :dependencies) { dependencies }

      result = command.send(:dependencies_for, group)
      result.should have(2).dependencies
    end
  end

  describe "#number_with_delimiter(number, delimiter = ',', separator = '.')" do
    let(:command) { Gem::Commands::AppraiserCommand.new }

    context "number is 0" do
      let(:number) { 0 }
      subject { command.send(:number_with_delimiter, number) }
      it { should eq('0') }
    end

    context "number is 100" do
      let(:number) { 100 }
      subject { command.send(:number_with_delimiter, number) }
      it { should eq('100') }
    end

    context "number is 1000" do
      let(:number) { 1000 }
      subject { command.send(:number_with_delimiter, number) }
      it { should eq('1,000') }
    end

    context "number is 10000.99" do
      let(:number) { 10000.99 }
      subject { command.send(:number_with_delimiter, number) }
      it { should eq('10,000.99') }
    end

    context "number is 1000000" do
      let(:number) { 1000000 }
      subject { command.send(:number_with_delimiter, number) }
      it { should eq('1,000,000') }
    end

    context "number is 1000000, delimiter is '_'" do
      let(:number) { 1000000 }
      let(:delimiter) { '_' }
      subject { command.send(:number_with_delimiter, number, delimiter) }
      it { should eq('1_000_000') }
    end

    context "number is '1000000 00', delimiter is '_', separator is ' '" do
      let(:number) { 1000000 }
      let(:delimiter) { '_' }
      let(:separator) { ' ' }
      subject { command.send(:number_with_delimiter, number, delimiter, separator) }
      it { should eq('1_000_000') }
    end
  end

end
