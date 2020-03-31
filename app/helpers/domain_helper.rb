# frozen_string_literal: true
require 'services/dns_service'

module DomainHelper
  include DNSService

  def is_registered(records, server)
    record = records[server.cluster.subdomain]
    if record == nil
      return false
    end
    record_has_ip(record, server.ip_string)
  end

  def registered_domain(records, server)
    record = records[server.cluster.subdomain]
    record&.name
  end
end
