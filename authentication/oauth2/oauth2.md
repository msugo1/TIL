### traditional way of authentication between server and third-parties
- the resource owner shares its credentials with third-parties to provide them with application access

**problems & limitations**
1. third-parties are required to store the resource owner's credentials for future use
(ex. password)
2. third-parties gain overly broad access to the resource owner's protected resources
- the owners have no way to restrict duration or access to a limited subset of resource
3. resource owners have to revoke access to all third parties to revoke access to an individual third party
4. Compromise of any third-party application results in that of the end-user's password and all of the data protected by that password.

## OAuth
- introduce an authorization layer and separate the role of the client from that of the resource owner.
- `a diffent set of credentials` than those of the resource owner is issued
    = access token
- because the resource owner only authenticates with the authorization server, the resource owner's credentials are never shared with the client.


### Flow
     +--------+                               +---------------+
     |        |--(A)- Authorization Request ->|   Resource    |
     |        |                               |     Owner     |
     |        |<-(B)-- Authorization Grant ---|               |
     |        |                               +---------------+
     |        |
     |        |                               +---------------+
     |        |--(C)-- Authorization Grant -->| Authorization |
     | Client |                               |     Server    |
     |        |<-(D)----- Access Token -------|               |
     |        |                               +---------------+
     |        |
     |        |                               +---------------+
     |        |--(E)----- Access Token ------>|    Resource   |
     |        |                               |     Server    |
     |        |<-(F)--- Protected Resource ---|               |
     +--------+                               +---------------+


