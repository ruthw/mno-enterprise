module MnoEnterprise::Concerns::Controllers::Jpi::V1::SubscriptionsController
  extend ActiveSupport::Concern

  #==================================================================
  # Instance methods
  #==================================================================
  # GET /mnoe/jpi/v1/organizations/1/subscriptions
  def index
    authorize! :manage_app_instances, parent_organization
    @subscriptions = MnoEnterprise::Subscription.includes(:product_instance, :product_pricing, :product_contract, :organization, :user, :'license_assignments.user', :'product_instance.product')
                                                .where(organization_id: parent_organization.id)
  end

  # GET /mnoe/jpi/v1/organizations/1/subscriptions/id
  def show
    authorize! :manage_app_instances, parent_organization
    @subscription = MnoEnterprise::Subscription.includes(:product_instance, :product_pricing, :product_contract, :organization, :user, :'license_assignments.user', :'product_instance.product')
                                                .where(organization_id: parent_organization.id, id: params[:id]).first
  end

  # POST /mnoe/jpi/v1/organizations/1/subscriptions
  def create
    authorize! :manage_app_instances, parent_organization

    subscription = MnoEnterprise::Subscription.new(subscription_update_params)
    subscription.relationships.organization = MnoEnterprise::Organization.new(id: parent_organization.id)
    subscription.relationships.user = MnoEnterprise::User.new(id: current_user.id)
    subscription.relationships.product_pricing = MnoEnterprise::ProductPricing.new(id: params[:subscription][:product_pricing_id])
    subscription.relationships.product_contract = MnoEnterprise::ProductContract.new(id: params[:subscription][:product_contract_id])
    subscription.save

    if subscription.errors.any?
      render json: subscription.errors, status: :bad_request
    else
      MnoEnterprise::EventLogger.info('subscription_add', current_user.id, 'Subscription added', subscription)
      head :created
    end
  end

  # PUT /mnoe/jpi/v1/organizations/1/subscriptions/abc
  def update
    authorize! :manage_app_instances, parent_organization

    subscription = MnoEnterprise::Subscription.where(organization_id: parent_organization.id, id: params[:id]).first
    return render_not_found('subscription') unless subscription
    subscription.update_attributes(subscription_update_params)

    if subscription.errors.any?
      render json: subscription.errors, status: :bad_request
    else
      MnoEnterprise::EventLogger.info('subscription_update', current_user.id, 'Subscription updated', subscription)
      head :ok
    end
  end

  protected

  def subscription_update_params
    params.require(:subscription).permit(:start_date, :max_licenses, :custom_data)
  end
end
