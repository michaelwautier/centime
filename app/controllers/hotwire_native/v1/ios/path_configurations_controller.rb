class HotwireNative::V1::Ios::PathConfigurationsController < ActionController::Base
  def show
    render json: HotwireNative::PathConfiguration.rules(platform: :ios)
  end
end
