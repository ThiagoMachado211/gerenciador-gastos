class Users::SubscriptionsController < Users::BaseController
  def show
  end

  def create
    redirect_to users_subscription_path, notice: "Upgrade solicitado."
  end

  def destroy
    redirect_to users_subscription_path, notice: "Assinatura cancelada."
  end
end