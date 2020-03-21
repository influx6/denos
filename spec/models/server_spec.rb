require 'rails_helper'

RSpec.describe Server, type: :model do
  subject {
    described_class.new(
      cluster_id:1,
      friendly_name: 'ny_zero',
      ip_string: '10.323.121.11',
    )
  }

  describe "Validations" do
    it "is valid all valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a valid ip_string" do
      subject.ip_string = nil
      expect(subject).to_not be_valid
    end

    it "is valid without a cluster_id" do
      subject.cluster_id = nil
      expect(subject).to be_valid
    end

    it "is valid without a friendly name" do
      subject.friendly_name = nil
      expect(subject).to be_valid
    end
  end

  describe "Association" do
    it { should belong_to(:cluster).without_validating_presence }
  end
end
