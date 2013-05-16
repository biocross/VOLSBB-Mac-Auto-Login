#import "BackgroundView.h"
#import "StatusItemView.h"

@class PanelController;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate>
{
    BOOL _hasActivePanel;
    __unsafe_unretained BackgroundView *_backgroundView;
    __unsafe_unretained id<PanelControllerDelegate> _delegate;
    __unsafe_unretained NSSearchField *_searchField;
    __unsafe_unretained NSTextField *_textField;
}

@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;
@property (nonatomic, unsafe_unretained) IBOutlet NSSearchField *searchField;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *textField;

@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;
-(IBAction)wifiInfo:(id)sender;
- (IBAction)logoutButton:(id)sender;

@property (nonatomic) IBOutlet NSTextField *username;
@property (nonatomic) IBOutlet NSTextField *password;
- (IBAction)aboutExpand:(id)sender;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *progressDot;
@property (unsafe_unretained) IBOutlet NSTextField *status;
@property (unsafe_unretained) IBOutlet NSTextField *moreAboutText;
- (IBAction)QuitApp:(NSButton *)sender;
- (bool)hasInternet;
- (IBAction)checkStatus:(id)sender;
@end
