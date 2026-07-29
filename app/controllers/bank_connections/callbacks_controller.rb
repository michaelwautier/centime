module BankConnections
  class CallbacksController < ApplicationController
    def show
      connection = current_user.bank_connections.find_by!(reference: params[:ref])

      if CompleteRequisition.call(connection: connection)
        redirect_to bank_connections_path, notice: "#{connection.institution_name} connected — first sync is running."
      else
        redirect_to bank_connections_path, alert: "The bank connection could not be completed. Please try again."
      end
    rescue GoCardless::Error => e
      redirect_to bank_connections_path, alert: "Bank connection failed: #{e.message}"
    end
  end
end
