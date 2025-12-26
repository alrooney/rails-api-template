Rails.application.routes.draw do
  mount Rswag::Api::Engine => "/api-docs"
  mount Rswag::Ui::Engine => "/api-docs"
  mount MissionControl::Jobs::Engine, at: "/jobs"

  namespace :api do
    namespace :v1 do
      resources :users, only: [ :index, :show, :update, :destroy ] do
        collection do
          get :me
        end
        member do
          patch :password, to: "users#update_password"
        end
      end

      post "login", to: "authentication#login"
      post "refresh", to: "authentication#refresh"
      delete "logout", to: "authentication#logout"
      post "register", to: "registrations#create"
      post "confirm_email", to: "registrations#confirm_email"
      post "confirm_phone", to: "registrations#confirm_phone"
      post "send_phone_confirmation", to: "registrations#send_phone_confirmation"
      post "send_email_confirmation", to: "registrations#send_email_confirmation"
      post "password/reset", to: "passwords#create"
      put "password/reset/:token", to: "passwords#update"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
