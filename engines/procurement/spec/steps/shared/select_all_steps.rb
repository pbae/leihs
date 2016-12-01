module SelectAll
  step 'I select all :string_with_spaces' do |string_with_spaces|
    text = case string_with_spaces
           when 'categories'
             _('Categories')
           when 'budget periods'
             _('Budget periods')
           when 'organisations'
             _('Organisations')
           when 'states'
             _('State of Request')
           when 'states'
             _('State of Request')
           when "inspector's priorities"
             _("Inspector's priority")
           else
             raise
           end
    within '#filter_panel .form-group', text: text, match: :prefer_exact do
      case string_with_spaces
      when 'states'
        all(:checkbox, minimum: 4).each { |x| x.set true }
      when "inspector's priorities"
        all(:checkbox, minimum: 4).each { |x| x.set true }
      else
        within '.btn-group' do
          find('button.multiselect').click # NOTE open the dropdown
          expect(current_scope[:class]).to include 'open'

          within '.dropdown-menu' do
            check _('Select all')
          end

          # NOTE close the dropdown
          find("button.multiselect[aria-expanded='true']").click
          expect(current_scope[:class]).not_to include 'open'
        end
      end
    end
  end
end
