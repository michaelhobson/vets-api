# frozen_string_literal: true

DebtsApi::Engine.routes.draw do
  namespace :v0, defaults: { format: :json } do
    resources :financial_status_reports, only: %i[create] do
      collection do
        get :download_pdf
      end
    end

    post 'calculate_monthly_expenses', to: 'financial_status_reports_calculations#monthly_expenses'
    post 'calculate_all_expenses', to: 'financial_status_reports_calculations#all_expenses'
    post 'calculate_monthly_income', to: 'financial_status_reports_calculations#monthly_income'
  end
end
