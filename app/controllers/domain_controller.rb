class DomainController < ApplicationController
  
  def index 
  	@servers = Server.all.order(friendly_name: :asc)
  end

  def register
  end

  def deregister
  end
end
