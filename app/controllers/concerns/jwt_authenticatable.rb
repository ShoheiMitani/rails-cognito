# frozen_string_literal: true

module JwtAuthenticatable
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Token::ControllerMethods

  included do
    before_action :authenticate_device!
  end

  attr_reader :current_user

  private

  def authenticate_device!
    authenticate_token || render_unauthorized
  end

  def authenticate_token
    authenticate_with_http_token do |token|
      payload = jwt_decode(token)
      # Find user from db if necessary
      @current_user = payload['email'] if verify_jwt_content(payload['aud'], payload['exp'])
    end
  end

  def jwt_decode(token)
    JSON::JWT.decode(token, public_key(token))
  rescue => e
    Rails.logger.error e
    {}
  end

  def verify_jwt_content(aud, exp)
    return false if aud != ENV['APP_CLIENT_ID']

    Time.at(exp) >= Time.current
  end

  def render_unauthorized
    headers['WWW-Authenticate'] = %(Bearer realm="token_required")
    raise ArgumentError, "Invalid authorization header: #{request.authorization}"
  end

  def public_key(token)
    decoded_token = JWT.decode(token, nil, false)
    kid = decoded_token.second['kid']

    jwk = credential['keys'].first { |k| k['kid'] == kid }

    JSON::JWK.new(jwk).to_key
  end

  def credential
    return @credential if defined? @credential

    connection = Faraday.new(url: credential_url)
    response = connection.get ''
    @credential = JSON.parse(response.body)
  end

  def credential_url
    "https://cognito-idp.#{ENV['AWS_REGION']}.amazonaws.com/#{ENV['USER_POOL_ID']}/.well-known/jwks.json"
  end
end
