# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Course::Controller, type: :controller do
  controller(Course::Controller) do
    def show
      render body: ''
    end

    def publicly_accessible?
      true
    end
  end

  let(:instance) { Instance.default }
  with_tenant(:instance) do
    let(:admin) { create(:administrator) }
    let(:user) { admin }
    let(:course) { create(:course, :published) }
    before { sign_in(user) if user }

    describe '#current_course' do
      it 'returns the current course' do
        get :show, params: { id: course.id }
        expect(controller.current_course).to eq(course)
      end
    end

    describe '#current_course_user' do
      context 'when there is no user logged in' do
        let(:user) { nil }
        subject { get :show, params: { id: course.id } }
        it 'raises an error' do
          expect { subject }.to raise_error(CanCan::AccessDenied)
        end
      end

      context 'when the user is logged in' do
        context 'when the user is not registered in the course' do
          it 'returns nil' do
            get :show, params: { id: course.id }
            expect(controller.current_course_user).to be_nil
          end
        end

        context 'when the user is registered in the course' do
          let!(:course_user) { create(:course_user, course: course, user: user) }
          it 'returns the correct user' do
            get :show, params: { id: course.id }
            expect(controller.current_course_user.user).to eq(user)
            expect(controller.current_course_user.course).to eq(controller.current_course)
          end
        end
      end
    end

    describe '#current_component_host' do
      it 'returns the component host of current course' do
        allow(controller).to receive(:current_course).and_return(course)
        expect(controller.current_component_host).to be_a Course::ControllerComponentHost
      end
    end

    describe '#sidebar_items' do
      before { controller.instance_variable_set(:@course, course) }

      it 'orders the sidebar items by ascending weight' do
        weights = controller.sidebar_items.map { |item| item[:weight] }
        expect(weights.length).not_to eq(0)
        expect(weights.each_cons(2).all? { |a, b| a <= b }).to be_truthy
      end

      it 'orders sidebar items with the same weight by ascending key' do
        allow(controller).to receive(:sidebar_items_weights).and_return(Hash.new(1))

        keys = controller.sidebar_items.map { |item| item[:key] }
        expect(keys.length).not_to eq(0)
        expect(keys.each_cons(2).all? { |a, b| a.to_s <= b.to_s }).to be_truthy
      end

      context 'when no type is specified' do
        it 'returns all sidebar items' do
          expect(controller.sidebar_items).to \
            contain_exactly(*controller.current_component_host.sidebar_items)
        end
      end

      context 'when a type is specified' do
        it 'returns only that type' do
          expect(controller.sidebar_items(type: :admin).all? { |item| item[:type] == :admin }).to \
            be_truthy
        end
      end
    end

    describe '#next_popup_notification' do
      render_views
      let(:student) { create(:course_student, course: course) }
      let(:user) { student.user }

      subject { JSON.parse(controller.next_popup_notification) }

      context "when the next notification is 'level_reached'" do
        before do
          create(:course_level, course: course, experience_points_threshold: 10)
          course.reload
          build(:course_experience_points_record, course_user: student, points_awarded: 20, awarder: admin).tap(&:save)
          get :show, params: { id: course.id }
        end

        context 'when leaderboard is enabled' do
          before { get :show, params: { id: course.id } }

          it 'returns the appropriate fields' do
            expect(subject['notificationType']).to eq('levelReached')
            expect(subject['levelNumber']).to eq(1)
            expect(subject['leaderboardEnabled']).to eq(true)
            expect(subject['leaderboardPosition']).to eq(1)
          end
        end

        context 'when leaderboard is disabled' do
          before do
            course.settings(:components, :course_leaderboard_component).enabled = false
            course.save
            controller.instance_variable_set(:@course, nil)
            get :show, params: { id: course.id }
          end

          it 'returns the appropriate fields' do
            expect(subject['notificationType']).to eq('levelReached')
            expect(subject['levelNumber']).to eq(1)
            expect(subject['leaderboardEnabled']).to eq(false)
            expect(subject['leaderboardPosition']).to eq(nil)
          end
        end
      end
    end
  end
end
