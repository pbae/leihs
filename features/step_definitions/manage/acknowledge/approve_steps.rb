# -*- encoding : utf-8 -*-

Given(/^I navigate to the (open orders|hand over visits|take back visits)$/) do |arg1|
  if current_path != manage_daily_view_path(@current_inventory_pool)
    step 'I open the daily view'
  end

  s = case arg1
        when 'open orders'
          _('Open Orders')
        when 'hand over visits'
          _('Hand Overs')
        when 'take back visits'
          _('Take Backs')
        else
          raise
      end
  find('.button', text: s).click
end

When(/^I quick approve a submitted order$/) do
  @contract ||= @current_inventory_pool.reservations_bundles.submitted.order('RAND ()').detect{|o| o.approvable? }
  within(".line[data-id='#{@contract.id}']") do
    find('[data-order-approve]', text: _('Approve')).click
  end
end

Then(/^I see a link to the hand over process of that order$/) do
  find(".line[data-id='#{@contract.id}'] .line-actions a[href='#{manage_hand_over_path(@current_inventory_pool, @contract.user)}']", text: _('Hand Over'))
end

Given /^I try to approve a contract that has problems$/ do
  @contract =  @current_inventory_pool.reservations_bundles.submitted.order('RAND ()').detect{|o| not o.approvable?}
  step 'I quick approve a submitted order'
  find('.modal')
end

Then /^I got an information that this contract has problems$/ do
  find('.modal .row.emboss.red')
end

When /^I approve anyway$/ do
  within('.modal') do
    find('.dropdown-toggle').click
    find('.dropdown-item[data-approve-anyway]').click
  end
  step 'the modal is closed'
end

Then /^this contract is approved$/ do
  find(".line[data-id='#{@contract.id}']", text: _('Approved'))

  approved_contract = @current_inventory_pool.reservations_bundles.approved.find_by(user_id: @contract.user)
  @contract.reservations.each do |line|
    expect(approved_contract.reservations.include? line).to be true
    expect(line.reload.status).to eq :approved
  end
  step 'that contract has been deleted'
end
