# frozen_string_literal: true

# actions or events associated with a single activity for use in home view 
class ActivityRow 
    include Mongoid::Document
    include Mongoid::Timestamps
    include MongoidSupport::AssociationProxies

    #transaction attributes
    field :transaction_id, type: String
    field :application_id, type: String
    field :primary_hbx_id, type: String
    field :fpl_year, type: Integer

    #activity attributes
    field :correlation_id, type: String
    field :activity_name, type: String
    field :status, type: StringifiedSymbol
    field :message, type: Hash

    index({ transaction_id: 1 })
    index({ application_id: 1 })
    index({ primary_hbx_id: 1 })
    index({ correlation_id: 1 })
    index({ updated_at: 1 })

    default_scope -> { order(:'updated_at'.desc) }

end