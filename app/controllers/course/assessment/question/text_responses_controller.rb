# frozen_string_literal: true
class Course::Assessment::Question::TextResponsesController < Course::Assessment::QuestionsController
  build_and_authorize_new_question :text_response_question,
                                   class: Course::Assessment::Question::TextResponse, only: [:new, :create]
  load_and_authorize_resource :text_response_question,
                              class: Course::Assessment::Question::TextResponse,
                              through: :assessment, parent: false, except: [:new, :create]

  def new
    if params[:file_upload] == 'true'
      @text_response_question.hide_text = true
      @text_response_question.allow_attachment = true
    end
    if params[:comprehension] == 'true'
      @text_response_question.is_comprehension = true
      build_at_least_one_group_one_point
    end
  end

  def create
    if @text_response_question.save
      redirect_to course_assessment_path(current_course, @assessment),
                  success: t('.success', name: question_type)
    else
      render 'new'
    end
  end

  def edit
    @question_assessment = load_question_assessment_for(@text_response_question)
    build_at_least_one_group_one_point if @text_response_question.comprehension_question?
  end

  def update
    @text_response_question.groups.map do |group|
      group.points.map do |point|
        point.solutions.map(&:solution_will_change!)
      end
    end

    if @text_response_question.update_attributes(text_response_question_params)
      redirect_to course_assessment_path(current_course, @assessment),
                  success: t('.success', name: question_type)
    else
      render 'edit'
    end
  end

  def destroy
    title = question_type
    if @text_response_question.destroy
      redirect_to course_assessment_path(current_course, @assessment),
                  success: t('.success', name: title)
    else
      error = @text_response_question.errors.full_messages.to_sentence
      redirect_to course_assessment_path(current_course, @assessment),
                  danger: t('.failure', name: title, error: error)
    end
  end

  private

  def text_response_question_params
    params.require(:question_text_response).permit(
      :title, :description, :staff_only_comments, :maximum_grade, :allow_attachment,
      :hide_text, :is_comprehension,
      skill_ids: [],
      solutions_attributes: [:_destroy, :id, :solution_type, :solution, :grade, :explanation],
      groups_attributes:
      [
        :_destroy, :id, :maximum_group_grade,
        points_attributes:
        [
          :_destroy, :id, :point_grade,
          solutions_attributes:
          [
            :_destroy, :id, :solution_type, :explanation, solution: []
          ]
        ]
      ]
    )
  end

  def question_type
    @text_response_question.question_type
  end

  def build_at_least_one_group_one_point
    @text_response_question.groups.build if @text_response_question.groups.empty?
    @text_response_question.groups.first.points.build if @text_response_question.groups.first.points.empty?
  end
end
