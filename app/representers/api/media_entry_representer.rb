class API::MediaEntryRepresenter < API::MediaResourceRepresenter

  property :content_type

  property :media_type

  link 'madek:previews' do api_previews_path(@represented) end 

  link 'madek:file' do file_api_media_entry_path(@represented) end

  #links :previews do 
  #  @represented.media_file.previews.map do |preview|
  #    {href: api_preview_path(preview)}
  #  end
  #end

end
