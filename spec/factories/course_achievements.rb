# frozen_string_literal: true
FactoryGirl.define do
  factory :course_achievement, class: Course::Achievement.name, aliases: [:achievement] do
    course
    sequence(:title) { |n| "Achievement #{n}" }
    sequence(:description) { |n| "Awesome achievement #{n}" }
    sequence(:weight)
    published true

    trait :with_badge do
      badge { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'minion.png')) }
    end
  end
end
