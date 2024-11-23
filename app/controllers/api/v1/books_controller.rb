# frozen_string_literal: true

require_relative "../../../representers/books_representer"

module Api
  module V1
    # Books controller
    class BooksController < ApplicationController
      MAX_PAGINATION_LIMIT = 100

      before_action :set_book, only: %i[show destroy update]
      before_action :set_author, only: %i[update create]

      def index
        books = Book.limit(limit).offset(params[:offset])
        books = books.where(author_id: params[:author_id]) if params[:author_id]
        render json: BooksRepresenter.new(books, request).as_json
      end

      def show
        render json: BooksRepresenter.new(@book, request).as_json
      end

      # rubocop:disable Metrics/MethodLength

      # Create a new book in the database.
      # Duplicate books from the same author are not allowed
      def create
        # The author ID was not provided, meaning this is a new other or they
        # chose to provide the full details of the author.
        if @author.nil?
          @author = Author.find_or_create_by(author_params)
        end

        db_book = @author.books.find_by(title: book_params[:title])

        if db_book
          render json: {
                   error: "A book with this title and author already exists"
                 }, status: :conflict
          return
        end

        book = @author.books.create(book_params)
        if book.persisted?
          render json: BooksRepresenter.new(book, request).as_json,
                 status: :created
        else
          render json: { errors: book.errors.full_messages },
                 status: :unprocessable_content
        end
      end

      # rubocop:enable Metrics/MethodLength

      def update
        if @book.update(book_params)
          render json: BooksRepresenter.new(@book, request).as_json
        else
          render json: { errors: @book.errors.full_messages },
                 status: :unprocessable_content
        end
      end

      def destroy
        @book.destroy
        head :no_content
      end

      private

      def limit
        [
          params.fetch(:limit, MAX_PAGINATION_LIMIT).to_i,
          MAX_PAGINATION_LIMIT
        ].min
      end

      def book_params
        params.require(:book).permit(:title, :author_id)
      end

      # rubocop:disable Metrics/MethodLength
      def set_book
        if params[:author_id]
          @book = Book.find_by(id: params[:id], author: @author)
          if @book.nil?
            return render json: {
                            error: "Book not found for the given author"
                          }, status: :not_found
          end
        else
          @book = Book.find_by(id: params[:id])
        end

        if @book.nil?
          render json: {
                   error: "Couldn't find Book with 'id'=#{params[:id]}"
                 }, status: :not_found
        end
      end

      # rubocop:enable Metrics/MethodLength

      def set_author
        return unless params[:author_id]

        @author = Author.find_by(id: author_id)

        if @author.nil?
          render json: {
                   error: "Author with ID #{author_id} not found."
                 }, status: :not_found
        end
      end

      def author_params
        params.require(:author).permit(:first_name, :last_name, :age)
      end
    end
  end
end
