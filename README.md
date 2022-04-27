# RUDP-FL
 RUDP-FL is a custom reliable UDP implementation for Haxe and OpenFL.

----------------------

Reliable UDP is a custom protocol on top of DatagramSocket(UDP) that provides some of the features of TCP, like reliable packet delivery and persistant connections, but on the software layer. This provides many of the benefits of both UDP and TCP such as:

### UDP 
- Fast packet transmission.
- NAT Hole punching(https://en.wikipedia.org/wiki/UDP_hole_punching)
- Low latency

### TCP
- Reliable packet delivery
- Persistant connections

----------------------

RUDP is perfect for developing reliable and scalable P2P applications with OpenFL, allowing you to guarantee data transmission with low latency.

---------------------

## Requirements
- Haxe 4+
- OpenFL 9.1+
- Lime 7.9+

## TODO
- Reduce header size to 72 bits
- Documentation
- Examples
