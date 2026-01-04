module Api
  module V1
    module Admin
      class TagsController < BaseController
        before_action :set_tag, only: [:update, :destroy]

        def index
          @tags = Tag.all
                     .order(:tag_name)
                     .page(params[:page])
                     .per(params[:per_page] || 50)
          
          render json: {
            data: @tags,
            meta: pagination_meta(@tags)
          }
        end

        def create
          @tag = Tag.new(tag_params)
          if @tag.save
            render json: @tag, status: :created
          else
            render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @tag.update(tag_params)
            render json: @tag
          else
            render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @tag.destroy
          head :no_content
        end

        private

        def set_tag
          @tag = Tag.find(params[:id])
        end

        def tag_params
          params.require(:tag).permit(:tag_name)
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
end
