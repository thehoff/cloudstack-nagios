class NagiosConfig < CloudstackNagios::Base

  class_option :bin_path, desc: "absolute path to the nagios-cloudstack binary"

  desc "generate_all", "generate all nagios configs"
  def generate_all
    commands = %w(router_hosts router_services api_hosts storage_pool_services capacity_services asyncjobs_services)
    commands.each do |command|
      invoke "nagios_config:#{command}"
      puts
    end
  end

  desc "router_hosts", "generate nagios hosts configuration for virtual routers"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_router_hosts.cfg.erb'),
    aliases: '-t'
  def router_hosts
  	host_template = load_template(options[:template])
    puts host_template.result(
      routers: cs_routers,
      date: date_string
    )
  end

  desc "router_services", "generate nagios services configuration for system vms"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_router_services.cfg.erb'),
    aliases: '-t'
  option :if_speed,
    desc: 'network interface speed in bits per second',
    type: :numeric,
    default: 1000000,
    aliases: '-s'
  def router_services
  	service_template = load_template(options[:template])
    puts service_template.result(
      routers: cs_routers,
      bin_path: bin_path,
      if_speed: options[:if_speed],
      config_file: options[:config],
      date: date_string
    )
  end

  desc "api_hosts", "generate nagios api host configuration"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_api_hosts.cfg.erb'),
    aliases: '-t'
  def api_hosts
    service_template = load_template(options[:template])
    puts service_template.result(
      zones: client.list_zones,
      bin_path: bin_path,
      config_file: options[:config],
      date: date_string
    )
  end

  desc "storage_pool_services", "generate nagios storage pool services configuration"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_storage_pool_services.cfg.erb'),
    aliases: '-t'
  option :over_provisioning, type: :numeric, default: 1.0
  def storage_pool_services
    service_template = load_template(options[:template])
    storage_pools = client.list_storage_pools.select do |pool| 
      pool['state'].downcase == 'up'
    end
    puts service_template.result(
      storage_pools: storage_pools,
      over_provisioning: options[:over_provisioning],
      bin_path: bin_path,
      config_file: options[:config],
      date: date_string
    )
  end

  desc "capacity_services", "generate nagios capacity services configuration"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_capacity_services.cfg.erb'),
    aliases: '-t'
  def capacity_services
    service_template = load_template(options[:template])
    puts service_template.result(
      zones: client.list_zones,
      capacity_types: Capacity::CAPACITY_TYPES,
      bin_path: bin_path,
      config_file: options[:config],
      date: date_string
    )
  end

  desc "asyncjobs_services", "generate nagios capacity services configuration"
  option :template,
    desc: "path of ERB template to use",
    default: File.join(File.dirname(__FILE__), '..', 'templates', 'cloudstack_asyncjobs_services.cfg.erb'),
    aliases: '-t'
  def asyncjobs_services
    service_template = load_template(options[:template])
    puts service_template.result(
      bin_path: bin_path,
      config_file: options[:config],
      date: date_string
    )
  end

  no_commands do
    def date_string
      Time.new.strftime("%d.%m.%Y - %H:%M:%S")
    end

    def bin_path
      unless options[:bin_path]
        return ''
      else
        return options[:bin_path].end_with?('/') ? options[:bin_path] : options[:bin_path] + "/"
      end
    end
  end

 end