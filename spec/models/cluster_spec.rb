require 'rails_helper'

RSpec.describe Cluster, type: :model do
  it "is valid with valid attributes" do
    expect(Cluster.new(name:'walnut', subdomain:'wal')).to be_valid
  end
  it "is not valid without attributes" do
    expect(Cluster.new).to_not be_valid
  end
  it "is not valid without a name" do
    expect(Cluster.new(subdomain: 'wl')).to_not be_valid
  end
  it "is not valid without a subdomain" do
    expect(Cluster.new(name: 'walnut')).to_not be_valid
  end
  it "should not accept a subdomain longer than 5 characters" do
    expect(Cluster.new(subdomain: 'wllsasss')).to_not be_valid
  end
end
