namespace :db do
  namespace :backup do
    desc 'Create database backup'
    task create: :environment do
      require 'fileutils'
      
      # Configuration
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      db_name = config[:database]
      db_user = config[:username] || ENV['USER']
      db_host = config[:host] || 'localhost'
      db_port = config[:port] || 5432
      
      # Backup directory
      backup_dir = Rails.root.join('backups')
      FileUtils.mkdir_p(backup_dir)
      
      # Backup filename with timestamp
      timestamp = Time.current.strftime('%Y-%m-%d_%H-%M-%S')
      backup_file = backup_dir.join("#{db_name}_#{timestamp}.dump")
      compressed_file = "#{backup_file}.gz"
      
      # Create backup using pg_dump
      puts "=" * 80
      puts "DATABASE BACKUP STARTED"
      puts "=" * 80
      puts "Database: #{db_name}"
      puts "Host: #{db_host}:#{db_port}"
      puts "User: #{db_user}"
      puts "Timestamp: #{timestamp}"
      puts "Backup file: #{backup_file}"
      puts "-" * 80
      
      # Set PGPASSWORD environment variable if password exists
      ENV['PGPASSWORD'] = config[:password] if config[:password]
      
      # Run pg_dump with custom format (-Fc for better compression)
      command = "pg_dump -Fc -h #{db_host} -p #{db_port} -U #{db_user} #{db_name} > #{backup_file}"
      
      if system(command)
        file_size = File.size(backup_file)
        puts "✓ Backup created successfully"
        puts "  Size: #{format_bytes(file_size)}"
        
        # Compress with gzip for additional compression
        puts "-" * 80
        puts "Compressing backup..."
        if system("gzip -9 #{backup_file}")
          compressed_size = File.size(compressed_file)
          compression_ratio = ((1 - compressed_size.to_f / file_size) * 100).round(2)
          puts "✓ Backup compressed successfully"
          puts "  Compressed size: #{format_bytes(compressed_size)}"
          puts "  Compression ratio: #{compression_ratio}%"
          
          # Log the backup
          log_backup(compressed_file, compressed_size, timestamp)
          
          # Rotate old backups
          rotate_backups(backup_dir)
          
          puts "=" * 80
          puts "BACKUP COMPLETE: #{compressed_file}"
          puts "=" * 80
        else
          puts "✗ Compression failed, but uncompressed backup exists at #{backup_file}"
        end
      else
        puts "✗ Backup failed!"
        exit 1
      end
      
      # Clear password from environment
      ENV.delete('PGPASSWORD')
    end
    
    desc 'Restore database from backup'
    task :restore, [:backup_file] => :environment do |t, args|
      unless args[:backup_file]
        puts "Usage: rails db:backup:restore[path/to/backup.dump.gz]"
        puts "\nAvailable backups:"
        list_backups
        exit 1
      end
      
      backup_file = args[:backup_file]
      unless File.exist?(backup_file)
        puts "✗ Backup file not found: #{backup_file}"
        exit 1
      end
      
      # Configuration
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      db_name = config[:database]
      db_user = config[:username] || ENV['USER']
      db_host = config[:host] || 'localhost'
      db_port = config[:port] || 5432
      
      puts "=" * 80
      puts "DATABASE RESTORE"
      puts "=" * 80
      puts "  WARNING: This will DESTROY all data in #{db_name}!"
      puts "Backup file: #{backup_file}"
      puts "-" * 80
      print "Type 'YES' to continue: "
      confirmation = STDIN.gets.chomp
      
      unless confirmation == 'YES'
        puts "Restore cancelled."
        exit 0
      end
      
      # Decompress if needed
      working_file = backup_file
      if backup_file.end_with?('.gz')
        puts "Decompressing backup..."
        working_file = backup_file.gsub('.gz', '')
        system("gunzip -c #{backup_file} > #{working_file}")
      end
      
      # Set password
      ENV['PGPASSWORD'] = config[:password] if config[:password]
      
      # Drop and recreate database
      puts "Dropping existing database..."
      Rake::Task['db:drop'].invoke
      
      puts "Creating new database..."
      Rake::Task['db:create'].invoke
      
      # Restore from backup
      puts "Restoring from backup..."
      command = "pg_restore -h #{db_host} -p #{db_port} -U #{db_user} -d #{db_name} #{working_file}"
      
      if system(command)
        puts "✓ Database restored successfully"
        
        # Clean up decompressed file if we created it
        File.delete(working_file) if backup_file.end_with?('.gz') && File.exist?(working_file)
        
        # Log the restore
        log_restore(backup_file)
        
        puts "=" * 80
        puts "RESTORE COMPLETE"
        puts "=" * 80
      else
        puts "✗ Restore failed!"
        exit 1
      end
      
      ENV.delete('PGPASSWORD')
    end
    
    desc 'List available backups'
    task list: :environment do
      list_backups
    end
    
    desc 'Test restore (creates test database and restores)'
    task :test_restore, [:backup_file] => :environment do |t, args|
      unless args[:backup_file]
        puts "Usage: rails db:backup:test_restore[path/to/backup.dump.gz]"
        exit 1
      end
      
      backup_file = args[:backup_file]
      unless File.exist?(backup_file)
        puts "✗ Backup file not found: #{backup_file}"
        exit 1
      end
      
      # Configuration
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      test_db_name = "#{config[:database]}_restore_test"
      db_user = config[:username] || ENV['USER']
      db_host = config[:host] || 'localhost'
      db_port = config[:port] || 5432
      
      puts "=" * 80
      puts "RESTORE TEST"
      puts "=" * 80
      puts "Backup file: #{backup_file}"
      puts "Test database: #{test_db_name}"
      puts "-" * 80
      
      # Decompress if needed
      working_file = backup_file
      if backup_file.end_with?('.gz')
        puts "Decompressing backup..."
        working_file = backup_file.gsub('.gz', '')
        system("gunzip -c #{backup_file} > #{working_file}")
      end
      
      # Set password
      ENV['PGPASSWORD'] = config[:password] if config[:password]
      
      # Create test database
      puts "Creating test database..."
      system("createdb -h #{db_host} -p #{db_port} -U #{db_user} #{test_db_name}")
      
      # Restore to test database
      puts "Restoring to test database..."
      command = "pg_restore -h #{db_host} -p #{db_port} -U #{db_user} -d #{test_db_name} #{working_file}"
      
      if system(command)
        puts "✓ Restore test successful"
        
        # Verify data
        puts "\nVerifying restored data..."
        verify_command = "psql -h #{db_host} -p #{db_port} -U #{db_user} -d #{test_db_name} -c \"SELECT 'users' as table_name, COUNT(*) as count FROM users UNION ALL SELECT 'projects', COUNT(*) FROM projects UNION ALL SELECT 'collaborations', COUNT(*) FROM collaborations;\""
        system(verify_command)
        
        # Cleanup
        puts "\nCleaning up test database..."
        system("dropdb -h #{db_host} -p #{db_port} -U #{db_user} #{test_db_name}")
        
        # Clean up decompressed file
        File.delete(working_file) if backup_file.end_with?('.gz') && File.exist?(working_file)
        
        puts "=" * 80
        puts "RESTORE TEST COMPLETE - Backup is valid!"
        puts "=" * 80
      else
        puts "✗ Restore test failed!"
        system("dropdb -h #{db_host} -p #{db_port} -U #{db_user} #{test_db_name}") rescue nil
        exit 1
      end
      
      ENV.delete('PGPASSWORD')
    end
    
    desc 'Rotate old backups (keep last 7 days, weekly for 4 weeks, monthly for 6 months)'
    task rotate: :environment do
      backup_dir = Rails.root.join('backups')
      rotate_backups(backup_dir)
    end
    
    # Helper methods
    def format_bytes(bytes)
      if bytes < 1024
        "#{bytes} B"
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(2)} KB"
      elsif bytes < 1024 * 1024 * 1024
        "#{(bytes / (1024.0 * 1024)).round(2)} MB"
      else
        "#{(bytes / (1024.0 * 1024 * 1024)).round(2)} GB"
      end
    end
    
    def log_backup(backup_file, size, timestamp)
      log_file = Rails.root.join('backups', 'backup.log')
      File.open(log_file, 'a') do |f|
        f.puts "#{timestamp} | BACKUP_CREATED | #{File.basename(backup_file)} | #{format_bytes(size)}"
      end
    end
    
    def log_restore(backup_file)
      log_file = Rails.root.join('backups', 'backup.log')
      timestamp = Time.current.strftime('%Y-%m-%d_%H-%M-%S')
      File.open(log_file, 'a') do |f|
        f.puts "#{timestamp} | RESTORE | #{File.basename(backup_file)}"
      end
    end
    
    def list_backups
      backup_dir = Rails.root.join('backups')
      backups = Dir.glob(backup_dir.join('*.dump.gz')).sort.reverse
      
      if backups.empty?
        puts "No backups found in #{backup_dir}"
      else
        puts "Available backups in #{backup_dir}:"
        puts "-" * 80
        backups.each do |backup|
          size = File.size(backup)
          mtime = File.mtime(backup)
          age = ((Time.current - mtime) / 86400).round(1)
          puts "  #{File.basename(backup)}"
          puts "    Size: #{format_bytes(size)} | Age: #{age} days | Modified: #{mtime}"
        end
      end
    end
    
    def rotate_backups(backup_dir)
      puts "\nRotating old backups..."
      backups = Dir.glob(backup_dir.join('*.dump.gz')).sort.reverse
      
      now = Time.current
      keep_daily = 7    # Keep last 7 days
      keep_weekly = 4   # Keep 4 weeks
      keep_monthly = 6  # Keep 6 months
      
      daily_cutoff = now - keep_daily.days
      weekly_cutoff = now - keep_weekly.weeks
      monthly_cutoff = now - keep_monthly.months
      
      backups_by_period = { daily: [], weekly: [], monthly: [], old: [] }
      
      backups.each do |backup|
        mtime = File.mtime(backup)
        
        if mtime > daily_cutoff
          backups_by_period[:daily] << backup
        elsif mtime > weekly_cutoff && mtime.wday == 0 # Sunday
          backups_by_period[:weekly] << backup
        elsif mtime > monthly_cutoff && mtime.day == 1 # First of month
          backups_by_period[:monthly] << backup
        else
          backups_by_period[:old] << backup
        end
      end
      
      # Keep only one backup per week/month period
      backups_by_period[:weekly] = backups_by_period[:weekly].uniq { |b| File.mtime(b).strftime('%Y-%W') }
      backups_by_period[:monthly] = backups_by_period[:monthly].uniq { |b| File.mtime(b).strftime('%Y-%m') }
      
      # Delete old backups
      deleted_count = 0
      deleted_size = 0
      
      backups_by_period[:old].each do |backup|
        size = File.size(backup)
        File.delete(backup)
        deleted_count += 1
        deleted_size += size
        puts "  Deleted: #{File.basename(backup)} (#{format_bytes(size)})"
      end
      
      kept_count = backups_by_period.values.flatten.uniq.count - deleted_count
      puts "✓ Rotation complete: #{kept_count} kept, #{deleted_count} deleted (freed #{format_bytes(deleted_size)})"
    end
  end
end
