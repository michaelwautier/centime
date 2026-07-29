class ConsentMailer < ApplicationMailer
  def expiring_soon
    @bank_connection = params[:bank_connection]
    @user = @bank_connection.user

    mail to: @user.email,
         subject: "Your #{@bank_connection.institution_name} connection expires soon"
  end
end
