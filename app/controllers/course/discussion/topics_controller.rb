# frozen_string_literal: true
class Course::Discussion::TopicsController < Course::ComponentController
  load_and_authorize_resource :discussion_topic, through: :course, instance_name: :topic,
                                                 class: Course::Discussion::Topic.name,
                                                 parent: false
  def index
    @topics = all_topics
  end

  def pending
    @topics = all_topics.pending_staff_reply
  end

  def my_students
    @topics = my_students_topics
  end

  def my_students_pending
    @topics = my_students_topics.pending_staff_reply
  end

  private

  def all_topics
    @topics.globally_displayed.ordered_by_updated_at.includes(:actable).page(page_param)
  end

  def my_students_topics
    my_student_ids = current_course_user ? current_course_user.my_students.pluck(:user_id) : []
    @topics = @topics.
              globally_displayed.
              ordered_by_updated_at.
              from_user(my_student_ids).
              includes(:actable).
              page(page_param)
  end
end
