# frozen_string_literal: true

# Base controller
class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_content
  rescue_from ActionController::RoutingError, with: :invalid_route
  rescue_from ActionController::ParameterMissing, with: :bad_request

  def invalid_route
    render json: {
      error: 'Route not found',
      endpoint: request.path,
      method: request.method
    }, status: :not_found
  end

  private

    def not_found(error)
      render json: {
        error:, success: false
      }, status: :not_found
    end

    def unprocessable_content(error)
      render json: {
        error:, success: false
      }, status: :unprocessable_content
    end

    def bad_request(error)
      render json: {
        error:, success: false
      }, status: :bad_request
    end
end
