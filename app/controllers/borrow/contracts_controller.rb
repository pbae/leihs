class Borrow::ContractsController < Borrow::ApplicationController

  before_action only: [:current, :timed_out] do
    @grouped_and_merged_lines = \
      Contract.grouped_and_merged_lines(current_user.reservations.unsubmitted)
    @models = current_user.reservations.unsubmitted.map(&:model).uniq
    @inventory_pools = \
      current_user.reservations.unsubmitted.map(&:inventory_pool).uniq
  end

  def index
    respond_to do |format|
      format.json { @contracts = ReservationsBundle.filter params, current_user }
      format.html do
        @grouped_and_merged_lines = \
          Contract.grouped_and_merged_lines current_user.reservations.submitted
      end
    end
  end

  def current
  end

  def submit
    Contract.transaction do
      current_user.reservations.unsubmitted.each do |c|
        c.created_at = Time.zone.now
        if c.user.delegation?
          c.delegated_user = \
            c.user.delegated_users.find(session[:delegated_user_id])
        end
      end
      if current_user \
          .reservations_bundles
          .unsubmitted
          .all? { |c| c.submit(params[:purpose]) }
        flash[:notice] = _('Your order has been successfully submitted, ' \
                           'but is NOT YET APPROVED.')
        redirect_to borrow_root_path
      else
        flash[:error] = \
          current_user
            .reservations
            .unsubmitted
            .flat_map { |c| c.errors.full_messages }
            .uniq
            .join("\n")
        redirect_to borrow_current_order_path
        raise ActiveRecord::Rollback
      end
    end
  end

  def remove
    current_user.reservations.unsubmitted.each(&:destroy)
    redirect_to borrow_root_path
  end

  def remove_reservations(line_ids = params[:line_ids])
    reservations = current_user.reservations.unsubmitted.find(line_ids)
    reservations.each do |l|
      current_user
        .reservations_bundles
        .unsubmitted
        .each { |c| c.remove_line(l) }
    end
    redirect_to borrow_current_order_path
  end

  def timed_out
    flash[:error] =  \
      _('%d minutes passed. The items are not reserved for you any more!') \
      % Setting.timeout_minutes
    @timed_out = true
    render :current
  end

  def delete_unavailables
    current_user.reservations.unsubmitted.each { |l| l.delete unless l.available? }
    redirect_to \
      borrow_current_order_path,
      flash: { success: _('Your order has been modified. ' \
                          'All reservations are now available.') }
  end

end
