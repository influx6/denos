require 'rails_helper'

RSpec.describe Server, type: :model do
  cluster = Cluster.create(name: 'Origon', subdomain: 'og')

  subject {
    described_class.new(
      cluster_id: cluster.id,
      friendly_name: 'ny_zero',
      ip_string: '10.323.121.11',
    )
  }

  after do
    cluster.destroy()
  end

  describe "Validations" do
    it "is valid all valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a valid ip_string" do
      subject.ip_string = nil
      expect(subject).not_to be_valid
    end

    it "is not valid without a cluster_id" do
      subject.cluster_id = nil
      expect(subject).not_to be_valid
    end

    it "is valid without a friendly name" do
      subject.friendly_name = nil
      expect(subject).to be_valid
    end

    it "should be able to get server's cluster" do
      expect(subject.cluster).to eq(cluster)
    end
  end

  describe "Association" do
    it { should belong_to(:cluster).without_validating_presence }
  end
end
