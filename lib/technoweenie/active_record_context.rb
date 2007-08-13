module Technoweenie
  module ActiveRecordContext
    def self.extended(base)
      class << base
        alias_method_chain :find_every, :context
        alias_method_chain :find_one,   :context
      end
    end
    
    mattr_accessor :log_context_activity
    mattr_reader :context_cache

    # Preloads the record from the given array of IDs.  The ids should all be the same type.
    # You can pass an array of active record models if that model belongs to the current one.
    #
    #   users = User.find :all
    #   Avatar.prefetch users # performs this automatically: users.collect { |user| user.avatar_id }
    #
    def prefetch(ids)
      return [] if ids.blank?
      initial = ids.first
      ids = ids.collect { |record| record.send(prefetch_default) } if initial.respond_to?(prefetch_default)
      ids.compact!
      ids.uniq!
      find :all, :conditions => { :id => ids }
    end
    
    # defaults to the foreign key of the current model
    #
    #   Avatar => avatar_id
    def prefetch_default
      @prefetch_default ||= name.foreign_key
    end

    def find_every_with_context(options)
      returning find_every_without_context(options) do |records|
        store_in_context records
      end
    end
    
    def find_one_with_context(id, options)
      record = options[:conditions].nil? && cached[id.to_i]
      logger.debug("[Context] #{record ? :Found : :Missed} #{name} ##{id}") if log_context_activity
      record ? record : find_one_without_context(id, options)
    end

    def cached
      context_cache ? (context_cache[self.base_class] ||= {}) : {}
    end
    
    def store_in_context(records)
      return if context_cache.nil?
      logger.debug "[Context] Storing #{name} records: #{records.collect(&:id).to_sentence}" if log_context_activity
      records.inject(cached) do |memo, record| 
        memo.update record.id => record
      end
    end
    
    # Enables the context cache inside this block.
    def with_context
      @@context_cache = {}
      yield
    ensure
      @@context_cache = nil
    end
  end
end