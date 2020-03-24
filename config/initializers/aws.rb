require 'aws-sdk-core'
require 'services/dns_service'

Aws.config.update({
                      region: ENV['AWS_REGION'],
                      credentials: Aws::Credentials.new(
                          ENV['AWS_ACCESS_KEY_ID'],
                          ENV['AWS_SECRET_ACCESS_KEY'],
                      )
                  })

module AWS
  class Service
    R53 = DNSService::Route53::Provider.new(ENV['AWS_HOSTED_ZONE'], Aws::Route53::Client.new)
  end
end
