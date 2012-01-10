require 'spec_helper'

describe "Internal Permissions" do

  before :each do
    @media_resource = FactoryGirl.create :media_resource
    @user = FactoryGirl.create :user
  end

  context "function userpermission_disallows" do
    
    before :each do
      @permissionset = FactoryGirl.create :permissionset, view: false, download: false, edit: false, manage: false
    end

    it "should return not nil if there is a userpermission that disallows" do
      FactoryGirl.create :userpermission, permissionset: @permissionset, user: @user, media_resource: @media_resource, view: false
      (Permissions.userpermission_disallows :view, @media_resource, @user).should_not == nil
    end

    it "should return nil if there is no userpermission that disallows" do
      FactoryGirl.create :userpermission, :user => @user, :media_resource => @media_resource, :maynot_view => false
      (Permissions.userpermission_disallows :view, @media_resource, @user).should == nil
    end


  end

  context "function userpermission_allows " do

    it "should return not nil if there is a userpermission that allows " do
      FactoryGirl.create :userpermission, :user => @user, :media_resource => @media_resource, :may_view => true
      (Permissions.userpermission_allows :view, @media_resource, @user).should_not == nil
    end

    it "should return nil if there is no userpermission that allows " do
      FactoryGirl.create :userpermission, :user => @user, :media_resource => @media_resource, :may_view => false
      (Permissions.userpermission_allows :view, @media_resource, @user).should == nil
    end

  end

  context "function grouppermission_allows" do

    before :each do
      @group = FactoryGirl.create :group
      @group.users << @user
    end

    it "should return nil if there is no grouppermission that allows " do
      FactoryGirl.create :grouppermission, group: @group, media_resource: @media_resource, may_view: false
      (Permissions.grouppermission_allows :view, @media_resource, @user).should == nil
    end
      
    it "should return not nil if there is a grouppermission that allows " do
      FactoryGirl.create :grouppermission, group: @group, media_resource: @media_resource, may_view: true
      (Permissions.grouppermission_allows :view, @media_resource, @user).should_not == nil
    end


  end

end
