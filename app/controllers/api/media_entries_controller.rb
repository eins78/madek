class Api::MediaEntriesController < ApiController
  def show
    @media_entry= MediaEntry.find(params[:id])
    render json: API::MediaEntryRepresenter.new(@media_entry).as_json.to_json
  end

  def file
    @media_entry= MediaEntry.find(params[:id])
    @media_file= @media_entry.media_file
    send_file @media_file.file_storage_location.to_s,  
      type: @media_file.content_type,
      disposition: 'inline'
  end
end
