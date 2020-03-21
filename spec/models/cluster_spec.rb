require 'rails_helper'

RSpec.describe Cluster, type: :model do
  subject {
    described_class.new(
      name: 'walrus',
      subdomain: 'wal',
    )
  }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end
  it "is not valid without attributes" do
    subject.name = nil
    subject.subdomain = nil
    expect(subject).to_not be_valid
  end
  it "is not valid without a name" do
    subject.name = nil
    expect(subject).to_not be_valid
  end
  it "is not valid without a subdomain" do
    subject.subdomain = nil
    expect(subject).to_not be_valid
  end
  it "should not accept a subdomain longer than 5 characters" do
    subject.subdomain = 'lalalala'
    expect(subject).to_not be_valid
  end
end
