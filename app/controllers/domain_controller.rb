class DomainController < ApplicationController

  def index 
  	@servers = Server.all
  end

  def register
  end

  def deregister
  end
end
