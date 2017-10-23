module Kubernetes
  module_function

  def client
    @client ||= begin
      auth_options = {
        bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token'
      }

      ssl_options = {
        ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
        verify_ssl: OpenSSL::SSL::VERIFY_PEER
      }

      Kubeclient::Client.new(
        "https://#{ENV['KUBERNETES_SERVICE_HOST']}:#{ENV['KUBERNETES_SERVICE_PORT']}/api/", 'v1', auth_options: auth_options,
                                                                                                  ssl_options: ssl_options
      )
    end
  end

  def namespaces
    if Loghouse::Application.development?
      %w[production staging review-123]
    else
      client.get_namespaces.map { |ns| ns.metadata.name }
    end
  end
end
