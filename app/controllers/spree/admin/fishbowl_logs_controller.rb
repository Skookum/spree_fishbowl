module Spree
  module Admin
    class FishbowlLogsController < ResourceController

      def index
        params[:q] ||= {}
        if !params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end
        if !params[:q][:created_at_lt].blank?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end

        @search = Spree::FishbowlLog.ransack(params[:q])
        @logs = @search.result.
          page(params[:page]).
          per(params[:per_page] || 50).
          order('created_at DESC')
      end

      def show
        @log = Spree::FishbowlLog.find(params[:id])
      end

    end
  end
end
