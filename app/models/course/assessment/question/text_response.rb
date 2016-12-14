# frozen_string_literal: true
class Course::Assessment::Question::TextResponse < ActiveRecord::Base
  acts_as :question, class_name: Course::Assessment::Question.name

  validate :validate_grade

  has_many :solutions, class_name: Course::Assessment::Question::TextResponseSolution.name,
                       dependent: :destroy, foreign_key: :question_id, inverse_of: :question

  accepts_nested_attributes_for :solutions

  def auto_gradable?
    !solutions.empty?
  end

  # Method provides readability to identifying whether a question is a file upload question.
  #  Used with the front-end translations.
  def file_upload_question?
    hide_text
  end

  def question_type
    if file_upload_question?
      I18n.t('activerecord.attributes.models.course/assessment/question/text_response.file_upload')
    else
      I18n.t('activerecord.attributes.models.course/assessment/question/text_response.text_response')
    end
  end

  def auto_grader
    Course::Assessment::Answer::TextResponseAutoGradingService.new
  end

  def attempt(submission, last_attempt = nil)
    answer = submission.text_response_answers.build(submission: submission, question: question)
    answer.answer_text = last_attempt.answer_text if last_attempt
    answer.acting_as
  end

  def initialize_duplicate(duplicator, other)
    copy_attributes(other)
    self.solutions = duplicator.duplicate(other.solutions)
  end

  private

  def validate_grade
    errors.add(:maximum_grade, :invalid_grade) if solutions.any? { |s| s.grade > maximum_grade }
  end
end
