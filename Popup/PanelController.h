#import "BackgroundView.h"
#import "StatusItemView.h"

@class PanelController;
@class ApplicationDelegate;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate, NSMenuDelegate>
{
    BOOL timerStarted;
    long seconds;
    NSTimer *timer;
    
    IBOutlet NSButton *startButton;
    IBOutlet NSTextField *timerLabel;
    IBOutlet NSPopUpButton *popupButton;

    BOOL _hasActivePanel;
    __unsafe_unretained BackgroundView *_backgroundView;
    __unsafe_unretained id<PanelControllerDelegate> _delegate;
    __unsafe_unretained NSSearchField *_searchField;
    __unsafe_unretained NSTextField *_textField;
    
    ApplicationDelegate *appDelegate;
    NSUserDefaults *userDefaults;
    
    NSString *currentProject;
}

@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;
- (void)onAppQuit;

- (IBAction)pressQuit:(id)sender;
- (IBAction)pressReset:(id)sender;
- (IBAction)pressStart:(id)sender;

@end
