# frozen_string_literal: true

class UsersController < ApplicationController
  include JwtAuthenticatable

  def index
    users = 10.times.map do |i|
      id = i + 1
      { id: id, name: "User No#{id}", email: "user#{id}@example.com" }
    end
    response.headers['Access-Control-Expose-Headers'] = 'X-Total-Count'
    response.headers['X-Total-Count'] = users.size

    render json: users
  end
end
