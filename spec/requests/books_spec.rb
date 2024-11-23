# spec/requests/books_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Books API", type: :request do
  before do
    Book.destroy_all
    Author.destroy_all

    reset_primary_key_sequences
  end

  let!(:author_one) do
    FactoryBot.create(
      :author, first_name: "Rob", last_name: "Fitzpatrick", age: 45,
    )
  end

  let!(:author_two) do
    FactoryBot.create(:author, first_name: "John", last_name: "Doe", age: 23)
  end

  describe "Book Listing Endpoint: GET /books" do
    before do
      FactoryBot.create(:book, title: "The Mom Test", author: author_one)
      FactoryBot.create(:book, title: "Beautiful Days", author: author_two)
    end

    it "returns all books" do
      get api_v1_books_url

      expect(response).to have_http_status(:ok)
      expect(response_body[:data].size).to eq(2)

      expect(response_body).to eq(
        BooksRepresenter.new(
          Book.all, request
        ).as_json
      )
    end

    it "uses JSON as the content type for responses" do
      get api_v1_books_url

      expect(response.content_type).to eq("application/json; charset=utf-8")
    end

    describe "Pagination" do
      it "returns a subset of books based on the limit query parameter" do
        get api_v1_books_url, params: { limit: 1 }

        expect(response).to have_http_status(:ok)
        expect(response_body[:data].size).to eq(1)
        expect(Book.count).to eq 2
      end

      it "returns the next data set when offset query parameter is applied" do
        get api_v1_books_url, params: { offset: 1 }

        expect(response).to have_http_status(:ok)
        expect(response_body[:data].size).to eq(1)

        book = Book.last # get the second and last book we have

        expect(response_body).to eq(
          {
            message: "Books retrieved successfully",
            success: true,
            total_books: 2,
            current_number: 1,
            data: [
              {
                id: book.id,
                title: "Beautiful Days",
                author_id: 2,
                author_name: "John Doe",
                author_age: 23,
                created_at: book.created_at.iso8601(3),
                updated_at: book.updated_at.iso8601(3)
              }
            ]
          }
        )
      end

      it "returns no books when limit and offset are out of bounds" do
        get api_v1_books_url, params: { offset: 2, limit: 1 }

        expect(response).to have_http_status(:ok)
        expect(response_body[:data].size).to eq(0) # no data should be returned

        Book.last # get the second and last book we have

        expect(response_body).to eq(
          {
            message: "Books retrieved successfully",
            success: true,
            total_books: 2,
            current_number: 0,
            data: []
          }
        )
      end
    end
  end

  describe "Book Creation endpoint" do
    it "returns an error when the Author is omitted in the request body" do
      headers = { accept: "application/json" }
      initial_count = Book.count

      post(
        api_v1_books_url,
        params: {
          book: { title: "My new book" }
        }, headers:,
      )

      expect(Book.count).to eq(initial_count)
      expect(response).to have_http_status(:bad_request)
    end

    it "returns an error when the title is omitted in the request body" do
      initial_count = Book.count
      headers = { accept: "application/json" }

      post(
        api_v1_books_url,
        params: {
          author: { 'first_name': "Rob", last_name: "Fitzpatrick", age: 45 }
        }, headers:,
      )

      expect(Book.count).to eq(initial_count)
      expect(response).to have_http_status(:bad_request)
    end

    it "correctly creates a new book record with valid data" do
      headers = { accept: "application/json" }
      initial_count = Book.count

      post(
        api_v1_books_url,
        params: {
          book: { title: "The Mom Test" },
          author: { 'first_name': "Rob", last_name: "Fitzpatrick", age: 45 }
        }, headers:,
      )

      expect(response).to have_http_status(:created)
      expect(Book.count).to eq(initial_count + 1)

      new_book = Book.find(response_body.dig(:data, :id))

      expect(response_body).to eq(
        {
          message: "Book created successfully",
          success: true,
          data: {
            id: new_book.id,
            title: "The Mom Test",
            author_id: 1,
            author_name: "Rob Fitzpatrick",
            author_age: 45,
            created_at: new_book.created_at.iso8601(3),
            updated_at: new_book.updated_at.iso8601(3)
          }
        }
      )
    end
  end

  describe "Single Book Retrieval endpoint" do
    let!(:book) do
      FactoryBot.create(:book, author: author_two, title: "Sample Book")
    end

    it "returns the correct book when a valid ID is provided" do
      get api_v1_book_url(book.id)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/json; charset=utf-8")

      json_response = response_body

      expect(json_response.dig(:data, :id)).to eq(book.id)
      expect(json_response.dig(:data, :title)).to eq("Sample Book")
      expect(json_response.dig(:data, :author_name)).to eq("John Doe")
    end

    it "returns a not found error when an invalid ID is provided" do
      get api_v1_book_url(999_999)

      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to eq("application/json; charset=utf-8")

      expect(response_body[:error]).to eq(
        "Couldn't find Book with 'id'=999999"
      )
    end

    it "ensures each book has author details and a title" do
      get api_v1_book_url(book.id)

      expect(response).to have_http_status(:ok)

      expect(response_body[:message]).to eq("Book retrieved successfully")
    end
  end

  describe "Book Update endpoints" do
    let!(:book) do
      FactoryBot.create(:book, author: author_one, title: "Original Title")
    end

    describe "PUT /api/v1/books/:id" do
      it "updates the book with valid attributes" do
        put api_v1_book_url(book.id), params: {
                                        book: { title: "Updated Title" }
                                      }

        expect(response).to have_http_status(:ok)
        expect(response_body[:data][:title]).to eq(
          "Updated Title"
        )
        expect(book.reload.title).to eq("Updated Title")
      end

      it "returns an error when the title field is empty" do
        put api_v1_book_url(book.id), params: { book: { title: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /api/v1/books/:id" do
      it "partially updates the book" do
        patch api_v1_book_url(book.id),
              params: {
                book: { title: "A Very New Title" }
              }

        expect(response).to have_http_status(:ok)
        expect(response_body.dig(:data, :title)).to eq("A Very New Title")
        expect(book.reload.title).to eq("A Very New Title")
      end

      it "returns an error when updating with invalid data" do
        patch api_v1_book_url(book.id), params: { no_book: { no_title: "" } }

        expect(response).to have_http_status(:bad_request)
      end
    end

    it "returns not found for non-existent book" do
      put api_v1_book_url(999_999), params: { book: { title: "New Title" } }

      expect(response).to have_http_status(:not_found)
      expect(response_body).to have_key(:error)
    end
  end

  describe "Book Deletion endpoint" do
    let!(:book) do
      FactoryBot.create(:book, author: author_one, title: "Sample Book")
    end

    it "deletes a book by id" do
      initial_count = Book.count
      delete api_v1_book_url(book.id)

      expect(response).to have_http_status(:no_content)
      expect(Book.find_by(id: book.id)).to be_nil
      expect(Book.count).to eq(initial_count - 1)
    end

    it "returns not found for non-existent book" do
      initial_count = Book.count
      delete api_v1_book_url(999_999)

      expect(response).to have_http_status(:not_found)
      expect(response_body[:error]).to eq(
        "Couldn't find Book with 'id'=999999"
      )
      expect(Book.count).to eq(initial_count)
    end

    it "returns an error when the book id is not a number" do
      initial_count = Book.count
      delete api_v1_book_url("abc")

      expect(response).to have_http_status(:not_found)
      expect(response_body[:error]).to eq(
        "Couldn't find Book with 'id'=abc"
      )
      expect(Book.count).to eq(initial_count)
    end
  end
end
