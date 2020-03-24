class DomainController < ApplicationController
  REGISTER_SUCCESS = "Successfully registered server"
  REGISTER_FAILURE = "Failed to register server, please retry"

  UNREGISTER_SUCCESS = "Successfully unregistered server"
  UNREGISTER_FAILURE = "Failed to unregister server, please retry"

  def index
    AWS::Service::R53.reload_records()
    @dns_records = AWS::Service::R53.get_servers()
    @servers = Server.all.order(friendly_name: :asc)
  end

  def register
    # TODO: Decide if we should comment
    # the record reload to optimize speed.
    #
    # If we decide to not scale this service 
    # and not allow users edit records on AWS 
    # then this line can be commented as we 
    # may safely assume all records are still
    # the same from the last get or update.
    #
    # This does mean if our underline dns service
    # goes down request with the old records will
    # be made but then again those will end with 
    # failure, so not much to worry about.
    AWS::Service::R53.reload_records()

    begin
      @server = Server.find(params[:id])
      AWS::Service::R53.add_server(@server)
    rescue
      puts "Bad things have happend ${$!}"
      flash[:error] = self.class::REGISTER_FAILURE
    else
      flash[:notice] = self.class::REGISTER_SUCCESS
    end

    redirect_to root_url
  end

  def deregister
    # TODO: Decide if we should comment
    # the record reload to optimize speed.
    #
    # If we decide to not scale this service 
    # and not allow users edit records on AWS 
    # then this line can be commented as we 
    # may safely assume all records are still
    # the same from the last get or update.
    #
    # This does mean if our underline dns service
    # goes down request with the old records will
    # be made but then again those will end with 
    # failure, so not much to worry about.
    AWS::Service::R53.reload_records()

    begin
      @server = Server.find(params[:id])
      AWS::Service::R53.rm_server(@server)
    rescue
      puts "Bad things have happend ${$!}"
      flash[:error] = self.class::UNREGISTER_FAILURE
    else
      flash[:notice] = self.class::UNREGISTER_SUCCESS
    end
    
    redirect_to root_url
  end

end
