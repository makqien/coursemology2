# frozen_string_literal: true
class Course::Discussion::TopicsController < Course::ComponentController
  load_and_authorize_resource :discussion_topic, through: :course, instance_name: :topic,
                                                 class: Course::Discussion::Topic.name,
                                                 parent: false
  def index
    @topics = @topics.page(page_param)
  end
end