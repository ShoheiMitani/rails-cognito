class UsersController < ApplicationController
  def index
    response = 10.times.map do |i|
      id = i + 1
      { id: id, name: "User No#{id}", email: "user#{id}@example.com" }
    end

    render json: response
  end
end
