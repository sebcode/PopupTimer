#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"
#import "ApplicationDelegate.h"
#import <DDLog.h>

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 122
#define PANEL_WIDTH 280
#define MENU_ANIMATION_DURATION .1

#pragma mark -

@implementation PanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;

static const int ddLogLevel = LOG_LEVEL_INFO;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
        
        [self restoreTime];
    }
    return self;
}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    // Resize panel
    NSRect panelRect = [[self window] frame];
    panelRect.size.height = POPUP_HEIGHT;
    [[self window] setFrame:panelRect display:NO];
    
    [self updateLabel];
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    
    self.backgroundView.arrowX = panelX;    
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    
    NSTimeInterval openDuration = OPEN_DURATION;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type] == NSLeftMouseDown)
    {
        NSUInteger clearFlags = ([currentEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        BOOL shiftPressed = (clearFlags == NSShiftKeyMask);
        BOOL shiftOptionPressed = (clearFlags == (NSShiftKeyMask | NSAlternateKeyMask));
        if (shiftPressed || shiftOptionPressed)
        {
            openDuration *= 100;
            
            if (shiftOptionPressed)
                NSLog(@"Icon is at %@\n\tMenu is on screen %@\n\tWill be animated to %@",
                      NSStringFromRect(statusRect), NSStringFromRect(screenRect), NSStringFromRect(panelRect));
        }
    }
    
    [panel setFrame:panelRect display:YES];
    [panel setAlphaValue:1];
}

- (void)closePanel
{
    [self.window orderOut:nil];
}

- (IBAction)pressReset:(id)sender
{
    if (timerStarted) {
        [self pressStart:nil];
    }
    
    DDLogInfo(@"Timer reset");
    seconds = 0;
    [self saveTime:YES];
    [self updateLabel];
}

- (IBAction)pressQuit:(id)sender
{
    [self saveTime:YES];
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)pressStart:(id)sender
{
    ApplicationDelegate *appDelegate = (ApplicationDelegate *)[[NSApplication sharedApplication] delegate];
    
    timerStarted = ! timerStarted;
    
    NSString *imgName = [NSString stringWithFormat:@"Status%@", timerStarted ? @"2" : @""];
    [appDelegate.menubarController.statusItemView setImage:[NSImage imageNamed:imgName]];
    
    [startButton setTitle:timerStarted ? @"Stop" : @"Start"];
    
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval: 1
                                                 target: self
                                               selector:@selector(tick)
                                               userInfo: nil
                                                repeats: YES];
    }
    
    if (timerStarted) {
        DDLogInfo(@"Timer start at %@", [self formatTime]);
    } else {
        DDLogInfo(@"Timer stop at %@", [self formatTime]);
    }
}

- (NSString *)formatTime
{
    long h = seconds / 3600;
    long m = (seconds / 60) % 60;
    long s = seconds % 60;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", (int)h, (int)m, (int)s];
}

- (void)updateLabel
{
    timerLabel.stringValue = [self formatTime];
}

- (void)restoreTime
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    seconds = [ud integerForKey:@"timer"];
    [self updateLabel];
}

- (void)saveTime:(BOOL)aDoSync
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:seconds forKey:@"timer"];
    if (seconds % 60 == 0) {
        [ud synchronize];
    }
}

- (void)tick
{
    if (!timerStarted) {
        return;
    }
    
    seconds++;
    [self updateLabel];
    [self saveTime:seconds % 60 == 0];
}

@end
