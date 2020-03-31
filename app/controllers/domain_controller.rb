# frozen_string_literal: true
class DomainController < ApplicationController
  REGISTER_SUCCESS = "Successfully registered server"
  REGISTER_FAILURE = "Failed to register server, please retry"

  UNREGISTER_SUCCESS = "Successfully unregistered server"
  UNREGISTER_FAILURE = "Failed to unregister server, please retry"

  def index
    result = AWS::Service::R53.get_servers
    @dns_records = result[:server_records]
    @subdomains_hash = result[:subdomains_hash]
    @servers = Server.all.order(friendly_name: :asc)
  end

  def register
    begin
      @server = Server.find(params[:id])
      AWS::Service::R53.add_server(@server)
    rescue
      puts "Bad things have happend #{$ERROR_INFO}"
      flash[:error] = self.class::REGISTER_FAILURE
    else
      flash[:notice] = self.class::REGISTER_SUCCESS
    end

    redirect_to(root_url)
  end

  def deregister
    begin
      @server = Server.find(params[:id])
      AWS::Service::R53.rm_server(@server)
    rescue
      puts "Bad things have happend #{$ERROR_INFO}"
      flash[:error] = self.class::UNREGISTER_FAILURE
    else
      flash[:notice] = self.class::UNREGISTER_SUCCESS
    end

    redirect_to(root_url)
  end
end
