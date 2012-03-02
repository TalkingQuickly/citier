module Citier
  module RootInstanceMethods

    include InstanceMethods
  
    # Instantiates the instance as it's lowest root class. Used when destroying a root class to 
    # make sure we're not leaving children behind
    def as_child
      #instance_class = Object.const_get(self.type)
      return bottom_class_instance = Kernel.const_get(self.type).where(:id => self.id).first if self.type
      return self if self.is_root? # Return self if we have no child
    end
  
    # Access the root class if ever you need.
    def as_root
       if !self.is_root?
         root_class = self.class.base_class

         #get the attributes of the class which are inherited from it's parent.
         attributes_for_parent = self.attributes.reject{|key,value| !root_class.column_names.include?(key) }

         #create a new instance of the superclass, passing the inherited attributes.
         parent = root_class.new(attributes_for_parent)
         parent.id = self.id
         parent.type = self.type
       
         unless new_record?  
           parent.reload #we need to reload the object to clear the active record dirty changes. Doubt this is the most efficent way. discovered this while trying to set a value to nil after after getting a Citier model .as_root instance
           parent.is_new_record(false)
         end

         parent
       else
          self #just return self if we are the root
       end
    end
  
    #For testing whther we are using the framework or not
    def acts_as_citier?
      true
    end
  
    def is_root?
      self.class.superclass==ActiveRecord::Base
    end

  end
end