//
//  ExampleWKWebViewController.m
//  ExampleApp-iOS
//
//  Created by Marcus Westin on 1/13/14.
//  Copyright (c) 2014 Marcus Westin. All rights reserved.
//

#import "ExampleWKWebViewController.h"
#import "WKWebViewJavascriptBridge.h"

@interface ExampleWKWebViewController ()<UIAlertViewDelegate>

@property WKWebViewJavascriptBridge* bridge;

@end

@implementation ExampleWKWebViewController

- (void)viewWillAppear:(BOOL)animated {
    if (_bridge) { return; }
    
    WKWebView* webView = [[NSClassFromString(@"WKWebView") alloc] initWithFrame:self.view.bounds];
    webView.navigationDelegate = self;
    webView.UIDelegate = self;
    [self.view addSubview:webView];
    [WKWebViewJavascriptBridge enableLogging];
    _bridge = [WKWebViewJavascriptBridge bridgeForWebView:webView];
    [_bridge setWebViewDelegate:self];
    
    [_bridge registerHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        responseCallback(@"Response from testObjcCallback");
    }];
    
    [_bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before ready" }];
    
    [self renderButtons:webView];
    [self loadExamplePage:webView];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidStartLoad");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidFinishLoad");
}

- (void)renderButtons:(WKWebView*)webView {
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    
    UIButton *callbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callbackButton setTitle:@"Call handler" forState:UIControlStateNormal];
    [callbackButton addTarget:self action:@selector(callHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:callbackButton aboveSubview:webView];
    callbackButton.frame = CGRectMake(10, 400, 100, 35);
    callbackButton.titleLabel.font = font;
    
    UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setTitle:@"Reload webview" forState:UIControlStateNormal];
    [reloadButton addTarget:webView action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:reloadButton aboveSubview:webView];
    reloadButton.frame = CGRectMake(110, 400, 100, 35);
    reloadButton.titleLabel.font = font;
}

- (void)callHandler:(id)sender {
//    id data = @{ @"greetingFromObjC": @"Hi there, JS!" };
//    [_bridge callHandler:@"testJavascriptHandler" data:data responseCallback:^(id response) {
//        NSLog(@"testJavascriptHandler responded: %@", response);
//    }];
    [_bridge callHandler:@"showAlert" data:@"Native call showAlert" responseCallback:^(id responseData) {
        NSLog(@"%@",responseData);
    }];
}

- (void)loadExamplePage:(WKWebView*)webView {
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"ExampleApp" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [webView loadHTMLString:appHtml baseURL:baseURL];
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(void))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else {
        UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
        popPresenter.sourceView = self.view;
        popPresenter.sourceRect = self.view.bounds;
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:webView.title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else {
        UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
        popPresenter.sourceView = self.view;
        popPresenter.sourceRect = self.view.bounds;
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    NSString *hostString = webView.URL.host;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:hostString preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = defaultText;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *input = ((UITextField *)alertController.textFields.firstObject).text;
        completionHandler(input);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(nil);
    }]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else {
        UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
        popPresenter.sourceView = self.view;
        popPresenter.sourceRect = self.view.bounds;
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

@end
