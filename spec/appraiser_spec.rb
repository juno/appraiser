require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Gem::Commands::AppraiserCommand do
  let(:empty_json) { '{}' }
  let(:rails_json) do
    <<-EOS
      {"dependencies":{"runtime":[{"name":"actionmailer","requirements":"= 3.0.9"},{"name":"actionpack","requirements":"= 3.0.9"},{"name":"activerecord","requirements":"= 3.0.9"},{"name":"activeresource","requirements":"= 3.0.9"},{"name":"activesupport","requirements":"= 3.0.9"},{"name":"bundler","requirements":"~> 1.0"},{"name":"railties","requirements":"= 3.0.9"}],"development":[]},"name":"rails","downloads":4977205,"info":"Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity. It encourages beautiful code by favoring convention over configuration.","version_downloads":306973,"version":"3.0.9","homepage_uri":"http://www.rubyonrails.org","bug_tracker_uri":"http://rails.lighthouseapp.com/projects/8994-ruby-on-rails","source_code_uri":"http://github.com/rails/rails","gem_uri":"http://rubygems.org/gems/rails-3.0.9.gem","project_uri":"http://rubygems.org/gems/rails","authors":"David Heinemeier Hansson","mailing_list_uri":"http://groups.google.com/group/rubyonrails-talk","documentation_uri":"http://api.rubyonrails.org","wiki_uri":"http://wiki.rubyonrails.org"}
    EOS
  end

  describe "Constants" do
    describe "RUBY_GEMS_URL" do
      subject { Gem::Commands::AppraiserCommand::RUBY_GEMS_URL }
      it { is_expected.to eq('http://rubygems.org/api/v1/gems/%s.json') }
    end

    describe "LINE" do
      subject { Gem::Commands::AppraiserCommand::LINE }
      it { is_expected.to eq('-' * 60) }
    end
  end

  # Instance methods

  describe "#usage" do
    let(:command) { Gem::Commands::AppraiserCommand.new }
    subject { command.usage }
    it { is_expected.to eq('gem appraiser [-g group]') }
  end

  describe "#execute" do
    let(:command) { Gem::Commands::AppraiserCommand.new }

    it "call #process with STDOUT as output" do
      allow(command).to receive(:process)
      command.execute
      expect(command).to have_received(:process).with($stdout)
    end
  end

  # private methods

  describe "#process(output)" do
    let(:command) { Gem::Commands::AppraiserCommand.new }
    let(:output) { double('IO').as_null_object }

    context "response body is not empty json" do
      let(:rails_dep) { double('Bundler::Dependency', groups: [:default], name: 'rails') }
      let(:rspec_dep) { double('Bundler::Dependency', groups: [:test], name: 'rspec') }
      let(:dependencies) { [rails_dep, rspec_dep] }

      before do
        allow(Bundler).to receive_message_chain(:definition, :dependencies).and_return(dependencies)
      end

      it "retrieves :default group dependency json from RubyGems API" do
        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_return(status: 200, body: rails_json)

        command.send(:process, output)

        expect(a_request(:get, 'http://rubygems.org/api/v1/gems/rails.json')) \
          .to have_been_made.once
      end

      it "not retrieves :test group dependency json from RubyGems API" do
        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_return(status: 200, body: rails_json)

        command.send(:process, output)

        expect(a_request(:get, 'http://rubygems.org/api/v1/gems/rspec.json')) \
          .not_to have_been_made
      end
    end

    context "response body is empty json" do
      let(:dependency) do
        double(
          'Bundler::Dependency',
          groups: [:default],
          name: 'rails',
          source: 'git://github.com/tenderlove/nokogiri.git'
        )
      end
      let(:dependencies) { [dependency] }

      before do
        allow(Bundler).to receive_message_chain(:definition, :dependencies).and_return(dependencies)
        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_return(status: 200, body: empty_json)
      end

      it "not raises exception" do
        expect {
          command.send(:process, output)
        }.to_not raise_error
      end

      it "puts dependency source" do
        allow(dependency).to receive(:source).and_return('git://github.com/tenderlove/nokogiri.git')
        command.send(:process, output)
        expect(dependency).to have_received(:source)
      end
    end
  end

  describe "#load_json(gem_name)" do
    let(:command) { Gem::Commands::AppraiserCommand.new }
    let(:gem_name) { 'rails' }

    context "open() raises OpenURI::HTTPError exception" do
      before do
        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_raise(OpenURI::HTTPError.new('error', double('StringIO')))
      end

      subject { command.send(:load_json, gem_name) }

      it { is_expected.to be_kind_of(Hash) }
      it { is_expected.to be_empty }
    end

    context "open() returns JSON response" do
      before do
        stub_request(:get, 'http://rubygems.org/api/v1/gems/rails.json').
          to_return(status: 200, body: rails_json)
      end

      subject { command.send(:load_json, gem_name) }

      it "have key 'name'" do
        expect(subject).to have_key('name')
        expect(subject['name']).to eq('rails')
      end

      it "have key 'authors'" do
        expect(subject).to have_key('authors')
        expect(subject['authors']).to eq('David Heinemeier Hansson')
      end

      it "have key 'downloads'" do
        expect(subject).to have_key('downloads')
        expect(subject['downloads']).to eq(4977205)
      end

      it "have key 'project_uri'" do
        expect(subject).to have_key('project_uri')
        expect(subject['project_uri']).to eq('http://rubygems.org/gems/rails')
      end

      it "have key 'documentation_uri'" do
        expect(subject).to have_key('documentation_uri')
        expect(subject['documentation_uri']).to eq('http://api.rubyonrails.org')
      end

      it "have key 'source_code_uri'" do
        expect(subject).to have_key('source_code_uri')
        expect(subject['source_code_uri']).to eq('http://github.com/rails/rails')
      end

      it "have key 'info'" do
        expect(subject).to have_key('info')
        expect(subject['info']) \
          .to eq("Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity. It encourages beautiful code by favoring convention over configuration.")
      end
    end
  end

  describe "#dependencies_for(group)" do
    let(:command) { Gem::Commands::AppraiserCommand.new }
    let(:group) { :development }
    let(:default_dep) { double('Bundler::Dependency', groups: [:default]) }
    let(:dev_dep) { double('Bundler::Dependency', groups: [:development]) }
    let(:dev_test_dep) { double('Bundler::Dependency', groups: [:development, :test]) }
    let(:dependencies) { [default_dep, dev_dep, dev_test_dep] }

    before do
      allow(Bundler).to receive_message_chain(:definition, :dependencies).and_return(dependencies)
    end

    subject { command.send(:dependencies_for, group) }

    it "should call Bundler.definition.dependencies.select" do
      expect(subject.size).to eq(2)
    end
  end

  describe "#number_with_delimiter(number, delimiter = ',', separator = '.')" do
    let(:command) { Gem::Commands::AppraiserCommand.new }

    subject { command.send(:number_with_delimiter, number) }

    context "number is 0" do
      let(:number) { 0 }
      it { is_expected.to eq('0') }
    end

    context "number is 100" do
      let(:number) { 100 }
      it { is_expected.to eq('100') }
    end

    context "number is 1000" do
      let(:number) { 1000 }
      it { is_expected.to eq('1,000') }
    end

    context "number is 10000.99" do
      let(:number) { 10000.99 }
      it { is_expected.to eq('10,000.99') }
    end

    context "number is 1000000" do
      let(:number) { 1000000 }
      it { is_expected.to eq('1,000,000') }
    end

    context "number is 1000000, delimiter is '_'" do
      let(:number) { 1000000 }
      let(:delimiter) { '_' }
      subject { command.send(:number_with_delimiter, number, delimiter) }
      it { is_expected.to eq('1_000_000') }
    end

    context "number is '1000000 00', delimiter is '_', separator is ' '" do
      let(:number) { 1000000 }
      let(:delimiter) { '_' }
      let(:separator) { ' ' }
      subject { command.send(:number_with_delimiter, number, delimiter, separator) }
      it { is_expected.to eq('1_000_000') }
    end
  end
end
