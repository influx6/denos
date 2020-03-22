
require 'rails_helper'
require 'services/dns_service'

include DNSService

RSpec.describe :Client  do
	describe "DNSClient" do
		pending "should be able to get resource set from Route53"
		pending "should be able to register a server in a cluster"
		pending "should be able to de-register a server in a cluster"
		pending "should be able to verify if a server is registered"
		pending "should be able to verify if a server is not registered"
	end
end
