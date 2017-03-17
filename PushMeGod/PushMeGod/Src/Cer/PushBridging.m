//
//  PushBridging.m
//  PushMeGod
//
//  Created by ding_qili on 17/1/7.
//  Copyright © 2017年 ding_qili. All rights reserved.
//

#import "PushBridging.h"
#import "ioSock.h"

@implementation PushBridging {
    otSocket socket;
    SSLContextRef context;
    SecKeychainRef keychain;
    SecCertificateRef certificate;
    SecIdentityRef identity;
}


- (BOOL)connect:(BOOL)debug{
    
    if(self.certificate == nil) {
        return NO;
    }
    
    // Define result variable.
    OSStatus result;
    
    // Establish connection to server.
    PeerSpec peer;
//    result = MakeServerConnection("gateway.push.apple.com", 2195, &socket, &peer);//
    if (debug) {
        result = MakeServerConnection("gateway.sandbox.push.apple.com", 2195, &socket, &peer);//
    }else{
        result = MakeServerConnection("gateway.push.apple.com", 2195, &socket, &peer);//
    }
    

    NSLog(@"MakeServerConnection(): %d", result);
    
    // Create new SSL context.
    result = SSLNewContext(false, &context);//
    NSLog(@"SSLNewContext(): %d", result);
    
    // Set callback functions for SSL context.
    result = SSLSetIOFuncs(context, SocketRead, SocketWrite);//
    NSLog(@"SSLSetIOFuncs(): %d", result);
    
    // Set SSL context connection.
    result = SSLSetConnection(context, socket);//
    NSLog(@"SSLSetConnection(): %d", result);
    
    // Set server domain name.
//    result = SSLSetPeerDomainName(context, "gateway.push.apple.com", 22);//
    if (debug) {
        result = SSLSetPeerDomainName(context, "gateway.sandbox.push.apple.com", 30);//
    }else{
        result = SSLSetPeerDomainName(context, "gateway.push.apple.com", 22);//
    }
    

    NSLog(@"SSLSetPeerDomainName(): %d", result);
    
    // Open keychain.
    result = SecKeychainCopyDefault(&keychain);//
    NSLog(@"SecKeychainOpen(): %d", result);
    
    // Create certificate.
    NSData *certificateData = [NSData dataWithContentsOfFile:self.certificate];
    
    certificate = SecCertificateCreateWithData(kCFAllocatorDefault, (CFDataRef)certificateData);
    if (certificate == NULL)
        NSLog (@"SecCertificateCreateWithData failled");
    
    // Create identity.
    result = SecIdentityCreateWithCertificate(keychain, certificate, &identity);//
    NSLog(@"SecIdentityCreateWithCertificate(): %d", result);
    
    // Set client certificate.
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)&identity, 1, NULL);
    result = SSLSetCertificate(context, certificates);//
    NSLog(@"SSLSetCertificate(): %d", result);
    CFRelease(certificates);
    
    // Perform SSL handshake.
    do {
        result = SSLHandshake(context);//
        NSLog(@"SSLHandshake(): %d", result);
    } while(result == errSSLWouldBlock);
    
    return result == 0;
    
}

- (void)disconnect {
    
    if(self.certificate == nil) {
        return;
    }
    
    // Define result variable.
    OSStatus result;
    
    // Close SSL session.
    result = SSLClose(context);//
    NSLog(@"SSLClose(): %d", result);
    
    // Release identity.
    if (identity != NULL)
        CFRelease(identity);
    
    // Release certificate.
    if (certificate != NULL)
        CFRelease(certificate);
    
    // Release keychain.
    if (keychain != NULL)
        CFRelease(keychain);
    
    // Close connection to server.
    close((int)socket);
    
    // Delete SSL context.
    result = SSLDisposeContext(context);//
    NSLog(@"SSLDisposeContext(): %d", result);
    
}


-(BOOL)push:(NSString *)token payload:(NSString *)payload{
    
    
    // Convert string into device token data.
    NSMutableData *deviceToken = [NSMutableData data];
    unsigned value;
    NSScanner *scanner = [NSScanner scannerWithString:token];
    while(![scanner isAtEnd]) {
        [scanner scanHexInt:&value];
        value = htonl(value);
        [deviceToken appendBytes:&value length:sizeof(value)];
    }
    
    // Create C input variables.
    char *deviceTokenBinary = (char *)[deviceToken bytes];
    char *payloadBinary = (char *)[payload UTF8String];
    size_t payloadLength = strlen(payloadBinary);
    
    // Define some variables.
    uint8_t command = 0;
    char message[293];
    char *pointer = message;
    uint16_t networkTokenLength = htons(32);
    uint16_t networkPayloadLength = htons(payloadLength);
    
    // Compose message.
    memcpy(pointer, &command, sizeof(uint8_t));
    pointer += sizeof(uint8_t);
    memcpy(pointer, &networkTokenLength, sizeof(uint16_t));
    pointer += sizeof(uint16_t);
    memcpy(pointer, deviceTokenBinary, 32);
    pointer += 32;
    memcpy(pointer, &networkPayloadLength, sizeof(uint16_t));
    pointer += sizeof(uint16_t);
    memcpy(pointer, payloadBinary, payloadLength);
    pointer += payloadLength;
    
    // Send message over SSL.
    size_t processed = 0;
    OSStatus result = SSLWrite(context, &message, (pointer - message), &processed);
    //    if (result != noErr)
    NSLog(@"SSLWrite(): %d %zd", result, processed);
    
    return result == 0;
}

@end
