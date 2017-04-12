# rspec spec/lib/rspec/scaffold/runner_spec.rb
describe RSpec::Scaffold::Runner do
  describe '#generate_spec' do
    let(:input) { FIXTURE_ROOT.join('multiple_args.rb') }

    subject { described_class.new.generate_spec(input).join("\n")}

    it 'returns a collection of lines used to build the spec file' do
      expect(subject).to eq %Q(# spring rspec
describe MultipleArgs do
  let(:name) {}
  let(:age) {}
  let(:args) {}

  subject { described_class.new name, age, *args }

  describe ".__" do
  end

  describe "#initialize" do
  end

end
)
    end

    context 'when given raw Ruby code' do
      let(:input) { "class Admin::Super; def name(); @name = '#{Time.now}'; end; end" }

      it 'returns a collection of lines used to build the spec file' do
        expect(subject).to eq %Q(# spring rspec
describe Admin::Super do

  subject { described_class.new  }

  describe "#name" do
    it "assigns @name" do
    end
  end

end
)
      end
    end
  end

end
