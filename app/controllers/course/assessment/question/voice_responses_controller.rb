# frozen_string_literal: true
class Course::Assessment::Question::VoiceResponsesController < Course::Assessment::Question::Controller
  build_and_authorize_new_question :voice_response_question,
                                   class: Course::Assessment::Question::VoiceResponse, only: [:new, :create]
  load_and_authorize_resource :voice_response_question,
                              class: Course::Assessment::Question::VoiceResponse,
                              through: :assessment, parent: false, except: [:new, :create]

  def create
    if @voice_response_question.save
      redirect_to course_assessment_path(current_course, @assessment),
                  success: t('.success')
    else
      render 'new'
    end
  end

  def new
  end

  def update
    if @voice_response_question.update_attributes(voice_response_question_params)
      redirect_to course_assessment_path(current_course, @assessment),
                  success: t('.success')
    else
      render 'edit'
    end
  end

  def edit
    @question_assessment = load_question_assessment_for(@voice_response_question)
  end

  def destroy
    if @voice_response_question.destroy
      redirect_to course_assessment_path(current_course, @assessment),
                  success: t('.success')
    else
      error = @voice_response_question.errors.full_messages.to_sentence
      redirect_to course_assessment_path(current_course, @assessment),
                  danger: t('.failure', error: error)
    end
  end

  private

  def voice_response_question_params
    params.require(:question_voice_response).permit(
      :file, :title, :description,
      :staff_only_comments, :maximum_grade, skill_ids: []
    )
  end
end
