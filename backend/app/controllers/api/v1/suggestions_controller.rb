module Api
  module V1
    class SuggestionsController < ApplicationController
      # GET /api/v1/suggestions/university_departments
      def university_departments
        users = User.where.not(country: [nil, ''], university: [nil, ''], department: [nil, ''])
        mapping = {}
        users.find_each do |user|
          country = user.country&.strip
          university = user.university&.strip
          department = user.department&.strip
          next if country.blank? || university.blank? || department.blank?
          mapping[country] ||= {}
          mapping[country][university] ||= Set.new
          mapping[country][university] << department
        end
        mapping.each do |country, unis|
          unis.each do |uni, depts|
            unis[uni] = depts.to_a.sort
          end
        end
        render json: mapping
      end

      def tags
        # Replace with real DB query if you have a Tag model
        tags = %w[Flutter Dart Ruby Rails JavaScript React Node.js Python MachineLearning UIUX Backend Frontend DevOps AWS GCP Azure Figma SQL NoSQL Mobile Web API Security Testing Agile Scrum ProjectManagement Leadership OpenSource Research DataScience AI Cloud Blockchain IoT ARVR GameDev Linux Docker Kubernetes Firebase GraphQL REST CICD Design Writing PublicSpeaking Mentoring Education Startups Entrepreneurship]
        render json: filter_list(tags)
      end

      def countries
        countries = %w[Malaysia Singapore India UnitedStates Nepal Bangladesh Indonesia Thailand Vietnam Philippines China Japan SouthKorea Australia UnitedKingdom Canada Germany France Italy Spain]
        render json: filter_list(countries)
      end

      def universities
        universities = User.where.not(university: [nil, '']).distinct.pluck(:university).sort
        render json: filter_list(universities)
      end

      def departments
        departments = User.where.not(department: [nil, '']).distinct.pluck(:department).sort
        render json: filter_list(departments)
      end

      private

      def filter_list(list)
        q = params[:query].to_s.downcase
        filtered = q.empty? ? list : list.select { |item| item.downcase.include?(q) }
        filtered.take(20)
      end
    end
  end
end
