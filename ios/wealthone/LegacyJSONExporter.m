#import <React/RCTBridgeModule.h>
#import <UIKit/UIKit.h>

@interface LegacyJSONExporter : NSObject <RCTBridgeModule>
@end

@implementation LegacyJSONExporter
RCT_EXPORT_MODULE();
+ (BOOL)requiresMainQueueSetup { return YES; }

RCT_REMAP_METHOD(share,
                 shareJSON:(NSString *)json
                 filename:(NSString *)filename
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *error = nil;
    NSURL *directory = [NSURL fileURLWithPath:[NSTemporaryDirectory()
      stringByAppendingPathComponent:NSUUID.UUID.UUIDString] isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:directory
      withIntermediateDirectories:YES attributes:nil error:&error];
    NSURL *url = [directory URLByAppendingPathComponent:filename.lastPathComponent];
    if (error || ![json writeToURL:url atomically:YES
      encoding:NSUTF8StringEncoding error:&error]) {
      reject(@"export_write", @"The backup file could not be created.", error);
      return;
    }
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if (scene.activationState == UISceneActivationStateForegroundActive &&
          [scene isKindOfClass:UIWindowScene.class]) {
        for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
          if (candidate.isKeyWindow) { window = candidate; break; }
        }
      }
    }
    }
    if (!window) {
      id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
      if ([delegate respondsToSelector:@selector(window)]) { window = delegate.window; }
    }
    if (!window) {
      for (UIWindow *candidate in UIApplication.sharedApplication.windows) {
        if (candidate.isKeyWindow) { window = candidate; break; }
      }
    }
    UIViewController *presenter = window.rootViewController;
    while (presenter.presentedViewController) { presenter = presenter.presentedViewController; }
    if (!presenter) {
      reject(@"export_present", @"The share sheet could not be opened.", nil);
      return;
    }
    UIActivityViewController *sheet = [[UIActivityViewController alloc]
      initWithActivityItems:@[url] applicationActivities:nil];
    sheet.popoverPresentationController.sourceView = presenter.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(
      CGRectGetMidX(presenter.view.bounds), CGRectGetMidY(presenter.view.bounds), 1, 1);
    sheet.popoverPresentationController.permittedArrowDirections = 0;
    sheet.completionWithItemsHandler = ^(UIActivityType activity, BOOL completed,
      NSArray *items, NSError *activityError) {
      [[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
      if (activityError) { reject(@"export_share", @"Sharing the backup failed.", activityError); }
      else { resolve(nil); }
    };
    [presenter presentViewController:sheet animated:YES completion:nil];
  });
}
@end
