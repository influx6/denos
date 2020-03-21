require 'rails_helper'

RSpec.describe Server, type: :model do
  it "is not valid without a valid ip_string" do
    expect(Server.new(cluster_id: 1, friendly_name: 'ny-zero')).to_not be_valid
  end

  it "is valid without a cluster_id" do
    expect(Server.new(ip_string: '10.323.121.11', friendly_name: 'ny-zero')).to be_valid
  end

  it "is valid without a friendly name" do
    expect(Server.new(ip_string: '10.323.121.11')).to be_valid
  end
end
