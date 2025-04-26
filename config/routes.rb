Rails.application.routes.draw do
  root "audio_files#index"
  
  resources :audio_files, only: [:index] do
    collection do
      post :parse
      post :update_metadata
    end
  end
end 