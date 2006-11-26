module Technoweenie
  module ActiveRecordContext
    def self.extended(base)
      class << base
        alias_method_chain :find_every, :context
        alias_method_chain :find_one,   :context
      end
    end
    
    mattr_reader :context_cache

    def find_every_with_context(options)
      returning find_every_without_context(options) do |records|
        store_in_context records
      end
    end
    
    def find_one_with_context(id, options)
      cached = options[:conditions].nil? && find_in_context(id)
      cached ? cached : find_one_without_context(id, options)
    end

    def find_in_context(id)
      context_cache && context_cache[self] && context_cache[self][id.to_i]
    end
    
    def store_in_context(records)
      return if context_cache.nil?
      records.inject(context_cache[self] ||= {}) do |memo, record| 
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