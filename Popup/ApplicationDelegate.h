#import "MenubarController.h"
#import "PanelController.h"

@class DDFileLogger;

@interface ApplicationDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate>
{
    DDFileLogger *fileLogger;
}

@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong, readonly) PanelController *panelController;

- (IBAction)togglePanel:(id)sender;

@end
