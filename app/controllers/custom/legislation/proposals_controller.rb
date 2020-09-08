class Legislation::ProposalsController < Legislation::BaseController
  include CommentableActions
  include FlagActions
  include ImageAttributes

  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary]
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :destroy_map_location_association, only: :update

  before_action :authenticate_user!, except: [:index, :show, :map, :summary]
  load_and_authorize_resource :process, class: "Legislation::Process"
  load_and_authorize_resource :proposal, class: "Legislation::Proposal", through: :process

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders %w[confidence_score created_at], only: :index
  has_orders %w[most_voted newest oldest], only: :show

  helper_method :resource_model, :resource_name
  respond_to :html, :js

  def show
    super
    legislation_proposal_votes(@process.proposals)
    @document = Document.new(documentable: @proposal)
    if request.path != legislation_process_proposal_path(params[:process_id], @proposal)
      redirect_to legislation_process_proposal_path(params[:process_id], @proposal),
                  status: :moved_permanently
    end
  end

  def create
    @proposal = Legislation::Proposal.new(proposal_params.merge(author: current_user))

    if @proposal.save
      redirect_to legislation_process_proposal_path(params[:process_id], @proposal), notice: I18n.t("flash.actions.create.proposal")
    else
      render :new
    end
  end

  def index_customization
    load_successful_proposals
    load_featured unless @proposal_successful_exists
  end

  def vote
    @proposal.register_vote(current_user, params[:value])
    legislation_proposal_votes(@proposal)
  end

  private

    def proposal_params
      params.require(:legislation_proposal).permit(:legislation_process_id, :title,
                    :summary, :description, :video_url, :tag_list,
                    :terms_of_service, :geozone_id, :skip_map,
                    image_attributes: image_attributes,
                    documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id],
                    map_location_attributes: [:latitude, :longitude, :zoom, :legislation_process_id])
    end
    
    def destroy_map_location_association
      map_location = params[:legislation][:map_location_attributes] #needs testing
      if map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?
        MapLocation.destroy(map_location[:id])
      end
    end
    
    def resource_model
      Legislation::Proposal
    end

    def resource_name
      "proposal"
    end

    def load_successful_proposals
      @proposal_successful_exists = Legislation::Proposal.successful.exists?
    end
end
