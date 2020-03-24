class ResourceRecord
  attr_reader :subdomain
  attr_reader :domain
  attr_reader :rr

  def initialize(resoure_record, domain, subdomain)
    @rr = resoure_record
    @domain = domain
    @subdomain = subdomain
  end

  def use_rr(resoure_record)
    @rr = resoure_record
  end

  def addr
    return [@subdomain, @domain].join(".")
  end

  def size
    return @rr.resource_records.size
  end

  def to_map_list
    ips = []
    @rr.resource_records.each do |v|
      ips.push({value: v[:value]})
    end
    return ips
  end

  def to_ip_list
    ips = []
    @rr.resource_records.each do |v|
      ips.push(v[:value])
    end
    return ips
  end

  def has_ip(ip)
    index = @rr.resource_records.find_index { |r| r[:value] == ip }
    return index != nil
  end

  def rm_ip(ip)
    index = @rr.resource_records.find_index { |r| r[:value] == ip }
    @rr.resource_records.delete_at(index)
  end

  def add_ip(ip)
    if self.has_ip(ip)
      return
    end

    @rr.resource_records.push(
        Aws::Route53::Types::ResourceRecord.new(
            value: ip,
        )
    )
  end
end
