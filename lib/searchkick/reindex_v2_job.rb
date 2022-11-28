module Searchkick
  class ReindexV2Job < ActiveJob::Base
    RECORD_NOT_FOUND_CLASSES = [
      "ActiveRecord::RecordNotFound",
      "Mongoid::Errors::DocumentNotFound",
      "NoBrainer::Error::DocumentNotFound",
      "Cequel::Record::RecordNotFound"
    ]

    queue_as { Searchkick.queue_name }

    def perform(klass, id, method_name = nil, routing: nil)
      model = klass.constantize
      record = if model.respond_to?(:unscoped)
                 model.unscoped.find(id)
               else
                 model.find(id)
               end

      unless record
        record = model.new
        record.id = id
        if routing
          record.define_singleton_method(:search_routing) do
            routing
          end
        end
      end

      RecordIndexer.new(record).reindex(method_name, mode: :inline)
    end
  end
end
