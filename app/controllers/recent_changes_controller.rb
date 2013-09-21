class RecentChangesController < ApplicationController

  before_filter :authenticate_user!
  before_filter :not_submitter!
  load_and_authorize_resource :conference, parent: false

  def index
    @versions = Version.where(conference_id: @conference.id).order("created_at DESC").paginate(
      page: params[:page],
      per_page: params[:per_page])
  end

  def show
    @version = Version.where(conference_id: @conference.id, id: params[:id]).first
  end

end
