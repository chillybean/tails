def secrets
  Dogtail::Application.new('secrets')
end

Then(/^Secrets tries to open "([^"]*)"$/) do |path|
  secrets.child(File.basename(path), roleName: 'label')
end
