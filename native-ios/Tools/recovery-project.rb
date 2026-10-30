# Shared by the full generator and incremental project updates.
def wealthone_source_reference(project, folder, path)
  group = project.main_group.groups.find { |g| g.path == folder } || project.main_group.new_group(folder, folder)
  group.files.find { |f| f.path == path } || group.new_file(path)
end

def wealthone_add_source(target, ref)
  target.source_build_phase.add_file_reference(ref) unless target.source_build_phase.files_references.include?(ref)
end

def configure_recovery_target(project, root)
  target = project.targets.find { |t| t.name == 'WealthOneRecovery' } || project.new_target(:application, 'WealthOneRecovery', :ios, '26.0')
  [['RecoveryApp', 'WealthOneRecoveryApp.swift'], ['App', 'LegacyMigration.swift'], ['App', 'Views/LegacyRecoveryBrowser.swift']].each do |folder, path|
    wealthone_add_source(target, wealthone_source_reference(project, folder, path))
  end
  if target.package_product_dependencies.empty?
    dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dependency.package = project.root_object.package_references.first
    dependency.product_name = 'WealthOneCore'
    target.package_product_dependencies << dependency
    build = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build.product_ref = dependency
    target.frameworks_build_phase.files << build
  end
  assets = wealthone_source_reference(project, 'App', 'Assets.xcassets')
  target.resources_build_phase.add_file_reference(assets) unless target.resources_build_phase.files_references.include?(assets)
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'SWIFT_VERSION' => '6.0', 'CODE_SIGN_STYLE' => 'Automatic', 'DEVELOPMENT_TEAM' => '2LG9PUJ57N',
      'PRODUCT_BUNDLE_IDENTIFIER' => 'ca.mymojo.wealthone', 'IPHONEOS_DEPLOYMENT_TARGET' => '26.0',
      'GENERATE_INFOPLIST_FILE' => 'NO', 'INFOPLIST_FILE' => 'RecoveryApp/Info.plist',
      'CODE_SIGN_ENTITLEMENTS' => 'RecoveryApp/Recovery.entitlements', 'TARGETED_DEVICE_FAMILY' => '1,2',
      'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon', 'MARKETING_VERSION' => '1.0',
      'CURRENT_PROJECT_VERSION' => '1', 'ENABLE_USER_SCRIPT_SANDBOXING' => 'YES'
    })
  end
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(target)
  scheme.set_launch_target(target)
  scheme.save_as(project.path, target.name, true)
  target
end
