FactoryGirl.define do
  factory :procurement_request, class: Procurement::Request do
    user { FactoryGirl.create(:procurement_access, :requester).user }

    association :budget_period, factory: :procurement_budget_period
    association :category, factory: :procurement_category

    article_name { Faker::Lorem.sentence }
    motivation { Faker::Lorem.sentence }
    price { 123 }
    requested_quantity { 5 }
    approved_quantity { nil }
    template { nil }
    priority { ['high', 'normal'].sample }

    before :create do |request|
      if request.template
        request.article_name = request.template.article_name
        request.article_number = request.template.article_number
        request.price = request.template.price
        request.supplier_name = request.template.supplier_name
      end
    end

    trait :full do
      organization do
        FactoryGirl.create(:procurement_organization, :with_parent)
      end

      association :model
      association :supplier
      association :location
      association :template, factory: :procurement_template

      approved_quantity 5
      order_quantity 5
      price_currency 'CHF'
      replacement false
      supplier_name Faker::Company.name
      receiver Faker::Name.name
      location_name Faker::Address.street_name
      inspection_comment Faker::Lorem.sentence
      inspector_priority :medium
    end

  end
end
