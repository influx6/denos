require 'rails_helper'

RSpec.describe Server, type: :model do
  describe "Validations" do
    cluster = nil
    server = nil

    before(:each) do
      cluster = Cluster.create(name: 'Origon', subdomain: 'og')
      server = Server.create(
          cluster_id: cluster.id,
          friendly_name: 'ny_zero',
          ip_string: '10.323.121.11',
      )
    end

    it "is valid all valid attributes" do
      expect(server).to be_valid
    end

    it "is not valid without a valid ip_string" do
      server.ip_string = nil
      expect(server).not_to be_valid
    end

    it "is not valid without a cluster_id" do
      server.cluster_id = nil
      expect(server).not_to be_valid
    end

    it "is valid without a friendly name" do
      server.friendly_name = nil
      expect(server).to be_valid
    end

    it "should be able to get server's cluster" do
      expect(server.cluster).to eq(cluster)
    end
  end

  describe "Association" do
    it { should belong_to(:cluster).without_validating_presence }
  end
end
