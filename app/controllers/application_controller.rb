require_dependency 'database_interactions'
class ApplicationController < ActionController::Base
  include DatabaseInteractions
end
