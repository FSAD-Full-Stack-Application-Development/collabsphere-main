class AuthenticationController < ApplicationController
  skip_before_action :authorize_request, only: [:login, :register]

  # POST /auth/login
  def login
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: { 
        token: token, 
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          system_role: user.system_role
        }
      }, status: :ok
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  # POST /auth/register
  def register
    user = User.new(user_params)
    if user.save
      token = JsonWebToken.encode(user_id: user.id)
      render json: { 
        token: token, 
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          system_role: user.system_role
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :email, :password, :password_confirmation, :bio, :avatar_url, :system_role, :country)
  end
end
