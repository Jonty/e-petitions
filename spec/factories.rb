require 'factory_girl'

FactoryGirl.define do
  factory :admin_user do
    sequence(:email) {|n| "admin#{n}@example.com" }
    password              "Letmein1!"
    password_confirmation "Letmein1!"
    sequence(:first_name) {|n| "AdminUser#{n}" }
    sequence(:last_name) {|n| "AdminUser#{n}" }
    force_password_reset  false
  end

  factory :sysadmin_user, :parent => :admin_user do
    role "sysadmin"
  end

  factory :moderator_user, :parent => :admin_user do
    role "moderator"
  end

  factory :archived_petition do
    sequence(:title) { |n| "Petition #{n}" }
    description "Petition description"
    signature_count 0
    opened_at { 2.years.ago }

    trait :response do
      response "Petition response"
    end

    trait :open do
      state "open"
      signature_count 100
    end

    trait :closed do
      state "open"
      signature_count 100
      closed_at { 1.year.ago }
    end

    trait :rejected do
      reason_for_rejection "Petition rejection"
      state "rejected"
    end
  end

  factory :petition do
    transient do
      creator_signature_attributes { {} }
      sponsors_signed false
      sponsor_count { AppConfig.sponsor_count_min }
    end
    sequence(:title) {|n| "Petition #{n}" }
    action "Petition action"
    description "Petition description"
    creator_signature  { |cs| cs.association(:signature, creator_signature_attributes.merge(:state => Signature::VALIDATED_STATE)) }
    after(:build) do |petition, evaluator|
      evaluator.sponsor_count.times do
        petition.sponsors.build(FactoryGirl.attributes_for(:sponsor))
      end
    end
  end

  factory :pending_petition, :parent => :petition do
    state  Petition::PENDING_STATE
    creator_signature  { |cs| cs.association(:signature, creator_signature_attributes.merge(:state => Signature::PENDING_STATE)) }
  end

  factory :validated_petition, :parent => :petition do
    state  Petition::VALIDATED_STATE

    after(:create) do |petition, evaluator|
      petition.sponsors.each do |sp|
        sp.create_signature!(FactoryGirl.attributes_for(:validated_signature)) if evaluator.sponsors_signed
      end
    end
  end

  factory :sponsored_petition, :parent => :petition do
    state  Petition::SPONSORED_STATE
  end

  factory :open_petition, :parent => :petition do
    state      Petition::OPEN_STATE
    open_at    { Time.current }
    closed_at  { open_at + 1.day }
  end

  factory :closed_petition, :parent => :petition do
    state      Petition::OPEN_STATE
    open_at    { 10.days.ago }
    closed_at  { 1.day.ago }
  end

  factory :rejected_petition, :parent => :petition do
    state  Petition::REJECTED_STATE
    rejection_code "duplicate"
  end

  factory :hidden_petition, :parent => :petition do
    state      Petition::HIDDEN_STATE
  end

  factory :signature do
    sequence(:name) {|n| "Jo Public #{n}" }
    sequence(:email) {|n| "jo#{n}@public.com" }
    postcode            "SW1A 1AA"
    country             "United Kingdom"
    uk_citizenship       '1'
    notify_by_email      '1'
    state                Signature::VALIDATED_STATE
  end

  factory :pending_signature, :parent => :signature do
    state      Signature::PENDING_STATE
  end

  factory :validated_signature, :parent => :signature do
    state      Signature::VALIDATED_STATE
  end

  sequence(:sponsor_email) { |n| "sponsor#{n}@example.com" }

  factory :sponsor do
    transient do
      email { generate(:sponsor_email) }
    end

    association :petition

    trait :pending do
      signature  { |s| s.association(:pending_signature, petition: s.petition, email: s.email) }
    end

    trait :validated do
      signature  { |s| s.association(:validated_signature, petition: s.petition, email: s.email) }
    end
  end

  factory :system_setting do
    sequence(:key)  {|n| "key#{n}"}
  end

  sequence(:constituency_id) { |n| (1234 + n).to_s }
  sequence(:mp_id) { |n| (4321 + n).to_s }


  factory :constituency_petition_journal do
    constituency_id { generate(:constituency_id) }
    association :petition
  end
end
