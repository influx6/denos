require 'rails_helper'

RSpec.describe Cluster, type: :model do
  describe "Validations" do
    cluster = nil
    before :each do
      cluster = Cluster.create(
          name: 'walrus',
          subdomain: 'wal',
      )
    end

    it "is valid with valid attributes" do
      expect(cluster).to be_valid
    end
    it "is not valid without attributes" do
      cluster.name = nil
      cluster.subdomain = nil
      expect(cluster).to_not be_valid
    end
    it "is not valid without a name" do
      cluster.name = nil
      expect(cluster).to_not be_valid
    end
    it "is not valid without a subdomain" do
      cluster.subdomain = nil
      expect(cluster).to_not be_valid
    end
    it "should not accept a subdomain longer than 5 characters" do
      cluster.subdomain = 'lalalala'
      expect(cluster).to_not be_valid
    end

    it "should not be able to save cluster with same subdomain" do
      c = Cluster.create(name: 'walrus', subdomain: 'wal')
      expect(c).to_not be_valid
      expect(c.id).to eq(nil)
    end
  end
end
