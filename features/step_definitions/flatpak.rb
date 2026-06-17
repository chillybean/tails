When /^I start GNOME Software$/ do
  @gnome_software = launch_gnome_software
  # Wait until it is done "Refreshing Data"
  try_for(60) { @gnome_software.child('Explore', roleName: 'page tab') }
end

When /^I try to start GNOME Software$/ do
  launch_gnome_software(check_started: false)
end

Then /^I see an error about GNOME Software requiring Tor to be ready$/ do
  Dogtail::Application.new('zenity')
                      .dialog('GNOME Software')
                      .child(
                        'GNOME Software can only start once Tor has bootstrapped.',
                        roleName: 'label'
                      )
end

When /^I install (.*) using GNOME Software$/ do |term|
  @gnome_software.child('Explore', roleName: 'page tab').click
  @gnome_software.child('Search', roleName: 'toggle button').click
  try_for(10) { @gnome_software.focused_child.roleName == 'entry' }
  @gnome_software.focused_child.text = term
  @gnome_software.child(term, roleName: 'label').click
  install_button = @gnome_software.button('Install')
  try_for(10) { install_button.sensitive? }
  install_button.click
end

When /^I uninstall (.*) using GNOME Software$/ do |app_name|
  @gnome_software.child('Installed', roleName: 'page tab').click
  # While "Apps" are listed instantaneously "Add-ons" are not showing
  # immediately, and will in fact trigger a loading screen before it
  # loads which is racing with the interaction of the "Uninstall..."
  # button. We have seen that lead to lost clicks, so let's prevent
  # that by waiting for the "Add-ons" to be listed.
  try_for(30) { @gnome_software.child('Add-ons', roleName: 'label') }
  @gnome_software.child(app_name, roleName: 'label')
                 .parent.parent.parent.child('Uninstall…', roleName: 'button').click
  @gnome_software.child("Uninstall #{app_name}?", roleName: 'alert')
                 .button('Uninstall').click
end

When /^I go to the main screen of GNOME Software$/ do
  $vm.execute('gnome-software --mode=overview', user: LIVE_USER)
end

def installed_flatpak_apps
  $vm.execute_successfully(
    'flatpak --user list --app --columns=application', user: LIVE_USER
  ).stdout.split("\n")
end

Then /^the (.*) Flatpak is (un)?installed after at most (\d+) seconds$/ do |app_id, uninstall, timeout|
  try_for(timeout.to_i) do
    installed_flatpak_apps.include?(app_id) == !uninstall
  end
end

When /^I start the (.*) Flatpak$/ do |app_id|
  launch_user_flatpak_app(app_id, check_started: false)
end

def flatpak_running?(app_id)
  $vm.execute(
    'flatpak ps --columns=application', user: LIVE_USER
  ).stdout.split("\n").include?(app_id)
end

Then /^the (.*) Flatpak is running$/ do |app_id|
  try_for(30) do
    flatpak_running?(app_id)
  end
end

When /^I kill the (.*) Flatpak$/ do |app_id|
  $vm.execute_successfully("flatpak kill #{app_id}", user: LIVE_USER)
  try_for(10, msg: "Flatpak #{app_id} could not be killed") do
    !flatpak_running?(app_id)
  end
end
