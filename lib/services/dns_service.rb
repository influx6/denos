# frozen_string_literal: true
require "aws-sdk-route53"

DOMAINS = /^([a-z0-9]+)[\-\.]{1}(([a-z0-9]+)*\.[a-z]{2,5})[\.]?$/

module DNSService
  DEFAULT_TTL = 300

  def get_domain_subdomain(resource_record)
    domain_match = DOMAINS.match(resource_record.name)
    if domain_match.nil?
      raise Exception, "Domain #{resource_record.name} is invalid, expected: dl.dmm.com"
    end
    {
      domain: domain_match[2],
      subdomain: domain_match[1],
    }
  end

  def create_resource_record(ip)
    Aws::Route53::Types::ResourceRecord.new(
      value: ip,
    )
  end

  def create_resource_record_hash(ip)
    {
      value: ip,
    }
  end

  def create_record_set_hash(type, name, ttl, ips)
    {
      ttl: ttl,
      type: type,
      name: name,
      weight: nil,
      failover: nil,
      geo_location: nil,
      set_identifier: nil,
      multi_value_answer: nil,
      resource_records: ips,
    }
  end

  def create_hosted_zone(domain, id)
    {
      data: {
        hosted_zone: {
          id: id,
          name: domain,
        },
      },
    }
  end

  def change_resource_set_request(action, hosted_zone, resource_record)
    {
      hosted_zone_id: hosted_zone.id,
      change_batch: {
        changes: [
          {
            action: action,
            resource_record_set: resource_record,
          },
        ],
      },
    }
  end

  def record_map_list(record)
    ips = []
    record.resource_records.each do |v|
      ips.push({ value: v[:value] })
    end
    ips
  end

  def record_ip_list(record)
    ips = []
    record.resource_records.each do |v|
      ips.push(v[:value])
    end
    ips
  end

  def record_has_ip(record, ip_string)
    record.resource_records.find_index { |r| r[:value] == ip_string } != nil
  end

  # Update: Remove all state cache and resolve all previous errors.
  class Provider
    include DNSService

    def initialize(hosted_zone_id, r53_client)
      @r53 = r53_client
      @hosted_zone = r53_client.get_hosted_zone({ id: hosted_zone_id }).data[:hosted_zone]
    end

    def get_servers
      server_records = []
      dns_records_hash = get_resource_records
      dns_records_hash.each_value do |rs|
        ips = record_ip_list(rs)
        servers = Server.where(ip_string: ips)

        # check for ips which where not found
        # roughly a O(n^2) complexity here, but
        # it's an acceptable cost.
        # As ips will be only ever equal to or greater servers.length)
        ips.each do |ip|
          server = servers.find { |s| s.ip_string == ip }
          unless server.nil?
            server_records.push({ server: server, domain: rs.name, ip: server.ip_string })
            next
          end

          server_records.push({ ip: ip, server: nil, domain: rs.name })
        end
      end

      {
        server_records: server_records,
        subdomains_hash: dns_records_hash,
      }
    end

    def has_server(server)
      record = get_resource_record_for(server)
      if record.nil?
        return false
      end
      record_has_ip(record, server.ip_string)
    end

    def add_server(server)
      unless server.valid?
        raise "Bad server record provided"
      end

      domain_name = [server.cluster.subdomain, @hosted_zone.name].join('.')
      record = get_resource_record_for(server)

      if record.nil?
        domain_rs = create_resource_record_hash(server.ip_string)
        local_rr = create_record_set_hash('A', domain_name, DEFAULT_TTL, [domain_rs])
        crr = change_resource_set_request('UPSERT', @hosted_zone, local_rr)
        @r53.change_resource_record_sets(crr)
        return
      end

      if record_has_ip(record, server.ip_string)
        return
      end

      record.resource_records.push(Aws::Route53::Types::ResourceRecord.new(value: server.ip_string))
      local_rr = create_record_set_hash('A', domain_name, DEFAULT_TTL, record_map_list(record))
      crr = change_resource_set_request('UPSERT', @hosted_zone, local_rr)
      @r53.change_resource_record_sets(crr)
    end

    def rm_server(server)
      unless server.valid?
        raise "Bad server record provided"
      end

      record = get_resource_record_for(server)
      unless record_has_ip(record, server.ip_string)
        return
      end

      action = 'UPSERT'
      if record.resource_records.size == 1
        action = 'DELETE'
      else
        index = record.resource_records.find_index { |r| r[:value] == server.ip_string }
        record.resource_records.delete_at(index)
      end

      local_rr = create_record_set_hash('A', record.name, DEFAULT_TTL, record_map_list(record))
      crr = change_resource_set_request(action, @hosted_zone, local_rr)
      @r53.change_resource_record_sets(crr)
    end

    def get_resource_records
      record_set = {}
      response = @r53.list_resource_record_sets({ hosted_zone_id: @hosted_zone.id })
      response.resource_record_sets.each do |record|
        if record.type == 'A'
          rr_data = get_domain_subdomain(record)
          record_set[rr_data[:subdomain]] = record
        end
      end

      record_set
    end

    def get_resource_record_for(server)
      server_cluster_address = [server.cluster.subdomain, @hosted_zone.name].join('.')
      response = @r53.list_resource_record_sets({ hosted_zone_id: @hosted_zone.id, start_record_name: server_cluster_address, start_record_type: 'A', max_items: 1 })

      unless !response.resource_record_sets.empty?
        return nil
      end

      response.resource_record_sets[0]
    end
  end
end
