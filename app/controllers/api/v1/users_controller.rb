class Api::V1::UsersController < ApplicationController
  before_action :set_user, except: [ :index, :me ]

  def index
    authorize User
    users = policy_scope(User)
    render json: UserSerializer.new(users).serializable_hash
  end

  def me
    authorize current_user
    render json: UserSerializer.new(current_user).serializable_hash
  end

  def show
    authorize @user
    render json: UserSerializer.new(@user).serializable_hash
  end

  def update
    authorize @user
    if @user.update(user_params)
      render json: UserSerializer.new(@user).serializable_hash, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update_password
    authorize @user
    unless @user.authenticate(password_params[:current_password])
      return render json: { errors: [ "Current password is incorrect" ] }, status: :unprocessable_content
    end

    # Validate password and password_confirmation are not empty
    if password_params[:password].blank?
      return render json: { errors: [ "Password can't be blank" ] }, status: :unprocessable_content
    end

    if @user.update(password: password_params[:password], password_confirmation: password_params[:password_confirmation])
      render json: { message: "Password updated successfully" }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    authorize @user
    @user.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :phone, profile: {})
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
