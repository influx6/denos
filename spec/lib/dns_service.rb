# frozen_string_literal: true
require 'rails_helper'
require "aws-sdk-route53"
require 'services/dns_service'

include(DNSService)

RSpec.describe(:Route53Service) do
  cluster_domain_addr = 'ba.dento.com.'

  server1_ip = '32.232.12.12'
  server2_ip = '434.232.212.122'

  response_with_no_a_record = {
    is_truncated: false,
    max_items: 100,
    resource_record_sets: [],
  }

  change_response_for_server1 = {
    max_items: 100,
    is_truncated: false,
    resource_record_sets: [create_record_set_hash('A', cluster_domain_addr, 300, [{ value: server1_ip }])],
  }

  change_response_for_server2 = {
    is_truncated: false,
    max_items: 100,
    resource_record_sets: [create_record_set_hash('A', cluster_domain_addr, 300, [{ value: server2_ip }])],
  }

  change_response_with_both = {
    is_truncated: false,
    max_items: 100,
    resource_record_sets: [
      create_record_set_hash('A', cluster_domain_addr, 300, [{ value: server2_ip }, { value: server2_ip }]),
    ],
  }

  describe "AWS::Route53 Integration with Stubs" do
    server1 = nil
    cluster = nil

    before :each do
      cluster = Cluster.create(subdomain: 'ba', name: 'Barcelona')
      server1 = Server.create(ip_string: server1_ip, cluster_id: cluster.id)
    end

    client = Aws::Route53::Client.new(
      stub_responses: true
    )

    r53 = Provider.new("test_zone", client)

    context "When requesting server records" do
      result = nil
      before :all do
        client.stub_responses(:list_resource_record_sets, change_response_for_server1)
        result = r53.get_servers
      end

      it "should return correct server data with server_list" do
        server_records = result[:server_records]
        expect(server_records).not_to(eq(nil))
        expect(server_records.size).to(eq(1))
        expect(server_records[0][:ip]).to(eq(server1_ip))
        expect(server_records[0][:domain]).to(eq(cluster_domain_addr))
      end

      it "should return correct server data with sub_domain hash" do
        subdomains_hash = result[:subdomains_hash]
        expect(subdomains_hash).not_to(eq(nil))

        cluster_resource_record = subdomains_hash[cluster.subdomain]
        expect(cluster_resource_record).not_to(eq(nil))
        expect(record_has_ip(cluster_resource_record, server1.ip_string)).to(eq(true))
      end
    end

    context "When adding server record with no existing subdomain A record" do
      it "should have change set with single resource_record hash" do
        client.stub_responses(:list_resource_record_sets, response_with_no_a_record)
        client.stub_responses(:change_resource_record_sets, -> (context) {
          change_batch = context.params[:change_batch]
          expect(change_batch).not_to(eq(nil))

          changes = change_batch[:changes]
          expect(changes.size).to(eq(1))

          change_record = changes[0]
          expect(change_record[:action]).to(eq("UPSERT"))

          resource_records = change_record[:resource_record_set][:resource_records]
          expect(resource_records).to(eq([{ value: server1_ip }]))
        })

        r53.add_server(server1)
      end
    end

    context "When adding server record with existing subdomain A record containing another ip" do
      it "change set should have 2 resource_record hash" do
        client.stub_responses(:list_resource_record_sets, change_response_for_server2)
        client.stub_responses(:change_resource_record_sets, -> (context) {
          change_batch = context.params[:change_batch]
          expect(change_batch).not_to(eq(nil))

          changes = change_batch[:changes]
          expect(changes.size).to(eq(1))

          change_record = changes[0]
          expect(change_record[:action]).to(eq("UPSERT"))

          resource_records = change_record[:resource_record_set][:resource_records]
          expect(resource_records).to(eq([{ value: server2_ip }, { value: server1_ip }]))
        })

        r53.add_server(server1)
      end
    end

    context "When removing server ip from changeset with more than 1 resource record" do
      it "receive correct changeset without server ip and action set to UPSERT" do
        client.stub_responses(:list_resource_record_sets, change_response_with_both)
        client.stub_responses(:change_resource_record_sets, -> (context) {
          change_batch = context.params[:change_batch]
          puts "Changes: #{change_batch}"
          expect(change_batch).not_to(eq(nil))

          changes = change_batch[:changes]
          expect(changes.size).to(eq(1))

          change_record = changes[0]
          expect(change_record[:action]).to(eq("UPSERT"))

          resource_records = change_record[:resource_record_set][:resource_records]
          expect(resource_records).to(eq([{ value: server2_ip }]))
        })

        r53.rm_server(server1)
      end
    end

    context "When removing server ip from changeset with 1 resource record with servers ip" do
      it "receive correct changeset with server ip and action set to DELETE" do
        client.stub_responses(:list_resource_record_sets, change_response_for_server1)
        client.stub_responses(:change_resource_record_sets, -> (context) {
          change_batch = context.params[:change_batch]
          expect(change_batch).not_to(eq(nil))

          changes = change_batch[:changes]
          expect(changes.size).to(eq(1))

          change_record = changes[0]
          expect(change_record[:action]).to(eq("DELETE"))

          resource_records = change_record[:resource_record_set][:resource_records]
          expect(resource_records).to(eq([{ value: server1_ip }]))
        })

        r53.rm_server(server1)
      end
    end
  end
end
