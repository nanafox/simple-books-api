module Api
  module V1
    class AuthorsController < ApplicationController
      def index
        render json: Author.all
      end
    end
  end
end
