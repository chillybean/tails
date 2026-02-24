def secrets
  Dogtail::Application.new('secrets')
end

Then(/^dconf has configuration for "Secrets"$/) do
  schema = '/org/gnome/World/Secrets'
  last_db = $vm.execute_successfully("dconf read #{schema}/last-opened-database",
                                     user: 'amnesia')
               .stdout
               .delete_suffix("\n")
               .delete_suffix("'")
               .delete_prefix("'")

  assert_equal('file:///home/amnesia/Persistent/Passwords.kdbx', last_db)
end

Then(/^Secrets tries to open "([^"]*)"$/) do |path|
  secrets.child(File.basename(path), roleName: 'label')
end
