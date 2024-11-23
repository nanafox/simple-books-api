class ApiHealthController < ApplicationController
  def index
    render json: {
      message: "API is running smoothly",
      status: 200,
      success: true
    }
  end

  def stats
    render json: {
      message: "API Stats retrieved successfully",
      status: 200,
      success: true,
      data: {
        books_count: Book.count
      }
    }
  end
end
