#!/usr/bin/env ruby
require_relative '../config/environment'

puts "\n" + "="*70
puts "COMPREHENSIVE BACKEND FUNCTIONALITY TEST"
puts "="*70

test_results = {
  passed: 0,
  failed: 0,
  tests: []
}

def test(name)
  print "\nTesting: #{name}... "
  result = yield
  if result
    puts "✓ PASSED"
    { name: name, status: :passed }
  else
    puts "✗ FAILED"
    { name: name, status: :failed }
  end
rescue => e
  puts "✗ ERROR: #{e.message}"
  { name: name, status: :failed, error: e.message }
end

# ==========================================
# 1. DATABASE & MODELS
# ==========================================
puts "\n#{'-'*70}"
puts "1. DATABASE & MODEL TESTS"
puts "-"*70

test_results[:tests] << test("Database connection") do
  ActiveRecord::Base.connection.execute("SELECT 1")
  true
rescue => e
  false
end

test_results[:tests] << test("User model") do
  User.count >= 0 && User.new.respond_to?(:email)
end

test_results[:tests] << test("Project model") do
  Project.count >= 0 && Project.new.respond_to?(:title)
end

test_results[:tests] << test("Profile fields exist") do
  user = User.first
  user.respond_to?(:age) && 
  user.respond_to?(:occupation) && 
  user.respond_to?(:short_term_goals)
end

test_results[:tests] << test("Thai users exist") do
  User.where(country: "Thailand").count == 3
end

test_results[:tests] << test("AIT affiliation") do
  User.where("university LIKE ?", "%Asian Institute of Technology%").count >= 2
end

# ==========================================
# 2. AUTHENTICATION
# ==========================================
puts "\n#{'-'*70}"
puts "2. AUTHENTICATION TESTS"
puts "-"*70

araya = User.find_by(email: "araya.student@collabsphere.com")

test_results[:tests] << test("User authentication") do
  araya && araya.authenticate("password123")
end

test_results[:tests] << test("JWT token generation") do
  token = JsonWebToken.encode(user_id: araya.id)
  decoded = JsonWebToken.decode(token)
  decoded[:user_id] == araya.id
end

test_results[:tests] << test("Password validation") do
  !araya.authenticate("wrongpassword")
end

# ==========================================
# 3. PROFILES
# ==========================================
puts "\n#{'-'*70}"
puts "3. PROFILE TESTS"
puts "-"*70

test_results[:tests] << test("Profile data complete") do
  araya.age.present? &&
  araya.occupation.present? &&
  araya.short_term_goals.present? &&
  araya.long_term_goals.present? &&
  araya.computer_equipment.present?
end

test_results[:tests] << test("Profile update") do
  original_age = araya.age
  araya.update(age: 23)
  success = araya.age == 23
  araya.update(age: original_age) # Restore
  success
end

test_results[:tests] << test("Age validation") do
  invalid_user = User.new(
    email: "test@test.com",
    password: "password123",
    full_name: "Test",
    age: 200
  )
  !invalid_user.valid? && invalid_user.errors[:age].present?
end

# ==========================================
# 4. PROJECTS
# ==========================================
puts "\n#{'-'*70}"
puts "4. PROJECT TESTS"
puts "-"*70

test_results[:tests] << test("Create project") do
  project = Project.create(
    title: "Test Backend Project",
    description: "Testing project creation",
    owner: araya,
    status: "Ongoing",
    visibility: "public"
  )
  success = project.persisted?
  project.destroy if project.persisted?
  success
end

test_results[:tests] << test("Project listing") do
  Project.count > 0
end

test_results[:tests] << test("Project visibility") do
  Project.where(visibility: "public").count > 0
end

# ==========================================
# 5. TAGS & SUGGESTIONS
# ==========================================
puts "\n#{'-'*70}"
puts "5. TAG & SUGGESTION TESTS"
puts "-"*70

test_results[:tests] << test("Tag model") do
  Tag.count >= 0
end

test_results[:tests] << test("University suggestions") do
  universities = User.where("university LIKE ?", "%Technology%")
                     .where.not(university: [nil, ''])
                     .select(:university)
                     .distinct
                     .pluck(:university)
  universities.any?
end

