module ErrorHandler
  extend ActiveSupport::Concern
  
  included do
    rescue_from ErrorHelper::ApiError, with: :handle_error
    rescue_from Exception, with: :general_handler
  end

  private
  def handle_error(e)
    data = {}
    data.merge! e.options if e.respond_to? :options
    render_failure_json e.message, data, e
  end

  def general_handler(e)
    render_failure_json e.message, {}, e
  end

end