class AppAdmin::MetaKeysController < AppAdmin::BaseController
  def index
    @meta_keys = MetaKey.page(params[:page]).per(12)
  end

  def new
    @meta_key = MetaKey.new
  end

  def create
    begin
      @meta_key = MetaKey.create(meta_key_params)
      redirect_to app_admin_meta_keys_url, flash: {success: "A new meta key has been created"}
    rescue => e
      redirect_to new_app_admin_meta_key_path, flash: {error: e.to_s}
    end
  end

  def edit
    @meta_key = MetaKey.find(params[:id])
  end

  def update
    begin
      @meta_key = MetaKey.find(params[:id])
      @meta_key.update_attributes! meta_key_params
      redirect_to app_admin_meta_keys_path, flash: {success: "The meta key has been updated."}
    rescue => e
      redirect_to edit_app_admin_meta_key_path(@meta_key), flash: {error: e.to_s}
    end
  end

  private

  def meta_key_params
    params.require(:meta_key).permit!
  end
end
