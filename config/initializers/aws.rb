# frozen_string_literal: true
require 'aws-sdk-core'
require 'services/dns_service'

Aws.config.update({
  stub_responses: ENV['RAILS_ENV'] == 'test',
  region: ENV['AWS_REGION'],
  credentials: Aws::Credentials.new(
    ENV['AWS_ACCESS_KEY_ID'],
    ENV['AWS_SECRET_ACCESS_KEY'],
  ),
})

module AWS
  class Service
    R53Client = Aws::Route53::Client.new
    R53 = DNSService::Provider.new(ENV['AWS_HOSTED_ZONE'], AWS::Service::R53Client)
  end
end
