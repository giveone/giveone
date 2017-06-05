class NonprofitsController < ApplicationController
  before_filter :find_nonprofit, only: [:show]
  before_filter :page_meta_tags, only: [:show]

  respond_to :html, except: [:upcoming_report]
  respond_to :json, only: [:upcoming_report]

  def index
    @nonprofits = Nonprofit.is_public
      order("id ASC")
  end

  def show
    @current_nonprofit = Nonprofit.is_public.find_by_param(params[:id]).featured_on

    @hide_header = true
    unless current_subscriber?
      @hide_footer = true
    end
  end

  protected

  def find_nonprofit
    @nonprofit = Nonprofit.is_public.find_by_param(params[:id])
  end

  def page_meta_tags
    @meta_tags["og:title"]            = @nonprofit.name
    @meta_tags["og:image"]            = @nonprofit.photo.url(:medium)
    @meta_tags["og:url"]              = nonprofit_url(@nonprofit)
    @meta_tags["og:description"]      = @nonprofit.blurb
    @meta_tags["twitter:card"]        = "summary_large_image"
    @meta_tags["twitter:title"]       = "#{Rails.application.secrets.name} Nonprofit for #{@nonprofit.featured_on.try(:to_s, :short_name)}: #{@nonprofit.name}"
    @meta_tags["twitter:image:src"]   = "#{@nonprofit.photo.url(:medium).gsub(/https/, 'http')}"
    @meta_tags["twitter:description"] = @nonprofit.blurb
  end
end
