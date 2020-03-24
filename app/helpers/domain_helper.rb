module DomainHelper
  def is_registered(server)
    return AWS::Service::R53.has_server(server)
  end

  def registered_domain(server)
    return AWS::Service::R53.get_server_domain(server)
  end
end
