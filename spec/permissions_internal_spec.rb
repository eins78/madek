require 'spec_helper'

describe "Internal Permissions" do

  before :all do
    # DataFactory.create_small_dataset
    @media_resource = FactoryGirl.create :media_resource, view: false
    @user = FactoryGirl.create :user
  end

  context "function userpermission_disallows" do

    it "should return not nil if there is a userpermission that disallows" do
      FactoryGirl.create :userpermission, view: false, user: @user, media_resource: @media_resource
      (Permissions.userpermission_disallows :view, @media_resource, @user).should_not == nil
    end

    it "should return nil if there is no userpermission that disallows" do
      (Permissions.userpermission_disallows :view, @media_resource, @user).should == nil
    end


  end

  context "function userpermission_allows " do

    it "should return not nil if there is a userpermission that allows " do
      FactoryGirl.create :userpermission, view: true, user: @user, media_resource: @media_resource
      (Permissions.userpermission_allows :view, @media_resource, @user).should_not == nil
    end

    it "should return nil if there is no userpermission that allows " do
      (Permissions.userpermission_allows :view, @media_resource, @user).should == nil
    end

  end

  context "function grouppermission_allows" do

    before :each do
      @group = FactoryGirl.create :group
      @group.users << @user
    end

    it "should return nil if there is no grouppermission at all" do
      (Permissions.grouppermission_allows :view, @media_resource, @user).should == nil
    end

      
    it "should return nil if there is a grouppermission that does not allow " do
      FactoryGirl.create :grouppermission, view: false, group: @group, media_resource: @media_resource
      (Permissions.grouppermission_allows :view, @media_resource, @user).should == nil
    end


    it "should return not nil if there is a grouppermission that allows " do
      FactoryGirl.create :grouppermission, view: true, group: @group, media_resource: @media_resource
      (Permissions.grouppermission_allows :view, @media_resource, @user).should_not == nil
    end


  end

end