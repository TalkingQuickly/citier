module Citier
<<<<<<< HEAD
  module InstanceMethods

    def updatetype 
      # Keeps our types intact when we've retrieved a record through Root.first etc. and save it.
      # Without this it would revert back to the root class
      type = self.type || self.class.to_s

           
      sql = "UPDATE #{self.class.base_class.table_name} SET #{self.class.inheritance_column} = '#{type}' WHERE id = #{self.id}"
      self.connection.execute(sql)
      citier_debug("#{sql}")
=======
  module InstanceMethods    
    def self.included(base)
      base.send :include, ForcedWriters
    end
    
    module ForcedWriters
      def force_attributes(new_attributes, options = {})
        new_attributes = @attributes.merge(new_attributes) if options[:merge]
        @attributes = new_attributes
        
        if options[:clear_caches] != false
          @aggregation_cache = {}
          @association_cache = {}
          @attributes_cache = {}
        end
      end
    
      def force_changed_attributes(new_changed_attributes, options = {})
        new_changed_attributes = @attributes.merge(new_changed_attributes) if options[:merge]
        @changed_attributes = new_changed_attributes
      end
>>>>>>> 34ff86d707a2ce4c5fd29516cb36bb4a5a85533e
    end
  
    # USAGE validates :attribute, :citier_uniqueness => true
    # Needed because validates :attribute, :uniqueness => true  Won't work because it tries to call child_class.attribute on parents table
    class CitierUniquenessValidator < ActiveModel::EachValidator  
      def validate_each(object, attribute, value)
        existing_record = object.class.where(attribute.to_sym => value).limit(1).first
        if existing_record && existing_record.as_root != object.as_root #if prev record exist and it isn't our current obj
              object.errors[attribute] << (options[:message] || "has already been taken.")  
        end 
      end  
    end

  end
end