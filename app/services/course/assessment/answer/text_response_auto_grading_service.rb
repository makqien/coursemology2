# frozen_string_literal: true
require 'rwordnet'
class Course::Assessment::Answer::TextResponseAutoGradingService < \
  Course::Assessment::Answer::AutoGradingService
  def evaluate(answer)
    if answer.question.actable.comprehension_question?
      answer.correct, grade, messages = evaluate_answer_comprehension(answer.actable)
    else
      answer.correct, grade, messages = evaluate_answer(answer.actable)
    end
    answer.auto_grading.result = { messages: messages }
    grade
  end

  private

  # Grades the given answer.
  #
  # @param [Course::Assessment::Answer::TextResponse] answer The answer specified by the
  #   student.
  # @return [Array<(Boolean, Integer, Object)>] The correct status, grade and the messages to be
  #   assigned to the grading.
  def evaluate_answer(answer)
    question = answer.question.actable
    answer_text = answer.normalized_answer_text
    exact_matches, keywords = question.solutions.partition(&:exact_match?)

    solutions = find_exact_match(answer_text, exact_matches)
    # If there is no exact match, we fall back to keyword matches.
    # Solutions are always kept in an array for easier use of #grade_for and #explanations_for
    solutions = solutions.present? ? [solutions] : find_keywords(answer_text, keywords)

    [
      correctness_for(question, solutions),
      grade_for(question, solutions),
      explanations_for(solutions)
    ]
  end

  # Returns one solution that exactly matches the answer.
  #
  # @param [String] answer_text The answer text entered by the student.
  # @param [Array<Course::Assessment::Question::TextResponseSolution>] solutions The solutions
  #   to be matched against answer_text.
  # @return [Course::Assessment::Question::TextResponseSolution] Solution that exactly matches
  #   the answer.
  def find_exact_match(answer_text, solutions)
    # comparison is case insensitive
    solutions.find { |s| s.solution.encode(universal_newline: true).casecmp(answer_text) == 0 }
  end

  # Returns the keywords found in the given answer text.
  #
  # @param [String] answer_text The answer text entered by the student.
  # @param [Array<Course::Assessment::Question::TextResponseSolution>] solutions The solutions
  #   to be matched against answer_text.
  # @return [Array<Course::Assessment::Question::TextResponseSolution>] Solutions that matches
  #   the answer.
  def find_keywords(answer_text, solutions)
    # TODO(minqi): Add tokenizer and stemmer for more natural keyword matching.
    solutions.select { |s| answer_text.downcase.include?(s.solution.downcase) }
  end

  # Returns the grade for a question with all matched solutions.
  #
  # The grade is considered to be the sum of grades assigned to all matched solutions, but not
  # exceeding the maximum grade of the question.
  #
  # @param [Course::Assessment::Question::TextResponse] question The question answered by the
  #   student.
  # @param [Array<Course::Assessment::Question::TextResponseSolution>] solutions The solutions that
  #   matches the student's answer.
  # @return [Integer] The grade for the question.
  def grade_for(question, solutions)
    [solutions.map(&:grade).reduce(0, :+), question.maximum_grade].min
  end

  # Returns the explanations for the given options.
  #
  # @param [Array<Course::Assessment::Question::TextResponseSolution>] solutions The solutions to
  #   obtain the explanations for.
  # @return [Array<String>] The explanations for the given solutions.
  def explanations_for(solutions)
    solutions.map(&:explanation).tap(&:compact!)
  end

  # Mark the correctness of the answer based on solutions.
  #
  # @param [Course::Assessment::Question::TextResponse] question The question answered by the
  #   student.
  # @param [Array<Course::Assessment::Question::TextResponseSolution>] solutions The solutions that
  #   matches the student's answer.
  # @param [Boolean] correct True if the answer is correct.
  def correctness_for(question, solutions)
    solutions.map(&:grade).sum >= question.maximum_grade
  end

  # Grades the given answer for comprehension questions.
  #
  # @param [Course::Assessment::Answer::TextResponse] answer The answer specified by the
  #   student.
  # @return [Array<(Boolean, Integer, Object)>] The correct status, grade and the messages to be
  #   assigned to the grading.
  def evaluate_answer_comprehension(answer)
    question = answer.question.actable
    answer_text = answer.normalized_answer_text
    answer_text_array = answer_text.downcase.gsub(/([^a-z ])/, ' ').split(' ')
    answer_text_lemma_array = []
    answer_text_array.each { |a| answer_text_lemma_array.push(WordNet::Synset.morphy_all(a).first || a) }

    answer_text_lemma_status = { 'compre_lifted_word' => Array.new(answer_text_lemma_array.length, nil),
                                 'compre_keyword' => Array.new(answer_text_lemma_array.length, nil) }

    hash_lifted_word_points = hash_compre_lifted_word(question)

    hash_keyword_solutions = hash_compre_keyword(question)

    find_compre_lifted_word_in_answer(answer_text_lemma_array,
                                      answer_text_lemma_status,
                                      hash_lifted_word_points)

    find_compre_keyword_in_answer(answer_text_lemma_array,
                                  answer_text_lemma_status,
                                  hash_keyword_solutions)

    answer_grade = grade_for_comprehension(question, answer_text_lemma_status)

    [
      correctness_for_comprehension(question, answer_grade),
      answer_grade,
      explanations_for_comprehension(question, answer_grade, answer_text_array, answer_text_lemma_status)
    ]
  end

  # All lifted words in a question as keys and
  # an array of Points where words are found as values, for comprehension questions.
  #
  # @param [Course::Assessment::Question::TextResponse] question The question answered by the
  #   student.
  # @return [Hash{String=>Array<Course::Assessment::Question::TextResponseComprehensionPoint>}]
  #   The mapping from lifted words to Points.
  def hash_compre_lifted_word(question)
    hash = {}
    question.groups.each do |group|
      group.points.each do |point|
        # for all TextResponseComprehensionSolution where solution_type == compre_lifted_word
        point.solutions.select(&:compre_lifted_word?).each do |s|
          s.solution_lemma.each do |solution_key|
            if hash.key solution_key
              hash_value = hash[solution_key]
              hash_value.push point unless hash_value.include? point
            else
              hash[solution_key] = [point]
            end
          end
        end
      end
    end
    hash
  end

  # All keywords in a question as keys and
  # an array of Solutions where words are found as values, for comprehension questions.
  #
  # @param [Course::Assessment::Question::TextResponse] question The question answered by the
  #   student.
  # @return [Hash{String=>Array<Course::Assessment::Question::TextResponseComprehensionSolution>}]
  #   The mapping from keywords to Solutions.
  def hash_compre_keyword(question)
    hash = {}
    question.groups.each do |group|
      group.points.each do |point|
        # for all TextResponseComprehensionSolution where solution_type == compre_keyword
        point.solutions.select(&:compre_keyword?).each do |s|
          s.solution_lemma.each do |solution_key|
            if hash.key? solution_key
              hash_value = hash[solution_key]
              hash_value.push s unless hash_value.include? s
            else
              hash[solution_key] = [s]
            end
          end
        end
      end
    end
    hash
  end

  # Find for all compre_lifted_word in answer, for comprehension questions.
  # If word is found, set +answer_text_lemma_status["compre_lifted_word"][index]+ to the
  # corresponding Point.
  #
  # @param [Array<String>] answer_text_lemma_array The lemmatised answer text in array form.
  # @param [Hash{String=>Array<nil or TextResponseComprehensionPoint or TextResponseComprehensionSolution>}]
  #   answer_text_lemma_status The status of each element in +answer_text_lemma+.
  # @param [Hash{String=>Array<Course::Assessment::Question::TextResponseComprehensionPoint>}] hash
  #   The mapping from lifted words to Points.
  def find_compre_lifted_word_in_answer(answer_text_lemma_array, answer_text_lemma_status, hash)
    answer_text_lemma_array.each_index do |index|
      answer_text_lemma_word = answer_text_lemma_array[index]
      next unless hash.key?(answer_text_lemma_word) && !hash[answer_text_lemma_word].empty?
      
      # lifted word found in answer
      first_point = hash[answer_text_lemma_word].shift
      answer_text_lemma_status['compre_lifted_word'][index] = first_point

      # for same Point, remove from all other values in hash
      hash.each_value do |point_array|
        point_array.delete_if { |point| point.equal? first_point }
      end
    end
  end

  # Find for all compre_keyword in answer, for comprehension questions.
  # If word is found, set +answer_text_lemma_status["compre_keyword"][index]+ to the
  # corresponding Solution.
  # and collate an array of all Solutions where keywords are found in answer.
  #
  # @param [Array<String>] answer_text_lemma_array The lemmatised answer text in array form.
  # @param [Hash{String=>Array<nil or TextResponseComprehensionPoint or TextResponseComprehensionSolution>}]
  #   answer_text_lemma_status The status of each element in +answer_text_lemma+.
  # @param [Hash{String=>Array<Course::Assessment::Question::TextResponseComprehensionSolution>}] hash
  #   The mapping from keywords to Solutions.
  def find_compre_keyword_in_answer(answer_text_lemma_array, answer_text_lemma_status, hash)
    answer_text_lemma_array.each_index do |index|
      next unless answer_text_lemma_status['compre_lifted_word'][index].nil?

      # not a lifted word
      answer_text_lemma_word = answer_text_lemma_array[index]
      next unless hash.key?(answer_text_lemma_word) && !hash[answer_text_lemma_word].empty?

      # keyword found in answer
      until hash[answer_text_lemma_word].empty?
        first_solution = hash[answer_text_lemma_word].shift
        first_solution_point = first_solution.point

        # for same Solution, remove from all other values in hash
        hash.each_value do |solution_array|
          solution_array.delete_if { |solution| solution.equal? first_solution }
        end

        unless answer_text_lemma_status['compre_lifted_word'].include? first_solution_point
          # keyword (Solution) does NOT belong to a "lifted" Point
          answer_text_lemma_status['compre_keyword'][index] = first_solution
          break
        end
      end
    end
  end

  # Returns the grade for a question with all matched solutions, for comprehension questions.
  #
  # The grade is considered to be the sum of grades assigned to all matched solutions, but not
  # exceeding the maximum grade of the point, group and question.
  #
  # @param [Course::Assessment::Question::TextResponse] question The question answered by the
  #   student.
  # @param [Hash{String=>Array<nil or TextResponseComprehensionPoint or TextResponseComprehensionSolution>}]
  #   answer_text_lemma_status The status of each element in +answer_text_lemma+.
  # @return [Integer] The grade of the student answer for the question.
  def grade_for_comprehension(question, answer_text_lemma_status)
    lifted_word_points = answer_text_lemma_status['compre_lifted_word']
    keyword_solutions = answer_text_lemma_status['compre_keyword']

    grade = 0
    question.groups.each do |group|
      group_grade = 0
      group.points.each do |point|
        next if lifted_word_points.include? point

        solutions_found = point.solutions.select(&:compre_keyword?).map { |s| keyword_solutions.include? s }
        (group_grade += point.point_grade) if solutions_found.all?
      end
      grade += [group_grade, group.maximum_group_grade].min
    end
    [grade, question.maximum_grade].min
  end

  # Mark the correctness of the answer based on grade, for comprehension questions.
  #
  # @param [Course::Assessment::Question::TextResponse] question The question answered by the
  #   student.
  # @param [Integer] grade The grade of the student answer for the question.
  # @param [Boolean] correct True if the answer is correct.
  def correctness_for_comprehension(question, grade)
    grade >= question.maximum_grade
  end

  # Returns the explanations for the given status, for comprehension questions.
  #
  # @param [Course::Assessment::Question::TextResponse] question The question answered by the
  #   student.
  # @param [Integer] grade The grade of the student answer for the question.
  # @param [Array<String>] answer_text_array The normalized, downcased, letters-only answer text
  #   in array form.
  # @param [Hash{String=>Array<nil or TextResponseComprehensionPoint or TextResponseComprehensionSolution>}]
  #   answer_text_lemma_status The status of each element in +answer_text_lemma+.
  # @return [Array<String>] The explanations for the given question.
  def explanations_for_comprehension(question, grade, answer_text_array, answer_text_lemma_status)
    [
      explanations_for_keyword(answer_text_array, answer_text_lemma_status['compre_keyword']),
      explanations_for_lifted_word(answer_text_array, answer_text_lemma_status['compre_lifted_word']),
      explanations_for_grade(question, grade)
    ].flatten
  end

  # @param [Array<String>] answer_text_array The normalized, downcased, letters-only answer text
  #   in array form.
  # @param [Array<nil or TextResponseComprehensionPoint or TextResponseComprehensionSolution>] status
  #   A particular hash value in +answer_text_lemma_status+.
  # @return [Array<String>] The explanations for comprehension keywords.
  def explanations_for_keyword(answer_text_array, status)
    if status.any?
      explanations = []
      status.each_index do |index|
        next if status[index].nil?

        word_explanation = answer_text_array[index]
        unless status[index].explanation.nil?
          word_explanation += ( ' (' + status[index].explanation + ')' )
        end
        explanations.push word_explanation
      end
      ['Keywords correctly expressed:', explanations.join(', ')]
    else
      []
    end
  end

  # @param [Array<String>] answer_text_array The normalized, downcased, letters-only answer text
  #   in array form.
  # @param [Array<nil or TextResponseComprehensionPoint or TextResponseComprehensionSolution>] status
  #   A particular hash value in +answer_text_lemma_status+.
  # @return [Array<String>] The explanations for comprehension lifted words.
  def explanations_for_lifted_word(answer_text_array, status)
    if status.any?
      explanations = []
      status.each_index do |index|
        explanations.push answer_text_array[index] unless status[index].nil?
      end
      ['Lifted words:', explanations.join(', ')]
    else
      []
    end
  end

  # @param [Course::Assessment::Question::TextResponse] question The question answered by the
  #   student.
  # @param [Integer] grade The grade of the student answer for the question.
  # @return [Array<String>] The explanations for comprehension grade.
  def explanations_for_grade(question, grade)
    ['Grade: ' + String(grade) + ' / ' + String(question.maximum_grade)]
  end
end
