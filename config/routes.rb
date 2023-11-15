Rails.application.routes.draw do
  root 'welcome#index'
  
  devise_for :users, controllers: { sessions: "users/sessions" }

  resources :user_logs, only: [:index, :show, :destroy]

  resources :units do
    collection do
      get 'import'
      post 'import' => 'units#import'
    end
    resources :users, :controller => 'unit_users'

    member do 
      # get 'index'
      get 'new_child_unit' => 'units#new'
      get 'child_units' => 'units#index'
      # get 'update_unit'
      # get 'destroy_unit'
    end
  end

  resources :users do
    member do
      get 'to_reset_pwd'
      patch 'reset_pwd'
      post 'lock' => 'users#lock'
      post 'unlock' => 'users#unlock'
    end
    resources :roles, :controller => 'user_roles'
  end

  resources :up_downloads do
    collection do 
      get 'up_download_import'
      post 'up_download_import' => 'up_downloads#up_download_import'
      
      get 'to_import'
      
      
    end
    member do
      get 'up_download_export'
      post 'up_download_export' => 'up_downloads#up_download_export'
    end
  end

  resources :expresses do
    collection do 
      get 'return_scan'
      post 'return_scan'
      post 'return_save'
      get 'resend_scan'
      post 'resend_scan'
      post 'find_resend_express_result'
      get 'tkzd'
      post 'tkzd'
      post 'get_new_express_no_and_print'
      get 'change_express_addr'
      post 'change_express_addr'
      get 'set_no_modify'
      post 'set_no_modify'
      get 'anomaly_done'
      post 'anomaly_done'
      get 'anomaly_index'
      post 'express_export'
    end
  end

  resources :batches do
    member do
      get 'done'
      post 'done' => 'batches#done'
    end
  end

  resources :orders do
    collection do 
      get 'change_order_addr'
      post 'change_order_addr'
      get 'set_no_modify'
      post 'set_no_modify'
    end
  end
    


  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
