class ApplicationController < ActionController::Base
  include DeviceFormat
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!

  private

  # Parses ?month=YYYY-MM, falling back to the current month.
  def parsed_month
    Date.parse("#{params[:month]}-01")
  rescue ArgumentError, TypeError
    Date.current
  end
end
