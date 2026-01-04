module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update, :destroy]

            # GET /api/v1/users
      def index
        @users = User.select(:id, :full_name, :email, :bio, :avatar_url, :country, :university)
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(params[:per_page] || 25)
        
        render json: @users, meta: pagination_meta(@users)
      end

      # GET /api/v1/users/:id or /api/v1/users/me
      def show
        user = params[:id] == 'me' ? current_user : @user
        render json: {
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          system_role: user.system_role,
          
          # Profile picture & bio
          avatar_url: user.avatar_url,
          bio: user.bio,
          
          # Personal information
          age: user.age,
          occupation: user.occupation,
          
          # Academic information
          country: user.country,
          university: user.university,
          department: user.department,
          
          # Goals and questions
          short_term_goals: user.short_term_goals,
          long_term_goals: user.long_term_goals,
          immediate_questions: user.immediate_questions,
          
          # Technical setup
          computer_equipment: user.computer_equipment,
          connection_type: user.connection_type,
          
          # Activity & engagement
          tags: user.tags.pluck(:tag_name),
          projects_count: user.owned_projects.count,
          collaborations_count: user.collaborations.count,
          
          # Timestamps
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end

      # GET /api/v1/users/profile
      def profile
        render json: current_user.as_json(except: [:password_digest]).merge(
          tags: current_user.tags.pluck(:tag_name)
        )
      end

      # GET /api/v1/users/autocomplete/universities
      def autocomplete_universities
        term = params[:term].to_s.strip
        
        universities = if term.present?
          User.where("university LIKE ?", "%#{sanitize_sql_like(term)}%")
              .where.not(university: [nil, ''])
              .select(:university)
              .distinct
              .limit(20)
              .pluck(:university)
              .sort
        else
          User.where.not(university: [nil, ''])
              .select(:university)
              .distinct
              .limit(20)
              .pluck(:university)
              .sort
        end
        
        render json: { universities: universities }
      end

      # GET /api/v1/users/autocomplete/countries
      def autocomplete_countries
        term = params[:term].to_s.strip
        
        countries = if term.present?
          User.where("country LIKE ?", "%#{sanitize_sql_like(term)}%")
              .where.not(country: [nil, ''])
              .select(:country)
              .distinct
              .limit(20)
              .pluck(:country)
              .sort
        else
          User.where.not(country: [nil, ''])
              .select(:country)
              .distinct
              .limit(20)
              .pluck(:country)
              .sort
        end
        
        render json: { countries: countries }
      end

      # PUT /api/v1/users/:id
      def update
        if @user.id == current_user.id || current_user.system_role == 'admin'
          if @user.update(user_params)
            # Handle tags if provided
            if params[:tags].present?
              @user.user_tags.destroy_all
              params[:tags].each do |tag_name|
                tag = Tag.find_or_create_by(tag_name: tag_name)
                @user.user_tags.create(tag: tag)
              end
            end
            
            render json: @user.as_json(except: [:password_digest]).merge(
              tags: @user.tags.pluck(:tag_name)
            )
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Unauthorized to update this user' }, status: :forbidden
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
        if current_user.system_role == 'admin' || @user.id == current_user.id
          @user.destroy
          render json: { message: 'User deleted successfully' }, status: :ok
        else
          render json: { error: 'Unauthorized to delete this user' }, status: :forbidden
        end
      end

      private

      def set_user
        # Support special identifier 'me' to reference the current authenticated user
        @user = (params[:id].to_s == 'me') ? current_user : User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(
          :full_name, :email, :password, :bio, :avatar_url, :system_role,
          :country, :university, :department,
          :age, :occupation,
          :short_term_goals, :long_term_goals, :immediate_questions,
          :computer_equipment, :connection_type
        )
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          next_page: collection.next_page,
          prev_page: collection.prev_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end
