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
  	# TODO: Uncomment this if:
  	#
  	# We decide to allow users editing 
  	# dns records on s3 as well or spawn this into
  	# multiple instances (to scale horizontally)
  	# then we need to add uncomment this, to 
  	# ensure we consistently are dealing with 
  	# latest records from amazon.
  	#
    # AWS::Service::R53.reload_records()

  	begin
	  	server = Server.find(params[:id])
	    AWS::Service::R53.add_server(server)
	rescue
		puts "Bad things have happend ${$!}"
		flash[:error] = self.class::REGISTER_FAILURE
	else
    	flash[:notice] = self.class::REGISTER_SUCCESS
  	end

    redirect_to action: "index"
  end

  def deregister
  	# TODO: Uncomment this if:
  	#
  	# We decide to allow users editing 
  	# dns records on s3 as well or spawn this into
  	# multiple instances (to scale horizontally)
  	# then we need to add uncomment this, to 
  	# ensure we consistently are dealing with 
  	# latest records from amazon.
  	#
    # AWS::Service::R53.reload_records()
    begin
	  	server = Server.find(params[:id])
	    AWS::Service::R53.rm_server(server)
	rescue
		puts "Bad things have happend ${$!}"
		flash[:error] = self.class::UNREGISTER_FAILURE
	else
    	flash[:notice] = self.class::UNREGISTER_SUCCESS
  	end
    redirect_to action: "index"
  end

end
