require "aws-sdk-route53"

# local imports
require "resource_record"

module DNSService

	class Client
	 def initialize(provider)
		@provider = provider
	 end

	 def registerServer(server, cluster)
	 end

	end

	class Route53Provider
	 def initialize(hosted_zone_id)
		@r53 = AWS::Route53::HostedZone.new(hosted_zone_id)
	 end

	 def getClusterRecords
		# recordSet = @r53.rrsets
	 end
	end

end
