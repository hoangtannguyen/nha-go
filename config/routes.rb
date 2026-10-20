Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :shops, only: [ :index ]
  resources :products, only: [ :index, :show ]

  resource :cart, only: [ :show ]
  resources :cart_items, only: [ :create, :update, :destroy ]
  resources :orders, only: [ :create, :show ], param: :code

  # Danh sách phường/xã cho ô chọn địa chỉ lúc thanh toán
  get "dia-gioi/phuong-xa", to: "addresses#wards", as: :address_wards

  # Đăng ký nhận tin hàng mới
  get  "dang-ky-nhan-tin", to: "subscribers#new",    as: :new_subscriber
  post "dang-ky-nhan-tin", to: "subscribers#create", as: :subscribers
  get  "dang-ky-thanh-cong", to: "subscribers#thanks", as: :subscriber_thanks
  get  "huy-nhan-tin/:token", to: "subscribers#unsubscribe", as: :unsubscribe

  # GHTK gọi về để cập nhật trạng thái vận đơn
  post "webhooks/ghtk", to: "webhooks/ghtk#create", as: :ghtk_webhook

  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resources :orders, only: [ :index, :show, :update, :destroy ], param: :code
    resources :products, except: [ :show ] do
      resources :photos, only: [ :destroy ], controller: "product_photos"
    end
    resources :categories, except: [ :show ]
    resources :customers, only: [ :index, :show ]
    resources :subscribers, only: [ :index, :destroy ] do
      member { patch :toggle }
      collection do
        get :broadcast
        post :broadcast, action: :send_broadcast
      end
    end
    resources :admin_users, except: [ :show ]
    resource :settings, only: [ :edit, :update ] do
      delete "images/:image", action: :reset_image, as: :reset_image
    end

    root "dashboard#index"
  end

  # Defines the root path route ("/")
  root "shops#index"
end
