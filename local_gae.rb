require 'java'

module LocalGAE
  class Service
    import com.google.apphosting.api.ApiProxy
    import com.google.appengine.tools.development.ApiProxyLocalImpl
    import com.google.appengine.api.datastore.dev.LocalDatastoreService

    class BaseEnvironment
      include ApiProxy::Environment
      def getAppId; 'JRuby/LocalGAE' end
      def getVersionId; '0.1' end
      def getRequestNamespace; '' end
      def getAuthDomain; '' end
      def isLoggedIn; false end
      def getEmail; '' end
      def isAdmin; false end
      def getAttributes; {} end
    end

    class BaseApiProxyLocalImpl < ApiProxyLocalImpl
      alias :service :getService
    end

    DEFAULT_DATA_DIR = '.'

    class << self
      def start(option = {})
        raise 'Environment is already set' if ApiProxy.current_environment
        ApiProxy.environment_for_current_thread = BaseEnvironment.new
        data_dir = option[:data_dir] || option['data_dir'] || DEFAULT_DATA_DIR
        proxy = BaseApiProxyLocalImpl.new(java.io.File.new(data_dir))
        if option[:no_storage] || option['no_storage']
          proxy.set_property(LocalDatastoreService::NO_STORAGE_PROPERTY, 'true')
          @@no_storage = true
        else
          @@no_storage = false
        end
        proxy.service('datastore_v3') # start datastore service
        ApiProxy.delegate = proxy
        if block_given?
          yield proxy
          stop
          nil
        else
          proxy
        end
      end

      def stop
        raise 'No environment' unless ApiProxy.current_environment
        datastore = ApiProxy.delegate.service('datastore_v3')
        datastore.clear_profiles if @@no_storage
        datastore.stop
        ApiProxy.delegate = nil
        ApiProxy.environment_for_current_thread = nil
      end

      def proxy
        ApiProxy.delegate
      end
    end
  end
end
