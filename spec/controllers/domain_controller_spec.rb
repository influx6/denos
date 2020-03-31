# frozen_string_literal: true
require 'rails_helper'
require "aws-sdk-route53"
require 'services/dns_service'

include(DNSService)

RSpec.describe(DomainController, type: :controller) do
  server_ip = '10.10.10.10'
  cluster_domain = 'wfi.waffi.com.'

  no_a_response = {
    is_truncated: false,
    max_items: 100,
    resource_record_sets: [
      create_record_set_hash('NS', 'dilan.denos.com', 300, [{ value: 'ms-1296.afs-34.org.' }]),
      create_record_set_hash('AAAA', 'dilan.denos.com', 300, [{ value: 'ms-1296.afs-34.org.' }]),
    ],
  }

  server_one_only = {
    is_truncated: false,
    max_items: 100,
    resource_record_sets: [
      create_record_set_hash('A', cluster_domain, 300, [{ value: server_ip }]),
    ],
  }

  change_info_response = {
    change_info: {
      status: 'PENDING',
      id: '/change/C103765939ACDRVNAVPS6',
      submitted_at: Time.now,
    },
  }

  server = nil
  before :each do
    cluster = Cluster.create(name: 'Waffi', subdomain: 'wfi')
    server = Server.create(
      cluster_id: cluster.id,
      ip_string: server_ip,
      friendly_name: 'bar',
    )
  end

  describe "GET index" do
    before :each do
      AWS::Service::R53Client.stub_responses(:list_resource_record_sets, no_a_response)
    end

    it "should assigned @servers for page tables" do
      get :index
      expect(assigns(:servers)).to(eq([server]))
      expect(AWS::Service::R53.has_server(server)).to(eq(false))
    end
    it "should render the index template" do
      get :index
      expect(response).to(render_template("index"))
      expect(response.status).to(eq(200))
    end
  end

  describe "POST register" do
    it "should register a non-registered server" do
      AWS::Service::R53Client.stub_responses(:list_resource_record_sets, server_one_only)
      AWS::Service::R53Client.stub_responses(:change_resource_record_sets, change_info_response)

      post :register, params: { id: server.id }

      expect(response).to(redirect_to(:root))
      expect(AWS::Service::R53.has_server(server)).to(eq(true))
    end
  end

  describe "POST deregister" do
    it "should deregister a giving server" do
      AWS::Service::R53Client.stub_responses(:list_resource_record_sets, no_a_response)
      AWS::Service::R53Client.stub_responses(:change_resource_record_sets, change_info_response)

      delete :deregister, params: { id: server.id }

      expect(response).to(redirect_to(:root))
      expect(AWS::Service::R53.has_server(server)).to(eq(false))
    end
  end
end
