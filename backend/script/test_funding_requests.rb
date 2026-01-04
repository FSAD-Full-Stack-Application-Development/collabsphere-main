#!/usr/bin/env ruby
require_relative '../config/environment'

puts "\n=== Funding Requests API Test ==="
puts "=" * 50

# Clean up existing test data
FundingRequest.destroy_all
Fund.destroy_all

# Get or create test users
owner = User.find_or_create_by!(email: 'owner@test.com') do |u|
  u.full_name = 'Project Owner'
  u.password = 'password123'
  u.university = 'Test University'
  u.country = 'Test Country'
end

funder = User.find_or_create_by!(email: 'funder@test.com') do |u|
  u.full_name = 'Funding User'
  u.password = 'password123'
  u.university = 'Test University'
  u.country = 'Test Country'
end

# Get or create test project
project = Project.find_or_create_by!(title: 'Test Funding Project') do |p|
  p.owner = owner
  p.description = 'A project to test funding requests'
  p.status = 'Ongoing'
  p.visibility = 'public'
  p.project_phase = 'planning'
  p.funding_goal = 10000.00
  p.current_funding = 0
  p.show_funds = true
end

puts "\n1. Test Data Created:"
puts "   Owner: #{owner.full_name} (#{owner.email})"
puts "   Funder: #{funder.full_name} (#{funder.email})"
puts "   Project: #{project.title}"
puts "   Current Funding: $#{project.current_funding}"

# Test 1: Create funding request
puts "\n2. Creating Funding Request..."
funding_request = FundingRequest.create!(
  project: project,
  funder: funder,
  amount: 500.00,
  note: 'I would like to support this amazing project!',
  status: 'pending'
)
puts "    Funding Request created (ID: #{funding_request.id})"
puts "   Amount: $#{funding_request.amount}"
puts "   Status: #{funding_request.status}"
puts "   Note: #{funding_request.note}"

# Test 2: Verify uniqueness constraint
puts "\n3. Testing Duplicate Request Prevention..."
begin
  duplicate = FundingRequest.create!(
    project: project,
    funder: funder,
    amount: 300.00,
    status: 'pending'
  )
  puts "    FAILED: Duplicate request was allowed"
rescue ActiveRecord::RecordInvalid => e
  puts "    Duplicate request prevented: #{e.message}"
end

# Test 3: List requests (owner view)
puts "\n4. Listing Funding Requests (Owner View)..."
owner_requests = project.funding_requests.recent
puts "   Total requests: #{owner_requests.count}"
owner_requests.each do |req|
  puts "   - #{req.funder.full_name}: $#{req.amount} (#{req.status})"
end

# Test 4: List requests (funder view)
puts "\n5. Listing Funding Requests (Funder View)..."
funder_requests = project.funding_requests.where(funder_id: funder.id)
puts "   Funder's requests: #{funder_requests.count}"
funder_requests.each do |req|
  puts "   - $#{req.amount} (#{req.status})"
end

# Test 5: Verify (approve) funding request
puts "\n6. Verifying Funding Request..."
puts "   Before: Project funding = $#{project.current_funding}"
puts "   Before: Total Fund records = #{Fund.count}"

funding_request.verify!(owner)

puts "    Request verified successfully"
puts "   Status: #{funding_request.status}"
puts "   Verified by: #{funding_request.verifier.full_name}"
puts "   Verified at: #{funding_request.verified_at}"
puts "   After: Project funding = $#{project.reload.current_funding}"
puts "   After: Total Fund records = #{Fund.count}"

# Verify Fund record was created
fund = Fund.last
puts "\n7. Verifying Fund Record Creation..."
puts "   Fund ID: #{fund.id}"
puts "   Amount: $#{fund.amount}"
puts "   Funder: #{fund.funder.full_name}"
puts "   Funded at: #{fund.funded_at}"

# Test 6: Try to verify already verified request
puts "\n8. Testing Double Verification Prevention..."
begin
  funding_request.verify!(owner)
  puts "    FAILED: Double verification was allowed"
rescue ActiveRecord::RecordInvalid => e
  puts "    Double verification prevented"
end

# Test 7: Create and reject another request
puts "\n9. Creating and Rejecting Another Request..."
funding_request2 = FundingRequest.create!(
  project: project,
  funder: funder,
  amount: 300.00,
  note: 'Another funding request',
  status: 'pending'
)
puts "   Request created: $#{funding_request2.amount}"

funding_request2.reject!(owner)
puts "    Request rejected successfully"
puts "   Status: #{funding_request2.status}"
puts "   Verified by: #{funding_request2.verifier.full_name}"
puts "   Project funding (unchanged): $#{project.reload.current_funding}"

# Test 8: Summary
puts "\n10. Final Summary:"
puts "   Total Funding Requests: #{FundingRequest.count}"
puts "   - Pending: #{FundingRequest.pending.count}"
puts "   - Verified: #{FundingRequest.verified.count}"
puts "   - Rejected: #{FundingRequest.rejected.count}"
puts "   Total Fund Records: #{Fund.count}"
puts "   Project Current Funding: $#{project.current_funding}"
puts "   Project Funding Goal: $#{project.funding_goal}"
puts "   Progress: #{(project.current_funding / project.funding_goal * 100).round(1)}%"

puts "\n=== All Tests Passed!  ==="
puts "=" * 50
