require File.join(File.dirname(__FILE__), 'abstract_unit')

class ActiveRecordContextTest < Test::Unit::TestCase
  def setup
    Foo.destroy_all
    @records = {}
    2.times { |i| f = Foo.create!(:bar => "test#{i}"); @records[f.id] = f }
    assert_nil Foo.context_cache
  end

  def test_should_initialize_context_cache_hash
    Foo.with_context do
      assert_kind_of Hash, Foo.context_cache
      assert_equal 0, Foo.context_cache.size
    end
    assert_nil Foo.context_cache
  end

  def test_should_store_records_in_cache
    Foo.with_context do
      records = Foo.find(:all)
      assert_equal records.size, Foo.context_cache[Foo].size
      assert_equal @records[1], Foo.find_in_context(1)
      assert_equal @records[2], Foo.find_in_context(2)
    end
  end
  
  def test_should_find_records_in_context
    Foo.with_context do
      records = Foo.find(:all)
      Foo.destroy_all
      assert_equal @records[1], Foo.find(1)
      assert_equal @records[2], Foo.find(2)
    end
    
    assert_raise ActiveRecord::RecordNotFound do
      Foo.find 1
    end
  end
end