test_results[:tests] << test("Country suggestions") do
  countries = User.where("country LIKE ?", "%Thai%")
                  .where.not(country: [nil, ''])
                  .select(:country)
                  .distinct
                  .pluck(:country)
  countries.any?
end

# ==========================================
# 6. MODERATION
# ==========================================
puts "\n#{'-'*70}"
puts "6. MODERATION TESTS"
puts "-"*70

test_results[:tests] << test("Moderation fields exist") do
  User.column_names.include?('is_suspended') &&
  Project.column_names.include?('is_hidden') &&
  Comment.column_names.include?('is_hidden')
end

test_results[:tests] << test("User suspension") do
  admin = User.find_by(system_role: 'admin')
  if admin.nil?
    # Create a temporary admin if none exists
    admin = User.create!(
      email: "temp_admin_#{Time.now.to_i}@test.com",
      password: "password123",
      full_name: "Temp Admin",
      system_role: "admin"
    )
    created_admin = true
  end
  
  test_user = User.create!(
    email: "suspend_test_#{Time.now.to_i}@test.com",
    password: "password123",
    full_name: "Suspend Test"
  )
  
  test_user.suspend!(reason: "Test suspension", admin: admin)
  success = test_user.suspended?
  
  test_user.destroy
  admin.destroy if created_admin
  success
end

test_results[:tests] << test("SpamFilter service exists") do
  defined?(SpamFilter) && SpamFilter.respond_to?(:spam?)
end

# ==========================================
# 7. NOTIFICATIONS
# ==========================================
puts "\n#{'-'*70}"
puts "7. NOTIFICATION TESTS"
puts "-"*70

test_results[:tests] << test("Notification model") do
  Notification.count >= 0
end

test_results[:tests] << test("Notification types") do
  # Check if notification_type column exists and TYPES constant is defined
  Notification.column_names.include?('notification_type') &&
  defined?(Notification::TYPES) &&
  Notification::TYPES.key?(:collaboration_request)
end

# ==========================================
# 8. MESSAGING
# ==========================================
puts "\n#{'-'*70}"
puts "8. MESSAGING TESTS"
puts "-"*70

test_results[:tests] << test("Message model") do
  Message.count >= 0 && Message.new.respond_to?(:content)
end

# ==========================================
# 9. COLLABORATIONS & FUNDING
# ==========================================
puts "\n#{'-'*70}"
puts "9. COLLABORATION & FUNDING TESTS"
puts "-"*70

test_results[:tests] << test("Collaboration model") do
  Collaboration.count >= 0
end

test_results[:tests] << test("Fund model") do
  Fund.count >= 0
end

# ==========================================
# 10. ASSOCIATIONS
# ==========================================
puts "\n#{'-'*70}"
puts "10. ASSOCIATION TESTS"
puts "-"*70

test_results[:tests] << test("User has projects") do
  User.reflect_on_association(:owned_projects).present?
end

test_results[:tests] << test("Project has owner") do
  Project.reflect_on_association(:owner).present?
end

test_results[:tests] << test("Project has tags") do
  Project.reflect_on_association(:tags).present?
end

test_results[:tests] << test("User has notifications") do
  User.reflect_on_association(:notifications).present?
end

# ==========================================
# CALCULATE RESULTS
# ==========================================
test_results[:tests].each do |result|
  if result[:status] == :passed
    test_results[:passed] += 1
  else
    test_results[:failed] += 1
  end
end

total = test_results[:passed] + test_results[:failed]

# ==========================================
# SUMMARY
# ==========================================
puts "\n" + "="*70
puts "TEST SUMMARY"
puts "="*70
puts "Total Tests:  #{total}"
puts "Passed:       #{test_results[:passed]} (#{(test_results[:passed].to_f / total * 100).round(1)}%)"
puts "Failed:       #{test_results[:failed]}"

if test_results[:failed] > 0
  puts "\nFailed Tests:"
  test_results[:tests].select { |t| t[:status] == :failed }.each do |t|
    puts "  ✗ #{t[:name]}"
    puts "    Error: #{t[:error]}" if t[:error]
  end
end

puts "\n" + "="*70
if test_results[:failed] == 0
  puts "✓ ALL BACKEND TESTS PASSED!"
  exit 0
else
  puts "✗ SOME TESTS FAILED"
  exit 1
end
puts "="*70 + "\n"
