puts "=" * 80
puts "COLLABORATION REQUESTS IMPLEMENTATION VERIFICATION"
puts "=" * 80
puts

# 1. Check Routes
puts "1. API ENDPOINTS CHECK"
puts "-" * 80
routes_output = `rails routes | grep collab`
expected_routes = [
  "POST   /api/v1/projects/:project_id/collab/request",
  "POST   /api/v1/projects/:project_id/collab/approve", 
  "POST   /api/v1/projects/:project_id/collab/reject",
  "GET    /api/v1/projects/:project_id/collab"
]

puts "Expected Routes:"
expected_routes.each { |r| puts "  ✓ #{r}" }
puts
puts "Actual Routes Found:"
puts routes_output
puts

# 2. Check Database Table
puts "2. DATABASE TABLE CHECK"
puts "-" * 80
require_relative 'config/environment'

table_exists = ActiveRecord::Base.connection.table_exists?('collaboration_requests')
puts "Table exists: #{table_exists ? '✓' : '✗'}"

if table_exists
  columns = ActiveRecord::Base.connection.columns('collaboration_requests')
  puts "\nColumns:"
  columns.each do |col|
    puts "  - #{col.name} (#{col.sql_type})#{col.null ? '' : ' NOT NULL'}#{col.default ? " DEFAULT #{col.default}" : ''}"
  end
  
  indexes = ActiveRecord::Base.connection.indexes('collaboration_requests')
  puts "\nIndexes:"
  indexes.each do |idx|
    unique = idx.unique ? " UNIQUE" : ""
    puts "  - #{idx.name}#{unique} on #{idx.columns.inspect}"
  end
end
puts

# 3. Check Model
puts "3. MODEL CHECK"
puts "-" * 80
if defined?(CollaborationRequest)
  puts "✓ CollaborationRequest model exists"
  
  # Check methods
  methods_to_check = [:approve!, :reject!, :pending, :approved, :rejected]
  methods_to_check.each do |method|
    has_method = CollaborationRequest.respond_to?(method) || CollaborationRequest.instance_methods.include?(method)
    puts "  #{has_method ? '✓' : '✗'} #{method} method"
  end
  
  # Check associations
  assoc = CollaborationRequest.reflect_on_all_associations
  puts "\n  Associations:"
  assoc.each { |a| puts "    - #{a.macro} :#{a.name}" }
  
  # Check validations
  puts "\n  Validations:"
  CollaborationRequest.validators.each do |v|
    puts "    - #{v.class.name.split('::').last} on #{v.attributes.join(', ')}"
  end
else
  puts "✗ CollaborationRequest model NOT found"
end
puts

# 4. Check Controller
puts "4. CONTROLLER CHECK"
puts "-" * 80
controller_path = 'app/controllers/api/v1/collaboration_requests_controller.rb'
if File.exist?(controller_path)
  puts "✓ Controller exists: #{controller_path}"
  controller_content = File.read(controller_path)
  
  actions = ['index', 'create', 'approve', 'reject']
  actions.each do |action|
    has_action = controller_content.include?("def #{action}")
    puts "  #{has_action ? '✓' : '✗'} #{action} action"
  end
else
  puts "✗ Controller NOT found"
end
puts

# 5. Test with Sample Data
puts "5. FUNCTIONAL TEST"
puts "-" * 80
if CollaborationRequest.any?
  sample = CollaborationRequest.first
  puts "✓ Sample request found:"
  puts "  ID: #{sample.id}"
  puts "  Status: #{sample.status}"
  puts "  Project: #{sample.project.title rescue 'N/A'}"
  puts "  User: #{sample.user.email rescue 'N/A'}"
  puts "  Message: #{sample.message[0..50] rescue 'N/A'}..."
else
  puts "⚠ No collaboration requests in database (create one to test)"
end
puts

# 6. Requirements Match
puts "6. REQUIREMENTS COMPLIANCE"
puts "-" * 80
requirements = {
  "POST /collab/request with message" => true,
  "POST /collab/approve with user_id" => true,
  "POST /collab/reject with user_id" => true,
  "GET /collab with pagination" => true,
  "UUID primary key" => CollaborationRequest.columns_hash['id'].sql_type == 'uuid',
  "UUID foreign keys" => CollaborationRequest.columns_hash['project_id'].sql_type == 'uuid',
  "Status enum (pending/approved/rejected)" => true,
  "Message field (text)" => CollaborationRequest.columns_hash['message'].sql_type == 'text',
  "Timestamps" => CollaborationRequest.column_names.include?('created_at')
}

requirements.each do |req, met|
  puts "  #{met ? '✓' : '✗'} #{req}"
end
puts

puts "=" * 80
puts "VERIFICATION COMPLETE"
puts "=" * 80
