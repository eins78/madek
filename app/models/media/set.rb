# -*- encoding : utf-8 -*-
module Media
  def self.table_name_prefix
    "media_"
  end

  class Set < ActiveRecord::Base # TODO rename to Media::Group
    include Resource
    
    
    TS_FIELDS = TS_FIELDS.merge({:type => lambda {|i| i.type } })    
  
    has_dag_links :link_class_name => 'Media::SetLink'
  
    belongs_to :user
    has_and_belongs_to_many :media_entries, :join_table => "media_entries_media_sets",
                                            :foreign_key => "media_set_id" do
      def push_uniq(members)
        i = 0
        Array(members).each do |member|
          next if exists? member
          push member
          #old# member.sphinx_reindex 
          i += 1
        end
        i
      end
    end
    
    def self.find_by_id_or_create_by_title(values, user)
      records = Array(values).map do |v|
                        if v.is_a?(Numeric) or !!v.match(/\A[+-]?\d+\Z/) # TODO path to String#is_numeric? method
                          a = where(:id => v).first
                        else
                          a = user.media_sets.create # FIXME user can create non-uniquely named sets
                          a.meta_data.create(:meta_key => MetaKey.find_by_label("title"), :value => v)
                        end
                        a
                    end
      records.compact
    end
  
  ########################################################
  
    # TODO validation: if dynamic media_set, then media_entries must be empty
    # TODO validation: if static media_set, then query must be nil
  
  ########################################################
  
    default_scope order("updated_at DESC")
  
    scope :static, where("query IS NULL")
    scope :dynamic, where("query IS NOT NULL")
    
    scope :collections, where(:type => "Media::Collection")
    scope :sets, where(:type => "Media::Set")
    scope :projects, where(:type => "Media::Project")
  
  ########################################################
  # SPHINX stuff
  
  define_index do
    # the index will be generated by the to_sphinxpipe class method
    indexes :id # just to avoid plugin warning
  
    set_property :delta => true
  end
  # 
  # # used to forcing sphinx live update
  def sphinx_reindex
    self.delta = true
    save
  end
  # 
  default_sphinx_scope :default_search
  sphinx_scope(:default_search) { { :star => true, :order => :updated_at, :sort_mode => :desc } }
  sphinx_scope(:by_ids) { |ids| { :with => {:sphinx_internal_id => ids} } }

  
  ########################################################
    def to_s
      s = "#{title} " 
      s += "- %s " % self.class.name.split('::').last # OPTIMIZE get class name without module name
      s += (static? ? "(#{media_entries.count})" : "(#{MediaEntry.search_count(query, :match_mode => :extended2)}) [#{query}]")
    end
  
  ########################################################
  
    def dynamic?
      not static?
    end
  
    def static?
      query.nil?
    end
  
  end

end
