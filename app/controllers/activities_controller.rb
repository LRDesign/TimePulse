require 'bcrypt'
class ActivitiesController < ApplicationController
  before_action :restrict_access, only: [:update, :create, :destroy]

  def index
    @activities = Activity.all
    render json:Activity.all
  end

  def show
   render json:Activity.last
  end

  def edit
  end

  def create
    p params

    @activity = Activity.new(activity_params)
      if @activity.save
        render json: @activity, status: 201
      else
        render json: @activity.errors, status: 422
      end
  end

  def update
    p params

    @activity = Activity.find(params[:activity][:id])
      if @activity.update(activity_params)
        render json: @activity, status: 200
      else
        render json: @activity.errors, status: 422
      end
  end

  def destroy
    @activity.destroy
      render json: :no_content

  end

private

  def activity_params
    params.require(:activity).permit(:description, :project_id, :source)
  end

  #should we leave this here or put it in Application Controller for global use?
  def restrict_access
    p request.headers["Authorization"]
    # p request.headers["login"]
    p User.where(:login => request.headers["login"]).first
    unless user = User.where(:login => request.headers["login"]).first
      render json: "authorization failed no user" , status: 403
    end
    p utoken = request.headers["Authorization"]
    # p etoken = BCrypt::Password.create(utoken)
    # p BCrypt::Password.new(user.encrypted_token)
    if BCrypt::Password.new(user.encrypted_token) == utoken
      return true
    else
      render json: "authorization failed wrong token", status: 403
    end
  end


end