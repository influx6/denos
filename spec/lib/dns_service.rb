require 'rails_helper'
require "aws-sdk-route53"
require 'services/dns_service'

include DNSService::Route53

RSpec.describe :Route53Service do
  cluster_domain = 'ba.dento.com.'
  cluster_domain2 = 'da.dento.com.'
  server1_ip = '32.232.12.12'
  server2_ip = '42.232.12.12'

  no_a_response = {
      is_truncated: false,
      max_items: 100,
      resource_record_sets: [
          create_record_set_hash('NS', 'dilan.denos.com', 300, [{value: 'ms-1296.afs-34.org.'}]),
          create_record_set_hash('AAAA', 'dilan.denos.com', 300, [{value: 'ms-1296.afs-34.org.'}]),
      ]
  }

  server_one_only = {
      is_truncated: false,
      max_items: 100,
      resource_record_sets: [
          create_record_set_hash('A', cluster_domain, 300, [{value: server1_ip}]),
      ]
  }

  server_one_two = {
      is_truncated: false,
      max_items: 100,
      resource_record_sets: [
          create_record_set_hash('A', cluster_domain, 300, [{value: server1_ip}, {value: server2_ip}]),
      ]
  }

  server_one_two_more = {
      is_truncated: false,
      max_items: 100,
      resource_record_sets: [
          create_record_set_hash('A', cluster_domain, 300, [{value: server1_ip}, {value: server2_ip}]),
          create_record_set_hash('A', cluster_domain2, 300, [{value: '14.34.33.33'}]),
          create_record_set_hash('A', cluster_domain2, 300, [{value: '64.134.133.433'}]),
      ]
  }

  change_info_response = {
      change_info: {
          status: 'PENDING',
          id: '/change/C103765939ACDRVNAVPS6',
          submitted_at: Time.now,
      }
  }

  describe "AWS::Route53 Integration with Stubs" do
  	server1 = nil
  	server2 = nil
  	cluster = nil

  	before :each do 
	  cluster = Cluster.create(subdomain: 'ba', name: 'Barcelona')
	  server1 = Server.create(ip_string: server1_ip, cluster_id: cluster.id)
	  server2 = Server.create(ip_string: server2_ip, cluster_id: cluster.id)
  	end

    hostedZone = ENV['AWS_HOSTED_ZONE']
    client = Aws::Route53::Client.new(
        stub_responses: true
    )

    r53 = Provider.new(hostedZone, client)

    it "should be able to get resource set from Route53" do
      client.stub_responses(:list_resource_record_sets, no_a_response)

      r53.reload_records()
      res = r53.get_records()
      expect(res).not_to eq(nil)
      expect(res.size).to eq(0)
    end

    it "should be able to register a server1 in a cluster" do
      client.stub_responses(:change_resource_record_sets, {
          change_info: {
              status: 'PENDING',
              id: '/change/C103765939ACDRVNAVPS6',
              submitted_at: Time.now,
          }
      })
      expect(r53.add_server(server1)).not_to eq(false)
    end

    it "should be able to verify if a server1 is registered" do
      client.stub_responses(:list_resource_record_sets, server_one_only)

      r53.reload_records()
      res = r53.get_records()
      expect(res).not_to eq(nil)
      expect(res.size).to eq(1)

      record = res[cluster.subdomain]
      expect(record).not_to eq(nil)
      expect(record.has_ip(server1.ip_string)).to eq(true)
    end

    it "should be able to register server2 into cluster" do
      client.stub_responses(:change_resource_record_sets, change_info_response)
      expect(r53.add_server(server2)).not_to eq(false)
    end

    it "should be able to verify if a server2 is registered in cluster" do
      client.stub_responses(:list_resource_record_sets, server_one_two)

      r53.reload_records()
      res = r53.get_records()
      expect(res).not_to eq(nil)
      expect(res.size).to eq(1)

      record = res[cluster.subdomain]
      expect(record).not_to eq(nil)
      expect(record.size).to eq(2)

      expect(record.has_ip(server1.ip_string)).to eq(true)
      expect(record.has_ip(server2.ip_string)).to eq(true)
    end

    it "should be able to verify server1 is in dns server" do
    	expect(r53.has_server(server1)).to eq(true)
    end

    it "should be able to verify server2 is in dns server" do
    	expect(r53.has_server(server2)).to eq(true)
    end

    it "should be able to retreive server1 domain" do
    	expect(r53.get_server_domain(server1)).to eq('ba.dento.com')
    end

    it "should be able to retreive server2 domain" do
    	expect(r53.get_server_domain(server2)).to eq('ba.dento.com')
    end

    it "should be able to retreive record-domain records from dns" do
	    client.stub_responses(:list_resource_record_sets, server_one_two_more)

	    r53.reload_records()
    	records = r53.get_servers()
    	expect(records.size).to eq(3)

    	expect(records[0][:server]).to eq(server1)
    	expect(records[1][:server]).to eq(server2)
    	expect(records[2][:server]).to eq(nil)
    end

    it "should be able to de-register server2 in cluster" do
      client.stub_responses(:change_resource_record_sets, change_info_response)

      expect(server2.cluster).not_to eq(nil)
      expect(r53.rm_server(server2)).not_to eq(false)
    end

    it "should be able to verify server2 is no more registered" do
      client.stub_responses(:list_resource_record_sets, server_one_only)

      r53.reload_records()
      res = r53.get_records()
      expect(res).not_to eq(nil)
      expect(res.size).to eq(1)

      record = res[cluster.subdomain]
      expect(record).not_to eq(nil)
      expect(record.has_ip(server1.ip_string)).to eq(true)
      expect(record.has_ip(server2.ip_string)).not_to eq(true)
    end

    it "should be able to de-register server1 in cluster" do
      client.stub_responses(:change_resource_record_sets, change_info_response)

      expect(r53.rm_server(server1)).not_to eq(false)
    end

    it "should be able to verify if server1 is de-registered" do
      client.stub_responses(:list_resource_record_sets, no_a_response)

      r53.reload_records()
      res = r53.get_records()
      expect(res).not_to eq(nil)
      expect(res.size).to eq(0)

      record = res[cluster.subdomain]
      expect(record).to eq(nil)
    end
  end
end
