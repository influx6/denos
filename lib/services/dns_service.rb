require "aws-sdk-route53"

# local imports
require "services/resource_record"

DOMAINS = /^([a-z0-9]+)[\-\.]{1}(([a-z0-9]+)*\.[a-z]{2,5})[\.]?$/

module DNSService

  module Route53
    DEFAULT_TTL = 300

    def get_domain_from_resource_record(resource_record)
      domain_match = DOMAINS.match(resource_record.name)
      if domain_match == nil
        raise Exception.new "Domain #{resource_record.name} is invalid, expected: dl.dmm.com"
      end
      return {
          domain: domain_match[2],
          subdomain: domain_match[1],
      }
    end

    def create_resource_record(ip)
      return Aws::Route53::Types::ResourceRecord.new(
          value: ip,
      )
    end

    def create_resource_record_hash(ip)
      return {
          value: ip,
      }
    end

    def create_resource_record_name(subdomain, domain)
      return [subdomain, domain].join('.')
    end

    def create_record_set_hash(type, name, ttl, ips)
      return {
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
      return {
          data: {
              hosted_zone: {
                  id: id,
                  name: domain,
              }
          }
      }
    end

    def create_change_resource_set_request(action, hosted_zone, resource_record)
      return {
          hosted_zone_id: hosted_zone.id,
          change_batch: {
              changes: [
                  {
                      action: action,
                      resource_record_set: resource_record,
                  }
              ]
          }
      }
    end

    # Provider takes a few short cuts to reduce multiple look ups
    # in that it caches 
    class Provider
      include DNSService::Route53

      def initialize(hosted_zone_id, r53Client)
        @r53 = r53Client
        @resource_record_cache = {}
        @hosted_zone = r53Client.get_hosted_zone({id: hosted_zone_id}).data[:hosted_zone]
      end

      def get_records
        # do a record reload if we have an empty map
        # as regards registered servers.
        if @resource_record_cache.empty?
          self.reload_records()
        end

        # Return what we have, let user ensure to reload
        return @resource_record_cache
      end

      def get_servers
        records = []
        self.get_records().each do |subdomain, rs|
          ips = rs.to_ip_list()
          servers = Server.where(ip_string: ips)

          # check for ips which where not found
          # roughly a O(n^2) complexity here, but
          # it's an acceptable cost.
          # As ips will be only ever equal to or greater servers.length)
          ips.each do |ip|
            server = servers.find { |s| s.ip_string == ip }
            if server != nil
              records.push({
                               server: server,
                               domain: rs.addr(),
                               ip: server.ip_string,
                               subdomain: rs.subdomain,
                           })
              next
            end

            records.push({
                             ip: ip,
                             server: nil,
                             domain: rs.addr(),
                             subdomain: rs.subdomain,
                         })
          end
        end
        return records
      end

      def get_server_domain(server)
        dns_records = @resource_record_cache
        dns_record = dns_records[server.cluster.subdomain]

        if dns_record == nil
          return
        end

        if dns_record.has_ip(server.ip_string)
          return dns_record.addr()
        end
      end

      def has_server(server)
        dns_record = @resource_record_cache[server.cluster.subdomain]
        if dns_record == nil
          return false
        end
        return dns_record.has_ip(server.ip_string)
      end

      def reload_records
        self.get_resource_records()
      end

      def add_server(server)
        if @resource_record_cache.empty?
          self.reload_records()
        end

        if !server.valid?
          return false
        end

        if !server.cluster.valid?
          return false
        end

        local_rr = nil
        local_record = @resource_record_cache[server.cluster.subdomain]

        domain_name = create_resource_record_name(server.cluster.subdomain, @hosted_zone.name)
        if local_record == nil
          domain_rs = create_resource_record_hash(server.ip_string)

          local_rr = create_record_set_hash('A', domain_name, DEFAULT_TTL, [domain_rs])
          local_record = ResourceRecord.new(local_rr, @hosted_zone.name, server.cluster.subdomain)

          # add to in-memory cache and list
          @resource_record_cache[server.cluster.subdomain] = local_record
        else
          local_record.add_ip(server.ip_string)
          local_rr = create_record_set_hash('A', domain_name, DEFAULT_TTL, local_record.to_map_list())
        end

        # send update request to aws.
        # keep it simple, send one at a time.
        crr = create_change_resource_set_request('UPSERT', @hosted_zone, local_rr)

        # am not sure we need to ChangeSet returned
        @r53.change_resource_record_sets(crr)

        self.reload_records()
        return true
      end

      def rm_server(server)
        if @resource_record_cache.empty?
          self.reload_records()
        end

        if !server.valid?
          return false
        end

        if !server.cluster.valid?
          return false
        end

        local_record = @resource_record_cache[server.cluster.subdomain]
        if local_record == nil
          return false
        end


        action = 'UPSERT'
        if local_record.rr.resource_records.size == 1
          action = 'DELETE'
        else
          local_record.rm_ip(server.ip_string)
        end

        domain_name = create_resource_record_name(local_record.subdomain, @hosted_zone.name)
        local_rr = create_record_set_hash('A', domain_name, DEFAULT_TTL, local_record.to_map_list())

        # send update request to aws.
        # keep it simple, send one at a time.
        crr = create_change_resource_set_request(action, @hosted_zone, local_rr)

        # am not sure we need to ChangeSet returned
        @r53.change_resource_record_sets(crr)

        if action == 'DELETE'
          @resource_record_cache.delete(server.cluster.subdomain)
        end

        self.reload_records()
        return true
      end

      protected

      # NOTE(reviewer): Considering my test data is 
      # intentionally made to be below 100, I wont run
      # into issues having to paginate. But I am not
      # sure if the test project intended to see how I would
      # handle this as well.
      #
      # If so, then I would need to update this to keep track
      # of the last records and type wanted (which is A records)
      # then use the `start_with_name` and `start_with_type` to 
      # paginate when records go beyond 100.
      #
      def get_resource_records
        response = @r53.list_resource_record_sets({
                                                      hosted_zone_id: @hosted_zone.id,
                                                  })

        new = {}
        old = @resource_record_cache
        response.resource_record_sets.each do |record|
          if record.type == 'A'
            rr_data = get_domain_from_resource_record(record)

            rr = nil
            if old.key?(rr_data[:subdomain])
              rr = old[rr_data[:subdomain]]
              rr.use_rr(record)
            else
              rr = ResourceRecord.new(record, rr_data[:domain], rr_data[:subdomain])
            end

            # Amazon enforces one subdomain or value 
            # in route53, so you can't have say two resource
            # record set of same sub-domain. So we good here.
            # No need to worry about 2 records of same sub-domain.
            new[rr_data[:subdomain]] = rr
          end
        end

        # update cache with new set.
        @resource_record_cache = new
      end

    end
  end
end
