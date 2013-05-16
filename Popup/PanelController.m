#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"




#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define SEARCH_INSET 17

#define POPUP_HEIGHT 210
#define PANEL_WIDTH 280
#define MENU_ANIMATION_DURATION .1

#pragma mark -

@implementation PanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize searchField = _searchField;
@synthesize textField = _textField;


#pragma mark -


- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
    }
    return self;
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.searchField];
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
    
    // Follow search string
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runSearch) name:NSControlTextDidChangeNotification object:self.searchField];
    
    //load old values
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    if([preferences stringForKey:@"usernameForVolsbbApp"]){
        [_username setStringValue:[preferences stringForKey:@"usernameForVolsbbApp"]] ;
        [_password setStringValue:[preferences stringForKey:@"passwordForVolsbbApp"]] ;
    }


    
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
    
    NSRect searchRect = [self.searchField frame];
    searchRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    searchRect.origin.x = SEARCH_INSET;
    searchRect.origin.y = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET - NSHeight(searchRect);
    
    if (NSIsEmptyRect(searchRect))
    {
        [self.searchField setHidden:YES];
    }
    else
    {
        [self.searchField setFrame:searchRect];
        [self.searchField setHidden:NO];
    }
    
    NSRect textRect = [self.textField frame];
    textRect.size.width = NSWidth([self.backgroundView bounds]) - SEARCH_INSET * 2;
    textRect.origin.x = SEARCH_INSET;
    textRect.size.height = NSHeight([self.backgroundView bounds]) - ARROW_HEIGHT - SEARCH_INSET * 3 - NSHeight(searchRect);
    textRect.origin.y = SEARCH_INSET;
    
    if (NSIsEmptyRect(textRect))
    {
        [self.textField setHidden:YES];
    }
    else
    {
        [self.textField setFrame:textRect];
        [self.textField setHidden:NO];
    }
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

- (void)runSearch
{
    NSString *searchFormat = @"";
    NSString *searchString = [self.searchField stringValue];
    if ([searchString length] > 0)
    {
        searchFormat = NSLocalizedString(@"Search for ‘%@’…", @"Format for search request");
    }
    NSString *searchRequest = [NSString stringWithFormat:searchFormat, searchString];
    [self.textField setStringValue:searchRequest];
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
            openDuration *= 10;
            
            if (shiftOptionPressed)
                NSLog(@"Icon is at %@\n\tMenu is on screen %@\n\tWill be animated to %@",
                      NSStringFromRect(statusRect), NSStringFromRect(screenRect), NSStringFromRect(panelRect));
        }
    }
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setFrame:panelRect display:YES];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
    
    
    
    
    [panel performSelector:@selector(makeFirstResponder:) withObject:self.searchField afterDelay:openDuration];
    
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        
        [self.window orderOut:nil];
    });
}

- (IBAction)wifiInfo:(NSButton *)sender {

    [_status setStringValue:@"Logging In..."];
    [_progressDot setAlphaValue:1];

    
    //add field validation here
    
    NSString *segment1 = @"userid=";
    segment1 = [segment1 stringByAppendingString: [_username stringValue]];
    segment1 = [segment1 stringByAppendingString:@"&password="];
    segment1 = [segment1 stringByAppendingString:[_password stringValue]];
    segment1 = [segment1 stringByAppendingString:@"&serviceName=ProntoAuthentication"]; 
    
    [_progressDot startAnimation:sender];
    
    NSData *postData = [segment1 dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://phc.prontonetworks.com/cgi-bin/authlogin"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

- (IBAction)logoutButton:(id)sender {
    //..logout code here
    
    [_status setStringValue:@"Logging Out..."];
    [_progressDot startAnimation:sender];
    [_progressDot setAlphaValue:1];
    
    NSString *post = @"nothing";
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://phc.prontonetworks.com/cgi-bin/authlogout"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
    
}

- (void)connection:(NSURLConnection*) connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Response recieved");
    NSString *fake = @"yup";
    [_progressDot stopAnimation:fake];
    [_progressDot setAlphaValue:0.1];
}

- (void)connection:(NSURLConnection*) connection didReceiveData:(NSData *)data
{
    NSLog(@"Data recieved");
    NSString* responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    //still needs "free access quota over"
    
    if ([responseString rangeOfString:@"Successful Pronto Authentication"].location != NSNotFound) {
        [_status setStringValue:@"Logged in"];
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences removeObjectForKey:@"usernameForVolsbbApp"];
        [preferences removeObjectForKey:@"passwordForVolsbbApp"];
        [preferences setObject:_username.stringValue forKey:@"usernameForVolsbbApp"];
        [preferences setObject:_password.stringValue forKey:@"passwordForVolsbbApp"];
    }
    else if ([responseString rangeOfString:@"You are already logged in"].location != NSNotFound){
        [_status setStringValue:@"Already Logged In"];
    }
    else if ([responseString rangeOfString:@"Logout successful"].location != NSNotFound){
        [_status setStringValue:@"Logged Out"];
    }
    else if ([responseString rangeOfString:@"Sorry, that account does not exist."].location != NSNotFound){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Sorry, that account does not exist."];
        [alert setInformativeText:@"Check your username and try again."];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [_status setStringValue:@"An Error Occurred"];
        [alert runModal];
    }
    else if ([responseString rangeOfString:@"Sorry, please check your username and password and try again."].location != NSNotFound){
        [_status setStringValue:@"Invalid Username/Password"];
    }
    else if ([responseString rangeOfString:@"Logout Failure"].location != NSNotFound){
            [_status setStringValue:@"Already Logged Out"];
    }
    
   
    
}


- (IBAction)aboutExpand:(id)sender {
    
    NSRect panelRect = [[self window] frame];
    
    switch([sender state]) {
        case NSOnState:
            panelRect.origin.y -= 120;
            panelRect.size.height = 330;
            [[self window] setFrame:panelRect display:YES animate:YES ];
            break;
        case NSOffState:
            panelRect.origin.y += 120;
            panelRect.size.height = 210;
            [[self window] setFrame:panelRect display:YES animate:YES];
            break;
        default:
            break;
    }
}




- (IBAction)QuitApp:(NSButton *)sender {
    
    switch ([sender state]) {
        case NSOnState:
            NSLog(@"its on");
            break;
        case NSOffState:
            NSLog(@"off now");
        default:
            break;
    }
    
}

// Check whether the user has internet
- (bool)hasInternet {
    NSURL *url = [[NSURL alloc] initWithString:@"http://www.google.com"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:2.5];
    BOOL connectedToInternet = NO;
    [_progressDot startAnimation:url];
    [_progressDot setAlphaValue:1];
    if ([NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil]) {
        connectedToInternet = YES;
    }
    return connectedToInternet;
    
    
    
}

- (IBAction)checkStatus:(id)sender {
    NSString *fake = @"yup";
    if([self hasInternet]){
        NSLog(@"Internet is connected!");
        [_status setStringValue:@"Internet Is Connected"];
        [_progressDot stopAnimation:fake];
        [_progressDot setAlphaValue:0.1];
    }
    else{
        [_status setStringValue:@"No Internet Access"];
        [_progressDot stopAnimation:fake];
        [_progressDot setAlphaValue:0.1];
    }
 
}

@end
