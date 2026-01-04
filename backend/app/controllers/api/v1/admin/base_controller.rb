module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authorize_admin!

        private

        def authorize_admin!
          render json: { error: 'Not Authorized' }, status: :forbidden unless current_user&.system_role == 'admin'
        end
      end
    end
  end
end
