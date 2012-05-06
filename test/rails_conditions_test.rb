ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require 'test_help'
require 'test/spec/rails'

context "The condition macro" do
  
  setup do
    @document = instantiate(:Document) do
      def showable?
        false
      end
      
      condition :active do
        false
      end
      
      condition :truth do
        true
      end
      
      condition :deactivateable, :if => :active
      condition :really_deactivateable, :if => :active & :truth
      
      condition :can_be_published, :if => :active & :showable
    end
  end
  
  specify "should generate a predicate method using a given block" do
    assert @document.respond_to?(:active?)
    assert @document.respond_to?(:active!)
  end
  
  specify "should generate exception mixins right after condition definition for block condition" do
    assert @document.class.const_get('ActiveFailed')
  end
  
  specify "should generate exception mixins right after condition definition for simple precondition" do
    assert @document.class.const_get('DeactivateableFailed')
  end
  
  specify "should generate exception mixins right after condition definition for complex precondition" do
    assert @document.class.const_get('ReallyDeactivateableFailed')
  end
  
  specify "should generate exception mixins at access time for preconditions without condition definition" do
    assert @document.class.const_get('ShowableFailed')
  end
end


context "The bang method defined by a condition" do

  setup do
    @document = instantiate(:Document) do
      attr_writer :active
      
      condition :active do
        @active
      end
    end
  end
  
  specify "should raise an Exception if the underlying predicate method returns false" do
    @document.active = true
    assert_nothing_raised do
      @document.active!
    end
    
    @document.active = false
    begin
      @document.active!
    rescue @document.class::ActiveFailed => e
      assert_equal RailsConditions::Failed, e.class
    else
      fail "exception expected"
    end
  end
end

context "A condition defined through an Atom precondition" do
  setup do
    @document = instantiate(:Document) do
      attr_writer :active, :public
      
      condition :active do
        @active
      end
    
      condition :can_be_deactivated, :if => :active
    end
  end
  
  specify "should return true if the precondition returns true" do
    @document.active = true
    assert @document.can_be_deactivated?
    @document.active = false
    assert !@document.can_be_deactivated?
  end
end


context "A condition defined through an And precondition" do
  setup do
    @document = instantiate(:Document) do
      attr_writer :active, :public
      
      condition :active do
        @active
      end
      
      condition :public do
        @public
      end
      
      condition :can_be_displayed, :if => :active & :public
    end
  end
  
  specify "should return true if both preconditions are true" do
    @document.active, @document.public = true, true
    assert @document.can_be_displayed?
  end
  
  specify "should return false if at least one precondition is false" do
    @document.active, @document.public = false, true
    assert !@document.can_be_displayed?
    @document.active, @document.public = true, false
    assert !@document.can_be_displayed?
    @document.active, @document.public = false, false
    assert !@document.can_be_displayed?
  end
  
  specify "should mixin the exception module of the failing precondition and it's own exception module if bang method fails" do
    @document.active = false
    @document.public = true
    
    begin
      @document.can_be_displayed!
    rescue RailsConditions::Failed => e
      assert_kind_of @document.class::ActiveFailed, e
      assert_kind_of @document.class::CanBeDisplayedFailed, e
    else
      fail "exception expected"
    end
  end
end

context "A condition defined through an Or precondition" do
  
  setup do
    @document = instantiate(:Posting) do
      attr_writer :expired, :inactive
      
      condition :expired do
        @expired
      end
      
      condition :inactive do
        @inactive
      end
      
      condition :can_be_edited, :if => :expired | :inactive
    end
  end
  
  specify "should return false if both preconditions are false" do
    @document.expired, @document.inactive = false, false
    assert !@document.can_be_edited?
  end
  
  specify "should return true if at least one precondition is true" do
    @document.expired, @document.inactive = false, true
    assert @document.can_be_edited?
    
    @document.expired, @document.inactive = true, false
    assert @document.can_be_edited?
    
    @document.expired, @document.inactive = true, true
    assert @document.can_be_edited?
  end
  
  specify "should mixin the exception module of the failing precondition and it's own exception module if bang method fails" do
    @document.expired = false
    @document.inactive = false
    
    begin
      @document.can_be_edited!
    rescue RailsConditions::Failed => e
      assert_kind_of @document.class::InactiveFailed, e # last condition not returning to true
      assert_kind_of @document.class::CanBeEditedFailed, e
    else
      fail "exception expected"
    end
  end
