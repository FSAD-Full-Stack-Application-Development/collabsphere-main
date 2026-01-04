module Api
  module V1
    class FundsController < ApplicationController
      before_action :set_project

      def index
        @funds = @project.funds.includes(:funder).order(funded_at: :desc)
        render json: @funds.as_json(
          include: { funder: { only: [:id, :full_name] } }
        )
      end

      def create
        @fund = @project.funds.build(fund_params)
        @fund.funder = current_user
        @fund.funded_at = Time.current
        
        if @fund.save
          render json: @fund, status: :created
        else
          render json: { errors: @fund.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_project
        @project = Project.find(params[:project_id])
      end

      def fund_params
        params.permit(:amount)
      end
    end
  end
end
