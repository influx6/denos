require 'rails_helper'

RSpec.describe DomainController, type: :controller do
	describe "GET index" do
		it "should assigned @servers for page tables" do
			server = Server.create(
				ip_string: '10.10.10.10',
				friendly_name: 'bar',
			)

			get :index
			expect(assigns(:servers)).to eq([server])
		end
		it "should render the index template" do
			get :index
			expect(response).to render_template("index")
		end
	end
end
