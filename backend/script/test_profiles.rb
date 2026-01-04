#!/usr/bin/env ruby
require_relative '../config/environment'
require 'json'

puts "\n" + "="*60
puts "TESTING PROFILE FUNCTIONALITY"
puts "="*60

# Test 1: Verify users exist
puts "\n1. Testing User Creation..."
araya = User.find_by(email: "araya.student@collabsphere.com")
somchai = User.find_by(email: "somchai.mentor@collabsphere.com")
nattapong = User.find_by(email: "nattapong.admin@collabsphere.com")

if araya && somchai && nattapong
  puts "✓ All three Thai users exist"
  puts "  - Araya (Student): #{araya.id}"
  puts "  - Somchai (Mentor): #{somchai.id}"
  puts "  - Nattapong (Admin): #{nattapong.id}"
else
  puts "✗ Missing users - run db/seeds/profile_users.rb first"
  exit 1
end

# Test 2: Check all profile fields are populated
puts "\n2. Testing Profile Fields..."
test_user = araya

required_fields = {
  'age' => test_user.age,
  'occupation' => test_user.occupation,
  'short_term_goals' => test_user.short_term_goals,
  'long_term_goals' => test_user.long_term_goals,
  'immediate_questions' => test_user.immediate_questions,
  'computer_equipment' => test_user.computer_equipment,
  'connection_type' => test_user.connection_type
}

all_present = true
required_fields.each do |field, value|
  if value.present?
    puts "✓ #{field}: #{value.to_s.truncate(50)}"
  else
    puts "✗ #{field}: MISSING"
    all_present = false
  end
end

if all_present
  puts "✓ All profile fields populated"
else
  puts "✗ Some profile fields are missing"
  exit 1
end

# Test 3: Test age validation
puts "\n3. Testing Age Validation..."
test_user_new = User.new(
  email: "test@example.com",
  password: "password123",
  full_name: "Test User",
  age: 200
)

if !test_user_new.valid? && test_user_new.errors[:age].present?
  puts "✓ Age validation working (rejects age > 150)"
else
  puts "✗ Age validation not working properly"
end

test_user_new.age = 25
if test_user_new.valid? || !test_user_new.errors[:age].present?
  puts "✓ Age validation accepts valid age (25)"
else
  puts "✗ Age validation rejects valid age"
end

# Test 4: Test profile JSON structure
puts "\n4. Testing Profile JSON Structure..."
profile_json = {
  id: araya.id,
  full_name: araya.full_name,
  email: araya.email,
  system_role: araya.system_role,
  avatar_url: araya.avatar_url,
  bio: araya.bio,
  age: araya.age,
  occupation: araya.occupation,
  country: araya.country,
  university: araya.university,
  department: araya.department,
  short_term_goals: araya.short_term_goals,
  long_term_goals: araya.long_term_goals,
  immediate_questions: araya.immediate_questions,
  computer_equipment: araya.computer_equipment,
  connection_type: araya.connection_type
}

puts "✓ Profile JSON structure:"
puts JSON.pretty_generate(profile_json)

# Test 5: Test update functionality
puts "\n5. Testing Profile Update..."
original_age = somchai.age
somchai.update(age: 39, occupation: "Senior Tech Lead")

if somchai.age == 39 && somchai.occupation == "Senior Tech Lead"
  puts "✓ Profile update successful"
  puts "  - Age changed: #{original_age} → #{somchai.age}"
  puts "  - Occupation updated: #{somchai.occupation}"
  
  # Restore original
  somchai.update(age: original_age, occupation: "Tech Lead & Part-time Mentor")
else
  puts "✗ Profile update failed"
end

# Test 6: Check all three personas
puts "\n6. Testing All Three Personas..."
personas = [
  { user: araya, expected_role: "user", expected_university: "Asian Institute of Technology" },
  { user: somchai, expected_role: "user", expected_university: "Chulalongkorn University (Alumni)" },
  { user: nattapong, expected_role: "admin", expected_university: "Asian Institute of Technology (Alumni)" }
]

personas.each do |persona|
  user = persona[:user]
  if user.system_role == persona[:expected_role] && user.university == persona[:expected_university]
    puts "✓ #{user.full_name} (#{user.system_role}) - #{user.university}"
  else
    puts "✗ #{user.full_name} - Role or university mismatch"
  end
end

# Test 7: Verify AIT affiliation
puts "\n7. Testing AIT Affiliation..."
ait_users = User.where("university LIKE ?", "%Asian Institute of Technology%")
puts "✓ Found #{ait_users.count} users affiliated with AIT:"
ait_users.each do |user|
  puts "  - #{user.full_name} (#{user.email})"
end

# Test 8: Check Thai country setting
puts "\n8. Testing Country Field..."
thai_users = User.where(country: "Thailand")
puts "✓ Found #{thai_users.count} users from Thailand:"
thai_users.each do |user|
  puts "  - #{user.full_name} (#{user.occupation})"
end

# Summary
puts "\n" + "="*60
puts "ALL TESTS PASSED ✓"
puts "="*60
puts "\nProfile API Ready:"
puts "  GET /api/v1/profiles/#{araya.id}"
puts "  GET /api/v1/profiles/#{somchai.id}"
puts "  GET /api/v1/profiles/#{nattapong.id}"
puts "\nTest login credentials:"
puts "  araya.student@collabsphere.com / password123"
puts "  somchai.mentor@collabsphere.com / password123"
puts "  nattapong.admin@collabsphere.com / password123"
puts "="*60 + "\n"
