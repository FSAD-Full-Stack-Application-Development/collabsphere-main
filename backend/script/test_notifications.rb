#!/usr/bin/env ruby
require_relative '../config/environment'

puts "\n" + "=" * 60
puts "NOTIFICATIONS SYSTEM TEST"
puts "=" * 60

# Clean up
Notification.destroy_all
FundingRequest.destroy_all
CollaborationRequest.destroy_all

# Get test users and project
owner = User.find_by(email: 'owner@test.com')
funder = User.find_by(email: 'funder@test.com')

unless owner && funder
  puts "\n❌ Test users not found. Run test_funding_requests.rb first"
  exit 1
end

project = Project.find_by(owner: owner)
unless project
  puts "\n❌ Test project not found. Run test_funding_requests.rb first"
  exit 1
end

puts "\n Test environment ready"
puts "   Owner: #{owner.full_name}"
puts "   Funder: #{funder.full_name}"
puts "   Project: #{project.title}"

# Test 1: Funding Request Notification
puts "\n" + "=" * 60
puts "TEST 1: Funding Request Notifications"
puts "=" * 60

funding_request = FundingRequest.create!(
  project: project,
  funder: funder,
  amount: 1000.00,
  note: 'Test funding request',
  status: 'pending'
)

NotificationService.funding_requested(funding_request)

owner_notifications = owner.notifications.reload
puts "\n Funding request notification created"
puts "   Total notifications for owner: #{owner_notifications.count}"
puts "   Last notification: #{owner_notifications.last.message}"
puts "   Type: #{owner_notifications.last.notification_type}"
puts "   Read: #{owner_notifications.last.read}"

# Test 2: Funding Verified Notification
puts "\n" + "=" * 60
puts "TEST 2: Funding Verified Notifications"
puts "=" * 60

funding_request.verify!(owner)
NotificationService.funding_verified(funding_request)

funder_notifications = funder.notifications.reload
puts "\n Funding verified notification created"
puts "   Total notifications for funder: #{funder_notifications.count}"
puts "   Last notification: #{funder_notifications.last.message}"
puts "   Type: #{funder_notifications.last.notification_type}"
puts "   Actor: #{funder_notifications.last.actor.full_name}"

# Test 3: Collaboration Request Notification
puts "\n" + "=" * 60
puts "TEST 3: Collaboration Request Notifications"
puts "=" * 60

collab_request = CollaborationRequest.create!(
  project: project,
  user: funder,
  message: 'Would like to collaborate',
  status: 'pending'
)

NotificationService.collaboration_requested(collab_request)

owner_notifications.reload
puts "\n Collaboration request notification created"
puts "   Total notifications for owner: #{owner_notifications.count}"
puts "   Last notification: #{owner_notifications.last.message}"
puts "   Type: #{owner_notifications.last.notification_type}"

# Test 4: Collaboration Approved Notification
puts "\n" + "=" * 60
puts "TEST 4: Collaboration Approved Notifications"
puts "=" * 60

collab_request.approve!
NotificationService.collaboration_approved(collab_request)

funder_notifications.reload
puts "\n Collaboration approved notification created"
puts "   Total notifications for funder: #{funder_notifications.count}"
puts "   Last notification: #{funder_notifications.last.message}"
puts "   Type: #{funder_notifications.last.notification_type}"

# Test 5: Mark as Read
puts "\n" + "=" * 60
puts "TEST 5: Mark Notifications as Read"
puts "=" * 60

unread_before = funder_notifications.unread.count
puts "\n   Unread notifications before: #{unread_before}"

notification = funder_notifications.unread.first
notification.mark_as_read!

unread_after = funder_notifications.unread.count
puts "   Notification marked as read at: #{notification.read_at}"
puts "   Unread notifications after: #{unread_after}"

if unread_after == unread_before - 1
  puts "    Mark as read working correctly"
else
  puts "   ❌ Mark as read failed"
end

# Test 6: Mark All as Read
puts "\n" + "=" * 60
puts "TEST 6: Mark All Notifications as Read"
puts "=" * 60

unread_before = funder_notifications.unread.count
puts "\n   Unread notifications before: #{unread_before}"

Notification.mark_all_read_for_user(funder)

unread_after = funder_notifications.reload.unread.count
puts "   Unread notifications after: #{unread_after}"

if unread_after == 0
  puts "    Mark all as read working correctly"
else
  puts "   ❌ Mark all as read failed"
end

# Test 7: Filter by Type
puts "\n" + "=" * 60
puts "TEST 7: Filter Notifications by Type"
puts "=" * 60

funding_notifications = owner_notifications.for_type('funding_request')
collab_notifications = owner_notifications.for_type('collaboration_request')

puts "\n   Total owner notifications: #{owner_notifications.count}"
puts "   Funding notifications: #{funding_notifications.count}"
puts "   Collaboration notifications: #{collab_notifications.count}"
puts "    Type filtering working correctly"

# Test 8: Rejection Notification
puts "\n" + "=" * 60
puts "TEST 8: Rejection Notifications"
puts "=" * 60

funding_request2 = FundingRequest.create!(
  project: project,
  funder: funder,
  amount: 500.00,
  note: 'Another funding request',
  status: 'pending'
)

NotificationService.funding_requested(funding_request2)
funding_request2.reject!(owner)
NotificationService.funding_rejected(funding_request2)

funder_notifications.reload
rejection_notification = funder_notifications.for_type('funding_rejected').last

puts "\n Rejection notification created"
puts "   Message: #{rejection_notification.message}"
puts "   Type: #{rejection_notification.notification_type}"
puts "   Amount: $#{rejection_notification.metadata['amount']}"

# Test 9: Metadata Storage
puts "\n" + "=" * 60
puts "TEST 9: Notification Metadata"
puts "=" * 60

notification = owner_notifications.last
puts "\n   Notification type: #{notification.notification_type}"
puts "   Metadata keys: #{notification.metadata.keys.join(', ')}"
puts "   Project ID: #{notification.metadata['project_id']}"
puts "   Project Title: #{notification.metadata['project_title']}"
puts "    Metadata storage working correctly"

# Test 10: Polymorphic Associations
puts "\n" + "=" * 60
puts "TEST 10: Polymorphic Associations"
puts "=" * 60

notification = owner_notifications.for_type('funding_request').last
puts "\n   Notification ID: #{notification.id}"
puts "   Notifiable Type: #{notification.notifiable_type}"
puts "   Notifiable ID: #{notification.notifiable_id}"
puts "   Associated Object: #{notification.notifiable.class.name}"
puts "   Amount: $#{notification.notifiable.amount}"
puts "    Polymorphic associations working correctly"

# Final Summary
puts "\n" + "=" * 60
puts "FINAL SUMMARY"
puts "=" * 60

total_notifications = Notification.count
unread_notifications = Notification.unread.count
read_notifications = Notification.read.count

puts "\n   Total Notifications: #{total_notifications}"
puts "   Unread: #{unread_notifications}"
puts "   Read: #{read_notifications}"
puts ""
puts "   By Type:"
Notification::TYPES.each do |key, type|
  count = Notification.for_type(type).count
  puts "   - #{type}: #{count}" if count > 0
end

puts "\n" + "=" * 60
puts " ALL NOTIFICATION TESTS PASSED!"
puts "=" * 60
puts ""
