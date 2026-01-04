# Test script for Collaboration Requests API
# Run with: rails runner test_collaboration_requests.rb

puts "🧪 Testing Collaboration Requests Flow\n\n"

# Setup: Find or create test users and project
owner = User.find_or_create_by!(email: 'owner@test.com') do |u|
  u.full_name = 'Project Owner'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.system_role = 'user'
end

requester = User.find_or_create_by!(email: 'requester@test.com') do |u|
  u.full_name = 'Requester User'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.system_role = 'user'
end

project = Project.find_or_create_by!(title: 'Test Collaboration Project') do |p|
  p.owner_id = owner.id
  p.description = 'Testing collaboration requests'
  p.status = 'Ongoing'
  p.visibility = 'public'
end

puts " Setup complete:"
puts "  Owner: #{owner.email} (ID: #{owner.id})"
puts "  Requester: #{requester.email} (ID: #{requester.id})"
puts "  Project: #{project.title} (ID: #{project.id})\n\n"

# Test 1: Create collaboration request
puts "📝 Test 1: User sends collaboration request"
request = CollaborationRequest.create(
  project_id: project.id,
  user_id: requester.id,
  message: "I'd love to contribute to this project!",
  status: 'pending'
)

if request.persisted?
  puts "   Request created successfully"
  puts "     ID: #{request.id}"
  puts "     Status: #{request.status}"
  puts "     Message: #{request.message}\n\n"
else
  puts "   Failed to create request: #{request.errors.full_messages.join(', ')}\n\n"
  exit
end

# Test 2: Check pending requests
puts "📋 Test 2: List pending requests"
pending = project.collaboration_requests.pending
puts "  Found #{pending.count} pending request(s)"
pending.each do |req|
  puts "    - User: #{req.user.full_name} (#{req.user.email})"
  puts "      Message: #{req.message}"
  puts "      Created: #{req.created_at}\n"
end
puts "\n"

# Test 3: Approve the request
puts " Test 3: Owner approves request"
begin
  request.approve!
  puts "   Request approved successfully"
  puts "     New status: #{request.status}"
  
  # Check if collaboration was created
  collab = Collaboration.find_by(project_id: project.id, user_id: requester.id)
  if collab
    puts "      Collaboration created: User is now a #{collab.project_role}\n\n"
  else
    puts "       Warning: Collaboration not created\n\n"
  end
rescue => e
  puts "   Failed to approve: #{e.message}\n\n"
end

# Test 4: Try to create duplicate request (should fail)
puts "🚫 Test 4: Try duplicate request (should fail)"
duplicate = CollaborationRequest.new(
  project_id: project.id,
  user_id: requester.id,
  message: "Another request",
  status: 'pending'
)

if duplicate.save
  puts "   FAIL: Duplicate request was allowed!\n\n"
else
  puts "   PASS: Duplicate request blocked"
  puts "     Error: #{duplicate.errors.full_messages.join(', ')}\n\n"
end

# Test 5: Create and reject a request
puts " Test 5: Create and reject a new request"
new_requester = User.find_or_create_by!(email: 'another@test.com') do |u|
  u.full_name = 'Another User'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.system_role = 'user'
end

reject_request = CollaborationRequest.create(
  project_id: project.id,
  user_id: new_requester.id,
  message: "Can I join?",
  status: 'pending'
)

if reject_request.persisted?
  puts "   Request created"
  reject_request.reject!
  puts "   Request rejected"
  puts "     Status: #{reject_request.status}\n\n"
end

# Final status
puts " Final Status:"
puts "  Total requests: #{project.collaboration_requests.count}"
puts "  Pending: #{project.collaboration_requests.pending.count}"
puts "  Approved: #{project.collaboration_requests.approved.count}"
puts "  Rejected: #{project.collaboration_requests.rejected.count}"
puts "  Total collaborators: #{project.collaborations.count}"

puts "\n All tests completed!"
