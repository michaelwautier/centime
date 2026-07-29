class HotwireNative::V1::Android::PathConfigurationsController < ActionController::Base
  def show
    render json: HotwireNative::PathConfiguration.rules(platform: :android)
  end
end
