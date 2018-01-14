json.allowAttachment question.allow_attachment? unless question.hide_text?
json.comprehension question.comprehension_question?
json.autogradable question.auto_gradable?

json.solutions question.solutions.each do |solution|
  json.solutionType solution.solution_type
  # Do not sanitize the solution here to prevent double sanitization.
  # Sanitization will be handled automatically by the React frontend.
  json.solution solution.solution
  json.grade solution.grade
end if can_grade && question.auto_gradable? && !question.comprehension_question?

json.groups question.groups.each do |group|
  json.maximumGroupGrade group.maximum_group_grade

  json.points group.points.each do |point|
    json.pointGrade point.point_grade

    json.solutions point.solutions.each do |s|
      json.solutionType s.solution_type
      # Do not sanitize the solution here to prevent double sanitization.
      # Sanitization will be handled automatically by the React frontend.
      json.solution s.solution.join(', ')
      json.solutionLemma s.solution_lemma.join(', ')
      json.explanation s.explanation
    end
  end
end if can_grade && question.auto_gradable? && question.comprehension_question?
