require 'rails_helper'

RSpec.describe DomainController, type: :controller do
	describe "POST register" do
		pending "should register a non-registered server"
	end
	describe "POST deregister" do
		pending "should deregister a giving server"
	end
	describe "GET index" do
		it "should assigned @servers for page tables" do
			cluster = Cluster.create(name: 'Waffi', subdomain: 'wfi')
			server = Server.create(
				cluster_id: cluster.id,
				ip_string: '10.10.10.10',
				friendly_name: 'bar',
			)

			get :index
			expect(assigns(:servers)).to eq([server])

			server.destroy
			cluster.destroy
		end
		it "should render the index template" do
			get :index
			expect(response).to render_template("index")
			expect(response.status).to eq(200)
		end
	end
end
