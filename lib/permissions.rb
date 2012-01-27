module Permissions
  extend self 

  class << self



    def authorized?(user, action, resource_or_resources)

      # the old authorized accepted subjects 
      raise "authorized? can only be called with a user" if user.class != User

      Array(resource_or_resources).all? do |resource|
        if resource.user == user
          true
        elsif resource.send(action) == true
          true
        elsif userpermission_disallows action, resource, user
          false
        elsif userpermission_allows action, resource, user
          true
        elsif grouppermission_allows action, resource, user
          true
        else
          false
        end
      end 

    end

    def is_private? user, resource, action
      new_action = Constants::Actions.old2new action
      (users_permitted_to_act_on_resouce resource, new_action).where("users.id <> #{user.id}").first.nil?
    end


    def users_permitted_to_act_on_resouce resource, action

      # do not optimize away this query as resource.user can be null
      owner_id = User.select("users.id").joins(:media_resources).where("media_resources.id" => resource.id)
      user_ids_by_userpermission= Userpermission.select("user_id").where("media_resource_id" => resource.id).where("userpermissions.#{action}" => true)
      user_ids_dissallowed_by_userpermission = Userpermission.select("user_id").where("media_resource_id" => resource.id).where("userpermissions.#{action}" => false)
      user_ids_by_grouppermission_but_not_dissallowed= Grouppermission.select("groups_users.user_id as user_id").joins(:group).joins("INNER JOIN groups_users ON groups_users.group_id = groups.id").where("media_resource_id" => resource.id).where("grouppermissions.#{action}" => true).where(" user_id NOT IN ( #{user_ids_dissallowed_by_userpermission.to_sql} )")
      user_ids_by_publicpermission= User.select("users.id").joins("CROSS JOIN media_resources").where("media_resources.#{action}" => true)

      User.where " users.id IN (
            #{owner_id.to_sql}
          UNION
            #{user_ids_by_userpermission.to_sql}
          UNION
            #{user_ids_by_grouppermission_but_not_dissallowed.to_sql}
          UNION
            #{user_ids_by_publicpermission.to_sql})"

    
    end




    def resources_permissible_for_user  user, action 
      MediaResource.accessible_by_user user, action
    end




    ### private

    def userpermission_disallows action, resource, user
      Userpermission.where(action => false).where(user_id: user).where(media_resource_id: resource).first
    end


    def userpermission_allows action, resource, user
      Userpermission.where(action => true).where(user_id: user).where(media_resource_id: resource).first
    end


    def grouppermission_allows action, resource, user
      Grouppermission.joins(:group => :users)
        .where(media_resource_id: resource.id)
        .where(action => true)
        .where("groups_users.user_id" => user)
        .first
    end




  end

end