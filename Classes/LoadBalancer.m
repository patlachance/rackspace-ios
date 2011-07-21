//
//  LoadBalancer.m
//  OpenStack
//
//  Created by Michael Mayo on 2/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LoadBalancer.h"
#import "VirtualIP.h"
#import "LoadBalancerNode.h"
#import "NSObject+NSCoding.h"
#import "LoadBalancerProtocol.h"
#import "LoadBalancerConnectionThrottle.h"
#import "Server.h"
#import "NSString+Conveniences.h"


@implementation LoadBalancer

@synthesize protocol, algorithm, status, virtualIPs, created, updated, maxConcurrentConnections,
            connectionLoggingEnabled, nodes, connectionThrottle, clusterName, sessionPersistenceType, progress,
            cloudServerNodes, virtualIPType, region, usage;

#pragma mark - Constructors and Memory Management

- (id)init {
    self = [super init];
    if (self) {
        self.nodes = [[[NSMutableArray alloc] init] autorelease];
        self.cloudServerNodes = [[[NSMutableArray alloc] init] autorelease];
    }
    return self;
}

- (void)dealloc {
    [protocol release];
    [algorithm release];
    [status release];
    [virtualIPs release];
    [created release];
    [updated release];
    [nodes release];
    [sessionPersistenceType release];
    [clusterName release];
    [cloudServerNodes release];
    [virtualIPType release];
    [region release];
    [usage release];
    [connectionThrottle release];
    [super dealloc];
}

#pragma mark - Serialization

- (void)encodeWithCoder: (NSCoder *)coder {
    [self autoEncodeWithCoder:coder];    
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [self autoDecode:coder];
    }
    return self;
}

#pragma mark - JSON

+ (LoadBalancer *)fromJSON:(NSDictionary *)dict {
    
    LoadBalancer *loadBalancer = [[[LoadBalancer alloc] initWithJSONDict:dict] autorelease];

    LoadBalancerProtocol *p = [[[LoadBalancerProtocol alloc] init] autorelease];
    p.name = [dict objectForKey:@"protocol"];
    p.port = [[dict objectForKey:@"port"] intValue];
    loadBalancer.protocol = p;
    
    loadBalancer.algorithm = [dict objectForKey:@"algorithm"];
    loadBalancer.status = [dict objectForKey:@"status"];
    
    NSArray *virtualIpDicts = [dict objectForKey:@"virtualIps"];
    loadBalancer.virtualIPs = [[[NSMutableArray alloc] initWithCapacity:[virtualIpDicts count]] autorelease];
    for (NSDictionary *vipDict in virtualIpDicts) {
        VirtualIP *ip = [VirtualIP fromJSON:vipDict];
        [loadBalancer.virtualIPs addObject:ip];
        loadBalancer.virtualIPType = ip.type;
    }
    
    loadBalancer.created = [loadBalancer dateForKey:@"time" inDict:[dict objectForKey:@"created"]];
    loadBalancer.updated = [loadBalancer dateForKey:@"time" inDict:[dict objectForKey:@"updated"]];

    if ([dict objectForKey:@"connectionLogging"]) {
        loadBalancer.connectionLoggingEnabled = [[[dict objectForKey:@"connectionLogging"] objectForKey:@"enabled"] boolValue];
    }

    NSArray *nodeDicts = [dict objectForKey:@"nodes"];
    loadBalancer.nodes = [[[NSMutableArray alloc] initWithCapacity:[nodeDicts count]] autorelease];
    for (NSDictionary *nodeDict in nodeDicts) {
        LoadBalancerNode *node = [LoadBalancerNode fromJSON:nodeDict];
        [loadBalancer.nodes addObject:node];
    }

    if ([dict objectForKey:@"connectionThrottle"]) {
        loadBalancer.connectionThrottle = [LoadBalancerConnectionThrottle fromJSON:[dict objectForKey:@"connectionThrottle"]];
    }
    
    loadBalancer.sessionPersistenceType = [[dict objectForKey:@"sessionPersistence"] objectForKey:@"persistenceType"];
    loadBalancer.clusterName = [[dict objectForKey:@"cluster"] objectForKey:@"name"];
    return loadBalancer;
}

