Rails.application.routes.draw do
  get 'domain/index'
  get 'domain', to: 'domain#index'

  post '/domain/register/:id', to: 'domain#register', as: 'domain_register'
  delete '/domain/deregister/:id', to: 'domain#deregister', as: 'domain_deregister'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'domain#index'
end
