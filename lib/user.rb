class User
  PERMISSONS_FILE_PATH = ENV.fetch('PERIMISSONS_FILE_PATH') { 'config/permissions.yml' }

  class << self
    def current
      @current
    end

    def current=(user)
      @current = user.is_a?(self) ? user : new(user)
    end
  end

  attr_accessor :name, :permissions
  def initialize(name)
    @name        = name
    @permissions = YAML.load_file(PERMISSONS_FILE_PATH)[name]

    raise "no user permissions configured for user '#{self}'" if permissions.blank?
  end

  def allowed_to?(namespace)
    permissions.any? do |p|
      Regexp.new(p).match?(namespace)
    end
  end

  def available_namespaces
    Kubernetes.namespaces.select { |ns| allowed_to?(ns) } 
  end

  def to_s
    name
  end
end
