When /^I start GNOME Software$/ do
  @gnome_software = launch_gnome_software
  # Wait until it is done "Refreshing Data"
  try_for(60) { @gnome_software.child('Explore', roleName: 'page tab') }
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

Then /^the (.*) Flatpak is running$/ do |app_id|
  try_for(30) do
    $vm.execute(
      'flatpak ps --columns=application', user: LIVE_USER
    ).stdout[/^#{app_id}$/]
  end
end

When /^I kill the (.*) Flatpak$/ do |app_id|
  $vm.execute_successfully("flatpak kill #{app_id}", user: LIVE_USER)
end

# This step is a workaround that will be dropped once we figure out
# how Tails will handle Flatpak/GNOME Software updates.
# https://gitlab.tails.boum.org/tails/tails/-/merge_requests/3009#note_283839
Given /^GNOME Software has an up-to-date Flathub AppStream$/ do
  $vm.execute_successfully('gnome-software --quit', user: LIVE_USER)
  Timeout.timeout(60) do
    $vm.execute_successfully('flatpak --user update', user: LIVE_USER)
  end
end
