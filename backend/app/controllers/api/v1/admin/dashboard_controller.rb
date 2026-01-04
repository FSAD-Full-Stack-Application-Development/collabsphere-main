module Api
  module V1
    module Admin
      class DashboardController < BaseController
        def stats
          counts = {
            users: User.count,
            projects: Project.count,
            tags: Tag.count
          }
          render json: counts
        end
      end
    end
  end
end
