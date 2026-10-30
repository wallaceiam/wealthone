# Builds an isolated runtime regression probe from production Watch sources.
# Run with the repo's xcodeproj GEM_HOME, then build/run the generated project
# on a disposable Watch simulator. No production test routes or data are added.
require 'xcodeproj'
require 'fileutils'
root = File.expand_path('..', __dir__)
output = ARGV[0] || '/tmp/wealthone-watch-navigation-probe'
FileUtils.mkdir_p(output)
['Watch/WatchModel.swift', 'Shared/WatchPayload.swift', 'Shared/SnapshotFreshness.swift'].each do |path|
  FileUtils.cp(File.join(root, path), output)
end
view = File.read(File.join(root, 'Watch/WatchViews.swift'))
link = "NavigationLink {\n            QuickEntryView()"
raise 'Quick entry navigation changed; update the probe route' unless view.include?(link)
view = view.sub('@State private var discarding = false', "@State private var discarding = false\n  @State private var probeOpenEntry = false")
view = view.sub(link, "NavigationLink(isActive: $probeOpenEntry) {\n            QuickEntryView()")
view = view.sub('}.navigationTitle("WealthOne")', '}.navigationTitle("WealthOne").onAppear { probeOpenEntry = true }')
File.write(File.join(output, 'WatchViews.swift'), view)
# Keep the production navigation/environment ownership exactly as it is. Only
# replace model initialization with an isolated synthetic fixture.
app = File.read(File.join(root, 'Watch/WealthOneWatchApp.swift'))
app = app.sub('private var model = WatchModel()', 'private var model = navigationProbeModel()')
app += <<~SWIFT

  @MainActor
  private func navigationProbeModel() -> WatchModel {
    let model = WatchModel()
    model.snapshot = WatchSnapshot(total: 300, change: 10,
      history: [.init(date: "2026-10-30", total: 300)],
      accounts: [.init(id: "probe-gbp", name: "Review GBP", currency: "GBP"),
        .init(id: "probe-cad", name: "Review CAD", currency: "CAD")], updatedAt: Date())
    return model
  }
SWIFT
File.write(File.join(output, 'WealthOneWatchApp.swift'), app)
project = Xcodeproj::Project.new(File.join(output, 'WatchNavigationProbe.xcodeproj'))
target = project.new_target(:application, 'WatchNavigationProbe', :watchos, '26.0')
Dir.glob(File.join(output, '*.swift')).each do |path|
  target.source_build_phase.add_file_reference(project.main_group.new_file(File.basename(path)))
end
target.build_configurations.each do |config|
  config.build_settings.merge!({ 'SWIFT_VERSION' => '6.0', 'GENERATE_INFOPLIST_FILE' => 'YES',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'ca.mymojo.wealthone.quickentrynavigationprobe',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'Watch Navigation Probe',
    'INFOPLIST_KEY_WKApplication' => 'YES', 'INFOPLIST_KEY_WKWatchOnly' => 'YES',
    'TARGETED_DEVICE_FAMILY' => '4' })
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(project.path, 'WatchNavigationProbe', true)
puts project.path