- (NSString *)toUpdateJSON {
    NSString *json
        = @"{ \"loadBalancer\": { "
           "        \"name\": \"<name>\","
           "        \"algorithm\": \"<algorithm>\","
           "        \"protocol\": \"<protocol>\","
           "        \"port\": \"<port>\""
           "  }}";
    ;
    json = [json replace:@"<name>" with:self.name];
    json = [json replace:@"<algorithm>" with:self.algorithm];
    json = [json replace:@"<protocol>" with:self.protocol.name];
    json = [json replace:@"<port>" withInt:self.protocol.port];
    return json;
}

- (NSString *)toJSON {
    
    NSString *json = @"{ \"loadBalancer\": { ";

    json = [json stringByAppendingString:[NSString stringWithFormat:@"\"name\": \"%@\", ", self.name]];
    json = [json stringByAppendingString:[NSString stringWithFormat:@"\"protocol\": \"%@\", ", self.protocol.name]];
    json = [json stringByAppendingString:[NSString stringWithFormat:@"\"port\": \"%i\", ", self.protocol.port]];
    json = [json stringByAppendingString:[NSString stringWithFormat:@"\"algorithm\": \"%@\", ", self.algorithm]];
    
    // virtualIPType
    if ([self.virtualIPType isEqualToString:@"Public"]) {
        json = [json stringByAppendingString:@"\"virtualIps\": [ { \"type\": \"PUBLIC\" } ], "];
    } else if ([self.virtualIPType isEqualToString:@"ServiceNet"]) {
        json = [json stringByAppendingString:@"\"virtualIps\": [ { \"type\": \"SERVICENET\" } ], "];
//    } else if ([self.virtualIPType isEqualToString:@"Shared Virtual IP"]) {
//        json = [json stringByAppendingString:@"\"virtualIps\": [ { \"type\": \"PUBLIC\" } ], "];
    }
    
    json = [json stringByAppendingString:@"\"nodes\": ["];
    for (int i = 0; i < [self.nodes count]; i++) {
        LoadBalancerNode *node = [self.nodes objectAtIndex:i];
        json = [json stringByAppendingString:@"{"];
        json = [json stringByAppendingString:[NSString stringWithFormat:@"\"address\": \"%@\",", node.address]];
        json = [json stringByAppendingString:[NSString stringWithFormat:@"\"port\": \"%@\",", node.port]];
        json = [json stringByAppendingString:[NSString stringWithFormat:@"\"condition\": \"%@\"", node.condition]];
        
        if (i == [self.nodes count] - 1) {
            if ([self.cloudServerNodes count] > 0) {
                json = [json stringByAppendingString:@"}, "];
            } else {
                json = [json stringByAppendingString:@"}"];
            }
        } else {
            json = [json stringByAppendingString:@"}, "];
        }
    }
    for (int i = 0; i < [self.cloudServerNodes count]; i++) {
        Server *server = [self.cloudServerNodes objectAtIndex:i];
        json = [json stringByAppendingString:@"{"];        
        json = [json stringByAppendingString:[NSString stringWithFormat:@"\"address\": \"%@\",", [[server.addresses objectForKey:@"public"] objectAtIndex:0]]];
        json = [json stringByAppendingString:[NSString stringWithFormat:@"\"port\": \"%i\",", self.protocol.port]];
        json = [json stringByAppendingString:@"\"condition\": \"ENABLED\""];
        json = [json stringByAppendingString:i == [self.cloudServerNodes count] - 1 ? @"}" : @"}, "];
    }
    json = [json stringByAppendingString:@"]"];
    
    json = [json stringByAppendingString:@"}}"];
    return json;
}

- (BOOL)shouldBePolled {
    return ![self.status isEqualToString:@"ACTIVE"];
}

@end
