# Run from repo root: GEM_HOME="$PWD/vendor/bundle/ruby/2.6.0" ruby native-ios/Tools/generate-project.rb
require 'xcodeproj'
require 'fileutils'
root = File.expand_path('..', __dir__)
project = Xcodeproj::Project.new(File.join(root, 'WealthOne.xcodeproj'))
project.root_object.attributes['LastUpgradeCheck'] = '2700'
app = project.new_target(:application, 'WealthOne', :ios, '26.0')
watch = project.new_target(:application, 'WealthOneWatch', :watchos, '26.0')
widget = project.new_target(:app_extension, 'WealthOneComplication', :watchos, '26.0')
package = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package.relative_path = '.'
project.root_object.package_references << package
product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product.package = package
product.product_name = 'WealthOneCore'
app.package_product_dependencies << product
build = project.new(Xcodeproj::Project::Object::PBXBuildFile)
app.frameworks_build_phase.files << build
# Swift package products use productRef rather than fileRef.
build.file_ref = nil
build.product_ref = product
[[app, 'App'], [watch, 'Watch'], [widget, 'Complication']].each do |target, folder|
  group = project.main_group.new_group(folder, folder)
  Dir.glob(File.join(root, folder, '**', '*.swift')).sort.each do |path|
    ref = group.new_file(path.delete_prefix(File.join(root, folder) + '/'))
    target.source_build_phase.add_file_reference(ref)
  end
  target.build_configurations.each do |config|
    s = config.build_settings
    s['SWIFT_VERSION'] = '6.0'
    s['CODE_SIGN_STYLE'] = 'Automatic'
    s['DEVELOPMENT_TEAM'] = '2LG9PUJ57N'
    s['MARKETING_VERSION'] = '2.0'
    s['CURRENT_PROJECT_VERSION'] = '3'
    s['GENERATE_INFOPLIST_FILE'] = 'NO'
    s['INFOPLIST_FILE'] = "#{folder}/Info.plist"
    s['PRODUCT_BUNDLE_IDENTIFIER'] = {'App'=>'ca.mymojo.wealthone.native', 'Watch'=>'ca.mymojo.wealthone.native.watchkitapp', 'Complication'=>'ca.mymojo.wealthone.native.watchkitapp.networthwidget'}[folder]
    s['TARGETED_DEVICE_FAMILY'] = folder == 'App' ? '1,2' : '4'
    s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
    s['ENABLE_USER_SCRIPT_SANDBOXING'] = 'YES'
    s['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon' if ['App', 'Watch'].include?(folder)
    s['CODE_SIGN_ENTITLEMENTS'] = folder == 'App' ? 'App/WealthOne.entitlements' : "#{folder}/Shared.entitlements"
    s['SKIP_INSTALL'] = 'YES' unless folder == 'App'
  end
end
shared = project.main_group.new_group('Shared', 'Shared')
Dir.glob(File.join(root, 'Shared', '*.swift')).each do |path|
 ref = shared.new_file(File.basename(path))
 [app, watch, widget].each { |target| target.source_build_phase.add_file_reference(ref) }
end
[[app, 'App'], [watch, 'Watch']].each do |target, folder|
  assets = File.join(root, folder, 'Assets.xcassets')
  if File.directory?(assets)
    ref = project.main_group.find_subpath(folder).new_file('Assets.xcassets')
    target.resources_build_phase.add_file_reference(ref)
  end
end
app.add_dependency(watch)
phase = app.new_copy_files_build_phase('Embed Watch Content')
phase.dst_subfolder_spec = '16'
phase.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'
phase.add_file_reference(watch.product_reference)
watch.add_dependency(widget)
phase = watch.new_copy_files_build_phase('Embed App Extensions')
phase.dst_subfolder_spec = '13'
phase.add_file_reference(widget.product_reference)
ui_tests = project.new_target(:ui_test_bundle, 'WealthOneUITests', :ios, '26.0')
ui_tests.add_dependency(app)
group = project.main_group.new_group('UITests', 'UITests')
Dir.glob(File.join(root, 'UITests', '*.swift')).each do |path|
  ui_tests.source_build_phase.add_file_reference(group.new_file(File.basename(path)))
end
ui_tests.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '6.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'ca.mymojo.wealthone.native.uitests'
  config.build_settings['TEST_TARGET_NAME'] = 'WealthOne'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
end
require_relative 'recovery-project'
configure_recovery_target(project, root)
project.save
[app, watch].each do |target|
 scheme = Xcodeproj::XCScheme.new
 scheme.add_build_target(target)
 scheme.set_launch_target(target)
 scheme.add_test_target(ui_tests) if target == app
 scheme.save_as(project.path, target.name, true)
end
puts project.path
