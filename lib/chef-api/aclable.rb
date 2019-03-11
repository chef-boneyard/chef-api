module ChefAPI
  module AclAble
    def acl_path
      self.resource_path + '/_acl'
    end

    def load_acl
      data = self.class.connection.get(acl_path)
      # make deep copy
      @orig_acl_data = Marshal.load(Marshal.dump(data))
      data.freeze
      @acl = data
    end

    def acl
      unless @acl
        self.load_acl
      end
      @acl
    end

    def save!
      super
      if @acl != @orig_acl_data
        %w(create update grant read delete).each{|action|
          if @acl[action] != @orig_acl_data[action]
            url = "#{self.acl_path}/#{action}"
            self.class.connection.put(url, {action => @acl[action]}.to_json)
          end
        }
      end
    end
  end
    
end
