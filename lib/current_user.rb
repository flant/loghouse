module Loghouse
  module CurrentUser
    extend ActiveSupport::Concern

    included do
      module_function
      def current_user
        @current_user
      end

      def current_user=(user)
        @current_user = user
      end
    end
  end
end
