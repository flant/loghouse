module Kubernetes
  module_function

  def client
    @client ||= begin
      auth_options = {
        bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token'
      }
      Kubeclient::Client.new(
        "https://#{ENV['KUBERNETES_SERVICE_HOST']}:#{ENV['KUBERNETES_SERVICE_PORT']}/api/", 'v1', auth_options: auth_options
      )
    end
  end

  def namespaces
    # TODO
    # client.get_namespaces.map { |ns| ns.metadata.name }
    %w[production staging review-123]
  end
end
