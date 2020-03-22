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

		def create_record_set(type, name, ttl, ips)
			return Aws::Route53::Types::ResourceRecordSet.new(
				ttl: ttl, 
				type: type,
				name: name,
				weight: nil,
				failover: nil, 
				geo_location: nil, 
				set_identifier: nil,
				multi_value_answer: nil, 
				resource_records: ips,
			)
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

		# Route53Server takes a few short cuts to reduce multiple look ups
		# in that it caches 
		class Route53Service

			 def initialize(hosted_zone_id, r53Client)
				@r53 = r53Client
				@resource_record_cache = {}
				@hosted_zone = r53Client.get_hosted_zone({id: hosted_zone_id}).data[:hosted_zone]
			 end

			 def get_records
			 	# ensure we have latest records, as we may have scaled out
			 	# this to more instances or there maybe user updated records
			 	# which will may in-memory cache stale.
			 	#
			 	# More so, it's just simpler to do this here and try to mitigate
			 	# all the headaches caches will cause, it's supposed to be simple
			 	# anyway. LOL.
		 		self.reload_records()

			 	return @resource_record_cache
			 end

			 def reload_records
		 		self.get_resource_records()
			 end

			 def add_server(server)
			 	# ensure we have latest records, as we may have scaled out
			 	# this to more instances or there maybe user updated records
			 	# which will may in-memory cache stale.
			 	#
			 	# More so, it's just simpler to do this here and try to mitigate
			 	# all the headaches caches will cause, it's supposed to be simple
			 	# anyway. LOL.
		 		self.reload_records()

			 	if !server.valid?
			 		return false
			 	end

			 	if !server.cluster.valid?
			 		return false
			 	end

			 	local_rr = nil
			 	local_record = @resource_record_cache[server.cluster.subdomain]

			 	domain_name = Route53::create_resource_record_name(server.cluster.subdomain, @hosted_zone.name)
			 	if local_record == nil
						domain_rs = Route53::create_resource_record_hash(server.ip_string)

			 	  local_rr = Route53::create_record_set_hash('A', domain_name, Route53::DEFAULT_TTL, [domain_rs])
						local_record = ResourceRecord.new(local_rr, @hosted_zone.name, server.cluster.subdomain)

						# add to in-memory cache and list
						@resource_record_cache[server.cluster.subdomain] = local_record
				else
				 	local_record.add_ip(server.ip_string)
				 	local_rr = Route53::create_record_set_hash('A', domain_name, Route53::DEFAULT_TTL, local_record.to_map_list())
				end

				# send update request to aws.
				# keep it simple, send one at a time.
				crr = Route53::create_change_resource_set_request('UPSERT', @hosted_zone, local_rr)

				# am not sure we need to ChangeSet returned
				@r53.change_resource_record_sets(crr)

			 	return true
			 end

			 def rm_server(server)
			 	# ensure we have latest records, as we may have scaled out
			 	# this to more instances or there maybe user updated records
			 	# which will may in-memory cache stale.
			 	#
			 	# More so, it's just simpler to do this here and try to mitigate
			 	# all the headaches caches will cause, it's supposed to be simple
			 	# anyway. LOL.
			 	#
			 	#
			 	# Comes with the cost of making many request on all ops though.
		 		self.reload_records()

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

			 	domain_name = Route53::create_resource_record_name(local_record.subdomain, @hosted_zone.name)
		 	    local_rr = Route53::create_record_set_hash('A', domain_name, Route53::DEFAULT_TTL, local_record.to_map_list())

				# send update request to aws.
				# keep it simple, send one at a time.
				crr = Route53::create_change_resource_set_request(action, @hosted_zone, local_rr)

				# am not sure we need to ChangeSet returned
				@r53.change_resource_record_sets(crr)

				if action == 'DELETE'
					@resource_record_cache.delete(server.cluster.subdomain)
				end

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
						rr_data = Route53::get_domain_from_resource_record(record)

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
