module ChildInstanceMethods

  def save(validate = true)
    return false unless self.valid?
    
    #citier_debug("Callback (#{self.inspect})")
    citier_debug("SAVING #{self.class.to_s}")
    
    #Just run before save callbacks
    #AIT NOTE: Will change any protected values back to original values so any models onwards won't see changes.
    self.run_callbacks(:save){ false }
  
    #get the attributes of the class which are inherited from it's parent.
    attributes_for_parent = self.attributes.reject{|key,value| !self.class.superclass.column_names.include?(key) }

    # Get the attributes of the class which are unique to this class and not inherited.
    attributes_for_current = self.attributes.reject{|key,value| self.class.superclass.column_names.include?(key) }

    citier_debug("Attributes for #{self.class.to_s}: #{attributes_for_current.inspect.to_s}")

    ########
    #
    # Parent saving
    
    #create a new instance of the superclass, passing the inherited attributes.
    parent = self.class.superclass.new(attributes_for_parent)
    parent.id = self.id
    parent.type = self.type
    
    parent.is_new_record(new_record?)

    # If we're root (AR subclass) this will just be saved as normal through AR. If we're a child it will call this method again. 
    # It will try and save it's parent and then save itself through the Writable constant.
    
    #Specific to my app
    if parent.is_root?
      parent.class.skip_callback(:save, :before, :before_save_change_request) 
      parent.class.skip_callback(:save, :after, :after_save_change_request)
      parent_saved = parent.save
      parent.class.set_callback(:save, :before, :before_save_change_request)
      parent.class.set_callback(:save, :after, :after_save_change_request)
    else
      parent_saved = parent.save
    end
    
    self.id = parent.id

    if(parent_saved==false)
      # Couldn't save parent class
      # TODO: Handle situation where parent class could not be saved
      citier_debug("Class (#{self.class.superclass.to_s}) could not be saved")
    end
    
    #End of parent saving
    
    ######
    ##
    ## Self Saving
    ##

    # If there are attributes for the current class (unique & not inherited) 
    # and parent(s) saved successfully, save current model
    if(!attributes_for_current.empty? && parent_saved)
       
      current = self.class::Writable.new(attributes_for_current)
      current.id = self.id
      current.is_new_record(new_record?)
      citier_debug(self.class.all.to_s)
      
      current_saved = current.save
      
      # Rails 3 doesn't yet have a way of only called AFTER save callback
      self.after_save_change_request if self.respond_to?('after_save_change_request') #Specific to an app I'm building
      
      # This is no longer a new record
      is_new_record(false)

      if(!current_saved)
        citier_debug("Class (#{self.class.superclass.to_s}) could not be saved")
        citier_debug("Errors = #{current.errors.to_s}")
        
      end
    end

    # Update root class with this 'type'
    if parent_saved && current_saved
      sql = "UPDATE #{self.class.root_class.table_name} SET #{self.class.inheritance_column} = '#{self.class.to_s}' WHERE id = #{self.id}"
      citier_debug("SQL : #{sql}")
      self.connection.execute(sql)
    end
    
    return parent_saved && current_saved
  end
  
  def save!
    raise ActiveRecord::RecordInvalid.new(self) unless self.valid?
    self.save
  end
  
  

  include InstanceMethods
end