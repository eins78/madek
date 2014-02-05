class API::Applicationpermission < ActiveRecord::Base 
  belongs_to :media_resource
  belongs_to :application 

  def self.destroy_irrelevant
    API::Applicationpermission.where(view: false, edit:false, download: false,manage: false).delete_all
    API::Applicationpermission.connection.execute <<-SQL
        DELETE
          FROM "applicationpermissions"
            USING "media_resources"
          WHERE "media_resources"."id" = "applicationpermissions"."media_resource_id"
          AND applicationpermissions.application_id = media_resources.application_id
    SQL
  end

end
