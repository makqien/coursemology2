# frozen_string_literal: true
require 'rwordnet'
class Course::Assessment::Question::TextResponseComprehensionSolution < ApplicationRecord
  self.table_name = 'course_assessment_question_text_response_compre_solutions'

  enum solution_type: [:compre_lifted_word, :compre_keyword]

  before_validation :remove_blank_solution,
                    :strip_whitespace_solution,
                    :convert_solution_to_lemma
                    :strip_whitespace_solution_lemma

  belongs_to :point, class_name: Course::Assessment::Question::TextResponseComprehensionPoint.name,
                     inverse_of: :solutions

  def auto_gradable_solution?
    !solution.empty?
  end

  def initialize_duplicate(duplicator, other)
    self.point = duplicator.duplicate(other.point)
  end

  private

  def comprehension_solution?
    compre_keyword? || compre_lifted_word?
  end

  def remove_blank_solution
    solution.reject!(&:blank?)
  end

  def strip_whitespace_solution
    solution.each(&:strip!)
  end

  def convert_solution_to_lemma
    solution_lemma.clear
    solution.each { |s| solution_lemma.push(WordNet::Synset.morphy_all(s).first || s) }
  end

  def strip_whitespace_solution_lemma
    solution_lemma.each(&:strip!)
  end
end
