require 'java'

class SimpleDatastore
  VERSION = '0.1'
  KIND = 'SimpleDatastore'

  import com.google.appengine.api.datastore.DatastoreServiceFactory
  import com.google.appengine.api.datastore.KeyFactory
  import com.google.appengine.api.datastore.Entity
  import com.google.appengine.api.datastore.Text

  class << self
    def [](key)
      to_ruby(entity.get_property(key.to_s))
    end

    def []=(key, value)
      entity { |entity| entity.set_property(key.to_s, to_java(value)) }
      value
    end

    def has_key?(key)
      entity.has_property(key.to_s)
    end

    def delete(key)
      entity { |entity| entity.remove_property(key.to_s) }
      nil
    end

    def keys
      entity.properties.map { |key, value| key }
    end

    def values
      entity.properties.map { |key, value| to_ruby(value) }
    end

  private
    def entity
      entity = service.get(KeyFactory.create_key(KIND, self.name))
    rescue NativeException
      entity = Entity.new(KIND, self.name)
    ensure
      if block_given?
        yield entity
        service.put(entity)
      end
    end

    def service
      @@service ||= DatastoreServiceFactory.datastore_service
    end

    def to_java(object)
      if object.is_a?(String) && object.length >= 500
        Text.new(object)
      else
        object
      end
    end

    def to_ruby(object)
      if object.is_a?(Java::JavaUtil::ArrayList)
        object.to_a
      elsif object.is_a?(Text)
        object.value
      else
        object
      end
    end
  end
end
