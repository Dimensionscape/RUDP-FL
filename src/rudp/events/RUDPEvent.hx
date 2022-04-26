package rudp.events;

import openfl.events.Event;
import rudp.core.Connection;

/**
 * ...
 * @author Christopher Speciale
 */
class RUDPEvent extends Event 
{
	public static inline var CONNECT:String = "connect";
	public static inline var CLOSE:String = "close";
	
	public var connection(default, null):Connection;
	public function new(type:String, bubbles:Bool=false, cancelable:Bool=false, connection:Connection) 
	{
		super(type, bubbles, cancelable);
		this.connection = connection;
		
	}
	override public function clone():RUDPEvent 
	{
		return new RUDPEvent(type, bubbles, cancelable, connection);
	}
	
}