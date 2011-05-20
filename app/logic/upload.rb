# -*- encoding : utf-8 -*-

class UploadEstimation
  def self.call(env)
    [200, {"Content-Type" => "text/html"}, [""]]
  end
end

class Upload
  def self.call(env)
      request = Rack::Request.new(env)
      params = request.params
      session = env['rack.session']

      current_user = User.find_by_id(session[:user_id]) if session[:user_id]
      
      ThinkingSphinx.deltas_enabled = false

        files = if !params['uploaded_data'].blank?
          params['uploaded_data']
        elsif !params['import_path'].blank?
          Dir[File.join(params['import_path'], '**', '*')]
        else
          nil
        end

        unless files.blank?
          # OPTIMIZE append if already exists (multiple grouped posts)
          #temp# upload_session = current_user.upload_sessions.latest
          upload_session = current_user.upload_sessions.create

          files.each do |f|
            # Mac OS X sometimes lies about the content type, so we have to detect the supplied type
            # separately from the true type
            uploaded_data = if params['uploaded_data']

              # QuickTime containers contain all sorts of messy data, which makes them hard for
              # the 'file' utility to guess, resulting in a lot of application/octet-stream types.
              # But since QuickTime video is always video/quicktime and always .mov, we simply override
              # this based on the filename here.
              # TODO: Could use exiftool instead of 'file' in general, it seems to do a good job with QuickTime
              if f[:tempfile].path =~ /.mov$/
                f[:type] = "video/quicktime"
              else
                supplied_type = f[:type]
                detected_type = `#{FILE_UTIL_PATH} "#{f[:tempfile].path}"`.split(";").first.gsub(/\n/,"")
                if supplied_type != detected_type
                  f[:type] = detected_type
                end
              end
              f
            else
              { :type=> `#{FILE_UTIL_PATH} "#{f}"`.split(";").first.gsub(/\n/,""),
                :tempfile=> File.new(f, "r"),
                :filename=> File.basename(f)}
            end
            
            # if uploaded_data['filename'].include?
            # uploaded_data['current_user'] = current_user.login # for the use of media_file, if we get a zipfile
            media_file = MediaFile.create(:uploaded_data => uploaded_data)
            media_entry = upload_session.media_entries.create(:media_file => media_file)

            uploaded_data[:tempfile].close unless params['uploaded_data']
          end
        end

      ThinkingSphinx.deltas_enabled = true

      # TODO check if all media_entries successfully saved

      if params['xhr']
        [200, {"Content-Type" => "text/html"}, [""]]
      else
        uri = if params['uploaded_data']
                "/upload"
              elsif params['import_path']
                "/upload/import_summary"
              else
                "/upload/new"
              end
        [ 303, {'Content-Length'=>'0', 'Content-Type'=>'text/plain', 'Location' => uri}, []]
      end
  end
end
