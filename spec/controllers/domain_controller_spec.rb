require 'rails_helper'

RSpec.describe DomainController, type: :controller do
  cluster = nil
  server = nil
  before :each do
    cluster = Cluster.create(name: 'Waffi', subdomain: 'wfi')
    server = Server.create(
        cluster_id: cluster.id,
        ip_string: '10.10.10.10',
        friendly_name: 'bar',
    )
  end

  describe "GET index" do
    it "should assigned @servers for page tables" do
      get :index
      expect(assigns(:servers)).to eq([server])
      expect(AWS::Service::R53.has_server(server)).to eq(false)
    end
    it "should render the index template" do
      get :index
      expect(response).to render_template("index")
      expect(response.status).to eq(200)
    end
  end
  describe "POST register" do
    it "should register a non-registered server" do
      post :register, params: { id: server.id }

      expect(response).to redirect_to :root
      expect(AWS::Service::R53.has_server(server)).to eq(true)
    end
  end
  describe "POST deregister" do
    it "should deregister a giving server" do
      delete :deregister, params: { id: server.id }

      expect(response).to redirect_to :root
      expect(AWS::Service::R53.has_server(server)).to eq(false)
    end
  end
end
