class Admin::ActivationsController < Admin::BaseController
  before_filter :find_activation, only: [:show, :edit, :update, :destroy]

  respond_to :html, :json

  def index
    @activations = Activation.
      order("happening_on ASC")
  end

  def show
    render :edit
  end

  def new
    @date = params[:date].to_s.to_date
    @activation = Activation.new(happening_on: @date)
  end

  def create
    @activation = Activation.new(activation_params)
    @activation.save
    respond_with(@activation, location: admin_activations_url)
  end

  def edit
  end

  def update
    @activation.update_attributes(activation_params)
    respond_with(@activation, location: edit_admin_activation_url(@activation))
  end

  def destroy
    @activation.destroy
    respond_with(@activation, location: admin_activations_url)
  end

  private
  def activation_params
    params.require(:activation).permit(:category_id, :name, :sponsor, :blurb, :description, :url, :spots_available, :time_range, :happening_on, :where, :is_public, :photo)
  end

  def find_activation
    @activation = Activation.find_by_param(params[:id])
  end
end
