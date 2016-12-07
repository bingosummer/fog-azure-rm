# Pick Resource Group name from Azure Resource Id(String)
def get_resource_group_from_id(id)
  id.split('/')[4]
end

# Pick Virtual Network name from Subnet Resource Id(String)
def get_virtual_network_from_id(subnet_id)
  subnet_id.split('/')[8]
end

# Pick Virtual Machine name from Virtual Machine Extension Id(String)
def get_virtual_machine_from_id(vme_id)
  vme_id.split('/')[VM_NAME_POSITION]
end

# Extract Endpoint type from (String)
def get_end_point_type(endpoint_type)
  endpoint_type.split('/')[2]
end

def get_record_set_from_id(id)
  id.split('/')[8]
end

def get_type_from_recordset_type(type)
  type.split('/')[2]
end

def get_hash_from_object(object)
  hash = {}
  object.instance_variables.each { |attr| hash[attr.to_s.delete('@')] = object.instance_variable_get(attr) }
  hash
end

# Extract Traffic Manager Profile Name from Endpoint id(String)
def get_traffic_manager_profile_name_from_endpoint_id(endpoint_id)
  endpoint_id.split('/')[8]
end

# Get server name from ID (String)
def get_server_name_from_id(database_id)
  database_id.split('/')[8]
end

# Pick Express Route Circuit name from Id(String)
def get_circuit_name_from_id(circuit_id)
  circuit_id.split('/')[8]
end

def get_record_type(type)
  type.split('/').last
end

def raise_azure_exception(exception, msg)
  message = if exception.respond_to? 'body'
              "Exception in #{msg} #{exception.body['error']['message'] unless exception.body['error']['message'].nil?} Type: #{exception.class}\n#{exception.backtrace.join("\n")}"
            else
              "#{exception.inspect}\n#{exception.backtrace.join("\n")}"
            end
  Fog::Logger.debug exception.backtrace
  raise message
end

# Make sure if input_params(Hash) contains all keys present in required_params(Array)
def validate_params(required_params, input_params)
  missing_params = required_params.select { |param| param unless input_params.key?(param) }

  if missing_params.any?
    raise(ArgumentError, "Missing Parameters: #{missing_params.join(', ')} required for this operation")
  end
end

def get_resource_from_resource_id(resource_id, position)
  data = resource_id.split('/') unless resource_id.nil?

  raise 'Invalid Resource ID' if data.count < 9 && data.count != 5

  data[position]
end

def random_string(length)
  (0...length).map { ('a'..'z').to_a[rand(26)] }.join
end

def active_directory_service_settings(environment = ENVIRONMENT_AZURE_CLOUD)
  case environment
  when ENVIRONMENT_AZURE_CHINA_CLOUD
    MsRestAzure::ActiveDirectoryServiceSettings.get_azure_china_settings
  when ENVIRONMENT_AZURE_US_GOVERNMENT
    MsRestAzure::ActiveDirectoryServiceSettings.get_azure_us_government_settings
  when ENVIRONMENT_AZURE_GERMAN_CLOUD
    MsRestAzure::ActiveDirectoryServiceSettings.get_azure_german_settings
  else
    MsRestAzure::ActiveDirectoryServiceSettings.get_azure_settings
  end
end

def resource_manager_endpoint_url(environment = ENVIRONMENT_AZURE_CLOUD)
  case environment
  when ENVIRONMENT_AZURE_CHINA_CLOUD
    MsRestAzure::AzureEnvironments::AzureChina.resource_manager_endpoint_url
  when ENVIRONMENT_AZURE_US_GOVERNMENT
    MsRestAzure::AzureEnvironments::AzureUSGovernment.resource_manager_endpoint_url
  when ENVIRONMENT_AZURE_GERMAN_CLOUD
    MsRestAzure::AzureEnvironments::AzureGermanCloud.resource_manager_endpoint_url
  else
    MsRestAzure::AzureEnvironments::Azure.resource_manager_endpoint_url
  end
end

# storage_endpoint_suffix is nil in ms_rest_azure 0.6.2
# Reference the issue: https://github.com/Azure/azure-sdk-for-ruby/issues/603
def storage_endpoint_suffix(environment = ENVIRONMENT_AZURE_CLOUD)
  case environment
  when ENVIRONMENT_AZURE_CHINA_CLOUD
    # MsRestAzure::AzureEnvironments::AzureChina.storage_endpoint_suffix
    '.core.chinacloudapi.cn'
  when ENVIRONMENT_AZURE_US_GOVERNMENT
    # MsRestAzure::AzureEnvironments::AzureUSGovernment.storage_endpoint_suffix
    '.core.usgovcloudapi.net'
  when ENVIRONMENT_AZURE_GERMAN_CLOUD
    # MsRestAzure::AzureEnvironments::AzureGermanCloud.storage_endpoint_suffix
    '.core.cloudapi.de'
  else
    # MsRestAzure::AzureEnvironments::Azure.storage_endpoint_suffix
    '.core.windows.net'
  end
end

def get_blob_endpoint(storage_account_name, enable_https = false, environment = ENVIRONMENT_AZURE_CLOUD)
  protocol = enable_https ? 'https' : 'http'
  "#{protocol}://#{storage_account_name}.blob#{storage_endpoint_suffix(environment)}"
end

def current_time
  time = Time.now.to_f.to_s
  time.split(/\W+/).join
end

# Parse storage blob/container to a hash
def parse_storage_object(object)
  data = {}
  if object.is_a? Hash
    object.each do |k, v|
      if k == 'properties'
        v.each do |j, l|
          data[j] = l
        end
      else
        data[k] = v
      end
    end
  else
    object.instance_variables.each do |p|
      kname = p.to_s.delete('@')
      if kname == 'properties'
        properties = object.instance_variable_get(p)
        properties.each do |k, v|
          data[k.to_s] = v
        end
      else
        data[kname] = object.instance_variable_get(p)
      end
    end
  end

  data['last_modified'] = Time.parse(data['last_modified'])
  data['etag'].delete!('"')
  data
end
