# frozen_string_literal: true
module Course::Assessment::QuestionsConcern
  extend ActiveSupport::Concern

  # Attempts the given set of questions.
  #
  # This will create answers for questions without any answers which are not being attempted, and
  # return them in the same order as specified.
  #
  # @param [Course::Assessment::Submission] submission The submission which will contain the
  #   answers.
  # @return [Array<Course::Assessment::Answer>] The answers for the questions, in the same order
  #   specified. Newly initialized answers will not be persisted.
  def attempt(submission)
    attempting_answers = submission.answers.latest_answers.
                         merge(submission.answers.with_attempting_state).
                         where(question: self).
                         map { |answer| [answer.question, answer] }.to_h

    map do |question|
      attempting_answers.fetch(question) { question.attempt(submission) }
    end
  end

  # Returns the questions which do not have a answer or correct answer.
  #
  # @param [Course::Assessment::Submission] submission The submission which contains the answers.
  # @return [Array<Course::Assessment::Question>]
  def not_correctly_answered(submission)
    where.not(id: submission.answers.where(correct: true).select(:question_id))
  end

  # Return the question at the given index. The next unanswered question will be returned if
  # the question at the index is not accessible.
  #
  # @param [Course::Assessment::Submission] submission The submission which contains the answers.
  # @param [Fixnum] current_index The index of the question, it's zero based.
  # @return [Array<Course::Assessment::Question>] The question at the given index or next
  #   unanswered question, whichever comes first.
  def step(submission, current_index)
    current_index = 0 if current_index < 0
    max_index = index(next_unanswered(submission) || last)

    # Return a +ActiveRecord::AssociationRelation+, so that the scope can be attempted.
    where(id: fetch([current_index, max_index].min))
  end

  # Return the next unanswered question.
  #
  # @param [Course::Assessment::Submission] submission The submission which contains the answers.
  # @return [Course::Assessment::Question|nil] the next unanswered question or nil if all
  #   questions have been correctly answered.
  def next_unanswered(submission)
    correctly_answered_questions = correctly_answered_questions(submission)
    return first if correctly_answered_questions.empty?

    reduce(nil) do |_, question|
      break question unless correctly_answered_questions.include?(question)
    end
  end

  private

  # Retrieves the correctly answered questions from the given submission.
  #
  # @param [Course::Assessment::Submission] submission The submission which contains the answers.
  # @return [Array<Course::Assessment::Question>] The questions which were correctly answered.
  def correctly_answered_questions(submission)
    where(id: submission.answers.where(correct: true).select(:question_id))
  end
end
