//
//  AccountManager.h
//  OpenStack
//
//  Created by Mike Mayo on 10/21/10.
//  The OpenStack project is provided under the Apache 2.0 license.
//

#import <Foundation/Foundation.h>
#import "APICallback.h"

@class OpenStackAccount, Server, Flavor, Image, Container, StorageObject, OpenStackRequest, ASINetworkQueue, LoadBalancer, LoadBalancerNode, OSComputeEndpoint;

@interface AccountManager : NSObject {
    OpenStackAccount *account;
    ASINetworkQueue *queue;
}

@property (nonatomic, retain) ASINetworkQueue *queue;
@property (nonatomic, assign) OpenStackAccount *account;

#pragma mark - Authentication

- (APICallback *)authenticate;

#pragma mark - Compute

- (APICallback *)getLimits;
- (APICallback *)softRebootServer:(Server *)server;
- (APICallback *)hardRebootServer:(Server *)server;
- (APICallback *)changeAdminPassword:(Server *)server password:(NSString *)password;
- (APICallback *)renameServer:(Server *)server name:(NSString *)name;
- (APICallback *)deleteServer:(Server *)server;
- (APICallback *)createServer:(Server *)server;
- (APICallback *)resizeServer:(Server *)server flavor:(Flavor *)flavor;
- (APICallback *)confirmResizeServer:(Server *)server;
- (APICallback *)revertResizeServer:(Server *)server;
- (APICallback *)rebuildServer:(Server *)server image:(Image *)image;
- (APICallback *)getBackupSchedule:(Server *)server;
- (APICallback *)updateBackupSchedule:(Server *)server;

- (APICallback *)getServers;
- (APICallback *)getServersAtEndpoint:(OSComputeEndpoint *)endpoint;
- (APICallback *)getImages;
- (APICallback *)getImagesAtEndpoint:(OSComputeEndpoint *)endpoint;
- (APICallback *)getFlavors;
- (APICallback *)getFlavorsAtEndpoint:(OSComputeEndpoint *)endpoint;
- (APICallback *)getImage:(Server *)server endpoint:(OSComputeEndpoint *)endpoint;

#pragma mark - Object Storage

- (APICallback *)getContainers;
- (APICallback *)createServer:(Server *)server endpoint:(OSComputeEndpoint *)endpoint;
- (APICallback *)deleteContainer:(Container *)container;

- (APICallback *)getObjects:(Container *)container;
- (APICallback *)getObject:(Container *)container object:(StorageObject *)object downloadProgressDelegate:(id)downloadProgressDelegate;
- (APICallback *)writeObject:(Container *)container object:(StorageObject *)object downloadProgressDelegate:(id)downloadProgressDelegate;
- (APICallback *)deleteObject:(Container *)container object:(StorageObject *)object;
  
- (APICallback *)updateCDNContainer:(Container *)container;

#pragma mark - Load Balancers

- (APICallback *)getLoadBalancers:(NSString *)endpoint;
- (APICallback *)getLoadBalancerDetails:(LoadBalancer *)loadBalancer endpoint:(NSString *)endpoint;
- (APICallback *)getLoadBalancerProtocols:(NSString *)endpoint;
- (APICallback *)createLoadBalancer:(LoadBalancer *)loadBalancer;
- (APICallback *)updateLoadBalancer:(LoadBalancer *)loadBalancer;
- (APICallback *)deleteLoadBalancer:(LoadBalancer *)loadBalancer;
- (APICallback *)updateLoadBalancerConnectionLogging:(LoadBalancer *)loadBalancer;

- (APICallback *)getLoadBalancerConnectionThrottling:(LoadBalancer *)loadBalancer;
- (APICallback *)updateLoadBalancerConnectionThrottling:(LoadBalancer *)loadBalancer;
- (APICallback *)deleteLoadBalancerConnectionThrottling:(LoadBalancer *)loadBalancer;

- (APICallback *)getLoadBalancerUsage:(LoadBalancer *)loadBalancer endpoint:(NSString *)endpoint;
- (APICallback *)addLBNodes:(NSArray *)nodes loadBalancer:(LoadBalancer *)loadBalancer endpoint:(NSString *)endpoint;
- (APICallback *)updateLBNode:(LoadBalancerNode *)node loadBalancer:(LoadBalancer *)loadBalancer endpoint:(NSString *)endpoint;
- (APICallback *)deleteLBNode:(LoadBalancerNode *)node loadBalancer:(LoadBalancer *)loadBalancer endpoint:(NSString *)endpoint;

@end
