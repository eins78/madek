class API::PreviewRepresenter < API::RepresenterBase

  property :content_type
  property :width
  property :height
  property :thumbnail, as: :'thumbnail_size'
  property :size

  link "madek:media_entry" do
    api_media_entry_path(@represented.media_file.media_entry_id)
  end

  link 'madek:file' do api_preview_file_path(@represented) end


end