end

context "A negated condition" do
  
  setup do
    @document = instantiate(:Posting) do
      attr_writer :active
      
      condition :active, :negated => :inactive do
        @active
      end
    end
  end
  
  
  specify "should return true if positiv condition evaluates to true" do
    @document.active = true
    assert @document.active?
    assert ! @document.inactive?
    
    @document.active = false
    assert ! @document.active?
    assert @document.inactive?
  end
  
  specify "should raise an Exception if the underlying predicate method returns true if the bang method was called" do
    @document.active = false
    assert_nothing_raised do
      @document.inactive!
    end
    
    @document.active = true
    begin
      @document.inactive!
    rescue @document.class::InactiveFailed => e
      assert_equal RailsConditions::Failed, e.class
    else
      fail "exception expected"
    end
  end
end

context "Preconditions from different classes" do
  
  setup do
    @user = instantiate(:User) do
      attr_writer :admin
      condition(:is_admin) { @admin }
    end
    
    @document = instantiate(:Document) do
      attr_writer :public
      condition(:public) { @public }
      condition :can_be_deleted, :if => :public & :user_is_admin
    end
  end
  
  specify "should execute on supplied classes" do
    @document.public = true
    @user.admin = true
    assert @document.can_be_deleted?(@user)
    
    @document.public = false
    @user.admin = true
    assert ! @document.can_be_deleted?(@user)
    
    @document.public = true
    @user.admin = false
    assert ! @document.can_be_deleted?(@user)
    
    @document.public = false
    @user.admin = false
    assert ! @document.can_be_deleted?(@user)
  end
  
  specify "should mixin exception modules of failing preconditions other classes" do
    @document.public = true
    @user.admin = false
    
    begin
      @document.can_be_deleted!(@user)
    rescue RailsConditions::Failed => e
      assert_kind_of @user.class::IsAdminFailed, e
      assert_kind_of @document.class::CanBeDeletedFailed, e
    else
      fail "exception expected"
    end
  end
end

context "An existing predicate method" do
  
  setup do
    @document = instantiate(:Document) do
      condition :can_be_displayed, :if => :public
      
      def public?
        false
      end
    end
  end
  
  specify "should be usable as a precondition without explicit condition definition" do
    begin
      @document.can_be_displayed!
    rescue @document.class::PublicFailed => e
      assert_kind_of RailsConditions::Failed, e
    else
      fail "exception expected"
    end
  end
end

context "Some super complex scenarios" do
  
  specify "should run..." do
    
    @user = instantiate(:User) do
      attr_writer :admin
      def is_admin?
        @admin
      end
    end
    
    @document = instantiate(:Document) do
      attr_writer :public
      condition(:public) { @public }
      condition :can_be_deleted, :if => :public & :user_is_admin
    end
    
    @document.public = true
    @user.admin = true
    assert @document.can_be_deleted?(@user)
    
    @document.public = true
    @user.admin = false
    assert ! @document.can_be_deleted?(@user)
  end
  
  specify "should run this too..." do
    @user = instantiate(:User) do
      attr_writer :id
      condition :owns_document, :negated => :does_not_own_document do |document|
        document.user_id == @id
      end
    end
    
    @document = instantiate(:Document) do
      attr_accessor :user_id
      condition :can_be_deleted, :if => :user_does_not_own_document
    end
    
    @user.id = 100
    @document.user_id = 100
    assert ! @document.can_be_deleted?(@user)
    
    @user.id = 200
    @document.user_id = 100
    assert @document.can_be_deleted?(@user)
  end
  
  specify "should run this also..." do
    @document = instantiate(:Document) do
      attr_writer :public
      condition(:public, :negated => :not_public)
      def public?
        @public
      end
    end
    
    assert @document.not_public?(1234)
  end
end

def instantiate(class_name = nil, &block)
  Object.__send__(:remove_const, class_name) if class_name && Object.const_defined?(class_name)
  klass = Class.new
  Object.const_set(class_name, klass) if class_name
  klass.__send__ :include, RailsConditions::Base
  klass.class_eval(&block)
  klass.new
end

