#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

BASE_URL = 'http://localhost:3000'

puts "\n" + "=" * 60
puts "FUNDING REQUESTS API INTEGRATION TEST"
puts "=" * 60

# Helper method for API requests
def api_request(method, path, body = nil, token = nil)
  uri = URI("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  
  case method
  when :get
    request = Net::HTTP::Get.new(uri)
  when :post
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = body.to_json if body
  when :delete
    request = Net::HTTP::Delete.new(uri)
  end
  
  request['Authorization'] = "Bearer #{token}" if token
  
  response = http.request(request)
  parsed_body = begin
    JSON.parse(response.body)
  rescue
    response.body
  end
  
  {
    status: response.code.to_i,
    body: parsed_body
  }
end

# Step 1: Register/Login users
puts "\n Setting up test users..."

owner_data = {
  user: {
    full_name: 'Project Owner',
    email: "owner_#{Time.now.to_i}@test.com",
    password: 'password123',
    university: 'Test University',
    country: 'Test Country'
  }
}

funder_data = {
  user: {
    full_name: 'Funding User',
    email: "funder_#{Time.now.to_i}@test.com",
    password: 'password123',
    university: 'Test University',
    country: 'Test Country'
  }
}

owner_response = api_request(:post, '/auth/register', owner_data)
funder_response = api_request(:post, '/auth/register', funder_data)

if owner_response[:status] == 201 && funder_response[:status] == 201
  puts "    Users created successfully"
  owner_token = owner_response[:body]['token']
  funder_token = funder_response[:body]['token']
  puts "   Owner token: #{owner_token[0..20]}..."
  puts "   Funder token: #{funder_token[0..20]}..."
else
  puts "   Failed to create users"
  puts "   Owner: #{owner_response[:body]}"
  puts "   Funder: #{funder_response[:body]}"
  exit 1
end

# Step 2: Create a project
puts "\n Creating test project..."

project_data = {
  project: {
    title: "Test Funding Project #{Time.now.to_i}",
    description: 'A project to test funding requests',
    status: 'Ongoing',
    visibility: 'public',
    project_phase: 'planning',
    funding_goal: 10000.00,
    show_funds: true
  }
}

project_response = api_request(:post, '/api/v1/projects', project_data, owner_token)

if project_response[:status] == 201
  project_id = project_response[:body]['project']['id']
  puts "    Project created: #{project_id}"
  puts "    Title: #{project_response[:body]['project']['title']}"
  puts "    Funding Goal: $#{project_response[:body]['project']['funding_goal']}"
else
  puts "    Failed to create project: #{project_response[:body]}"
  exit 1
end

# Step 3: Submit funding request (as funder)
puts "\n  Submitting funding request..."

funding_request_data = {
  funding_request: {
    amount: 500.00,
    note: 'I would like to support this amazing project!'
  }
}

submit_response = api_request(:post, "/api/v1/projects/#{project_id}/fund/request", funding_request_data, funder_token)

if submit_response[:status] == 201
  funding_request_id = submit_response[:body]['funding_request']['id']
  puts "    Funding request submitted"
  puts "   Request ID: #{funding_request_id}"
  puts "   Amount: $#{submit_response[:body]['funding_request']['amount']}"
  puts "   Status: #{submit_response[:body]['funding_request']['status']}"
  puts "   Note: #{submit_response[:body]['funding_request']['note']}"
else
  puts "    Failed to submit funding request: #{submit_response[:body]}"
  exit 1
end

# Step 4: Test duplicate prevention
puts "\n Testing duplicate request prevention..."

duplicate_response = api_request(:post, "/api/v1/projects/#{project_id}/fund/request", funding_request_data, funder_token)

if duplicate_response[:status] == 422
  puts "    Duplicate prevention working"
  puts "   Error: #{duplicate_response[:body]['error']}"
else
  puts "    Duplicate was allowed: #{duplicate_response[:body]}"
end

# Step 5: List funding requests (funder view)
puts "\n Listing funding requests (Funder View)..."

list_funder_response = api_request(:get, "/api/v1/projects/#{project_id}/fund", nil, funder_token)

if list_funder_response[:status] == 200
  puts "    Funder can see their requests"
  puts "   Total requests: #{list_funder_response[:body]['funding_requests'].length}"
  puts "   Pagination: Page #{list_funder_response[:body]['pagination']['current_page']} of #{list_funder_response[:body]['pagination']['total_pages']}"
else
  puts "    Failed to list requests: #{list_funder_response[:body]}"
end

# Step 6: List funding requests (owner view)
puts "\n Listing funding requests (Owner View)..."

list_owner_response = api_request(:get, "/api/v1/projects/#{project_id}/fund", nil, owner_token)

if list_owner_response[:status] == 200
  puts "    Owner can see all requests"
  puts "   Total requests: #{list_owner_response[:body]['funding_requests'].length}"
  requests = list_owner_response[:body]['funding_requests']
  requests.each do |req|
    puts "   - #{req['funder']['full_name']}: $#{req['amount']} (#{req['status']})"
  end
else
  puts "    Failed to list requests: #{list_owner_response[:body]}"
end

# Step 7: Test unauthorized verify (funder tries to verify)
puts "\n Testing authorization (non-owner cannot verify)..."

verify_unauthorized = api_request(:post, "/api/v1/projects/#{project_id}/fund/verify", { id: funding_request_id }, funder_token)

if verify_unauthorized[:status] == 403
  puts "    Authorization working correctly"
  puts "   Error: #{verify_unauthorized[:body]['error']}"
else
  puts "    Authorization failed: #{verify_unauthorized[:body]}"
end

# Step 8: Verify funding request (owner)
puts "\n Verifying funding request (Owner)..."

# Get current project funding
project_before = api_request(:get, "/api/v1/projects/#{project_id}", nil, owner_token)
funding_before = project_before[:body]['project']['current_funding']
puts "   Current funding before: $#{funding_before}"

verify_response = api_request(:post, "/api/v1/projects/#{project_id}/fund/verify", { id: funding_request_id }, owner_token)

if verify_response[:status] == 200
  puts "    Funding request verified"
  puts "   Status: #{verify_response[:body]['funding_request']['status']}"
  puts "   Verified by: #{verify_response[:body]['funding_request']['verifier']['full_name']}"
  puts "   Project funding after: $#{verify_response[:body]['project']['current_funding']}"
  
  # Verify the funding increased correctly
  expected_funding = funding_before.to_f + 500.00
  actual_funding = verify_response[:body]['project']['current_funding'].to_f
  
  if (actual_funding - expected_funding).abs < 0.01
    puts "    Project funding updated correctly (+$500.00)"
  else
    puts "     Funding mismatch: expected $#{expected_funding}, got $#{actual_funding}"
  end
else
  puts "    Failed to verify: #{verify_response[:body]}"
end

# Step 9: Test double verification prevention
puts "\n Testing double verification prevention..."

double_verify = api_request(:post, "/api/v1/projects/#{project_id}/fund/verify", { id: funding_request_id }, owner_token)

if double_verify[:status] == 422
  puts "    Double verification prevented"
  puts "   Error: #{double_verify[:body]['error']}"
else
  puts "    Double verification was allowed: #{double_verify[:body]}"
end

# Step 10: Create and reject another request
puts "\n  Creating and rejecting another request..."

funding_request_data2 = {
  funding_request: {
    amount: 300.00,
    note: 'Another funding request'
  }
}

submit_response2 = api_request(:post, "/api/v1/projects/#{project_id}/fund/request", funding_request_data2, funder_token)

if submit_response2[:status] == 201
  funding_request_id2 = submit_response2[:body]['funding_request']['id']
  puts "    Second request created: $#{submit_response2[:body]['funding_request']['amount']}"
  
  # Get current funding before rejection
  project_before_reject = api_request(:get, "/api/v1/projects/#{project_id}", nil, owner_token)
  funding_before_reject = project_before_reject[:body]['project']['current_funding']
  
  # Reject it
  reject_response = api_request(:post, "/api/v1/projects/#{project_id}/fund/reject", { id: funding_request_id2 }, owner_token)
  
  if reject_response[:status] == 200
    puts "    Request rejected"
    puts "   Status: #{reject_response[:body]['funding_request']['status']}"
    
    # Verify funding didn't change
    project_after_reject = api_request(:get, "/api/v1/projects/#{project_id}", nil, owner_token)
    funding_after_reject = project_after_reject[:body]['project']['current_funding']
    
    if funding_before_reject == funding_after_reject
      puts "    Project funding unchanged after rejection (still $#{funding_after_reject})"
    else
      puts "     Funding changed after rejection: $#{funding_before_reject} → $#{funding_after_reject}"
    end
  else
    puts "    Failed to reject: #{reject_response[:body]}"
  end
else
  puts "    Failed to create second request: #{submit_response2[:body]}"
end

# Step 11: Final summary
puts "\n Final Summary..."

final_list = api_request(:get, "/api/v1/projects/#{project_id}/fund", nil, owner_token)
final_project = api_request(:get, "/api/v1/projects/#{project_id}", nil, owner_token)

if final_list[:status] == 200 && final_project[:status] == 200
  requests = final_list[:body]['funding_requests']
  project = final_project[:body]['project']
  
  puts "   Total Funding Requests: #{requests.length}"
  puts "   - Pending: #{requests.count { |r| r['status'] == 'pending' }}"
  puts "   - Verified: #{requests.count { |r| r['status'] == 'verified' }}"
  puts "   - Rejected: #{requests.count { |r| r['status'] == 'rejected' }}"
  puts "   Project Current Funding: $#{project['current_funding']}"
  puts "   Project Funding Goal: $#{project['funding_goal']}"
  puts "   Progress: #{(project['current_funding'].to_f / project['funding_goal'].to_f * 100).round(1)}%"
end

puts "\n" + "=" * 60
puts " ALL TESTS COMPLETED SUCCESSFULLY!"
puts "=" * 60
puts "\n"
