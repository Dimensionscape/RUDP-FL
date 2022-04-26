package rudp.core;

/**
 * ...
 * @author Christopher Speciale
 */
enum abstract FrameType(Int) from Int to Int
{
	var CONNECT = 0;
	var HANDSHAKE = 1;
	var PACKET = 2;
	var ACK = 3;
	var FIN = 4;
}